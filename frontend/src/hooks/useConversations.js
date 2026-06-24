import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import toast from 'react-hot-toast';
import api from '../lib/api';

export function useConversations(params = {}) {
  return useQuery({
    queryKey: ['conversations', params],
    queryFn: async () => {
      const { data } = await api.get('/conversations', { params });
      return data;
    },
    placeholderData: keepPreviousData,
  });
}

export function useConversation(id, { refetchInterval } = {}) {
  return useQuery({
    queryKey: ['conversations', String(id)],
    queryFn: async () => {
      const { data } = await api.get(`/conversations/${id}`);
      return data.data;
    },
    enabled: !!id,
    refetchInterval: refetchInterval ?? false,
  });
}

// ── Helper: patch all cached conversations lists ─────────────────────────────
function patchLists(qc, patchFn) {
  qc.setQueriesData({ queryKey: ['conversations'] }, (old) => {
    if (!old?.data) return old;
    return { ...old, data: old.data.map(patchFn) };
  });
}

export function useUpdateConversation() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...payload }) => {
      const { data } = await api.patch(`/conversations/${id}`, payload);
      return data;
    },
    onMutate: async ({ id, title }) => {
      await qc.cancelQueries({ queryKey: ['conversations'] });
      const snapshots = qc.getQueriesData({ queryKey: ['conversations'] });
      // Optimistically update title in list
      if (title !== undefined) {
        patchLists(qc, (c) => c.id === id ? { ...c, title } : c);
      }
      return { snapshots };
    },
    onSuccess: (response, variables) => {
      if (response?.data) {
        qc.setQueryData(['conversations', String(variables.id)], response.data);
      }
      qc.invalidateQueries({ queryKey: ['conversations'] });
      toast.success('Conversation renommée.');
    },
    onError: (err, _vars, context) => {
      context?.snapshots?.forEach(([key, value]) => qc.setQueryData(key, value));
      toast.error(err.response?.data?.message ?? 'Erreur.');
    },
  });
}

export function useDeleteConversation() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async (id) => {
      const { data } = await api.delete(`/conversations/${id}`);
      return data;
    },
    onMutate: async (id) => {
      await qc.cancelQueries({ queryKey: ['conversations'] });
      const snapshots = qc.getQueriesData({ queryKey: ['conversations'] });
      qc.setQueriesData({ queryKey: ['conversations'] }, (old) => {
        if (!old?.data) return old;
        return { ...old, data: old.data.filter((c) => c.id !== id) };
      });
      return { snapshots };
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['conversations'] });
      toast.success('Conversation supprimée.');
    },
    onError: (err, _id, context) => {
      context?.snapshots?.forEach(([key, value]) => qc.setQueryData(key, value));
      toast.error(err.response?.data?.message ?? 'Erreur.');
    },
  });
}

export function useRateConversation() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, rating, comment }) => {
      const { data } = await api.post(`/conversations/${id}/rate`, { rating, comment });
      return data;
    },
    onSuccess: (_data, { id }) => {
      qc.invalidateQueries({ queryKey: ['conversations', String(id)] });
      qc.invalidateQueries({ queryKey: ['conversations'] });
    },
    onError: (err) => {
      toast.error(err.response?.data?.message ?? 'Erreur lors de l\'évaluation.');
    },
  });
}

export function useCloseConversation() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async (id) => {
      const { data } = await api.put(`/conversations/${id}/close`);
      return data;
    },
    onMutate: async (id) => {
      await qc.cancelQueries({ queryKey: ['conversations'] });
      const snapshots = qc.getQueriesData({ queryKey: ['conversations'] });
      // Optimistically mark as closed in list
      patchLists(qc, (c) => c.id === id ? { ...c, status: 'closed' } : c);
      // Also patch the single conversation query
      qc.setQueryData(['conversations', String(id)], (old) =>
        old ? { ...old, status: 'closed' } : old
      );
      return { snapshots };
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['conversations'] });
      toast.success('Consultation clôturée.');
    },
    onError: (err, _id, context) => {
      context?.snapshots?.forEach(([key, value]) => qc.setQueryData(key, value));
      toast.error(err.response?.data?.message ?? 'Erreur.');
    },
  });
}
