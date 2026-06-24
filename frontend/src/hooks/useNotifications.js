import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../lib/api';

export function useNotifications(params = {}) {
  return useQuery({
    queryKey: ['notifications', params],
    queryFn: async () => {
      const { data } = await api.get('/notifications', { params });
      return data;
    },
  });
}

export function useMarkAsRead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.put(`/notifications/${id}/read`),
    onMutate: async (id) => {
      await qc.cancelQueries({ queryKey: ['notifications'] });
      const snapshots = qc.getQueriesData({ queryKey: ['notifications'] });
      qc.setQueriesData({ queryKey: ['notifications'] }, (old) => {
        if (!old?.data) return old;
        return {
          ...old,
          data: old.data.map((n) =>
            n.id === id ? { ...n, read_at: new Date().toISOString() } : n
          ),
        };
      });
      return { snapshots };
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notifications'] }),
    onError: (_err, _id, context) => {
      context?.snapshots?.forEach(([key, value]) => qc.setQueryData(key, value));
    },
  });
}

export function useMarkAllAsRead() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => api.put('/notifications/read-all'),
    onMutate: async () => {
      await qc.cancelQueries({ queryKey: ['notifications'] });
      const snapshots = qc.getQueriesData({ queryKey: ['notifications'] });
      qc.setQueriesData({ queryKey: ['notifications'] }, (old) => {
        if (!old?.data) return old;
        const now = new Date().toISOString();
        return {
          ...old,
          data: old.data.map((n) => ({ ...n, read_at: n.read_at ?? now })),
        };
      });
      return { snapshots };
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['notifications'] }),
    onError: (_err, _vars, context) => {
      context?.snapshots?.forEach(([key, value]) => qc.setQueryData(key, value));
    },
  });
}
