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

export function useUpdateConversation() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...payload }) => {
      const { data } = await api.patch(`/conversations/${id}`, payload);
      return data;
    },
    onSuccess: (response, variables) => {
      if (response?.data) {
        qc.setQueryData(['conversations', String(variables.id)], response.data);
      }
      qc.invalidateQueries({ queryKey: ['conversations'] });
      toast.success('Conversation renommee.');
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Erreur.'),
  });
}

export function useDeleteConversation() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: async (id) => {
      const { data } = await api.delete(`/conversations/${id}`);
      return data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['conversations'] });
      toast.success('Conversation supprimee.');
    },
    onError: (err) => toast.error(err.response?.data?.message ?? 'Erreur.'),
  });
}
