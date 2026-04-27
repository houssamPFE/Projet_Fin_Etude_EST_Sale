import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../lib/api';
import toast from 'react-hot-toast';

export function useAdminDashboard() {
  return useQuery({
    queryKey: ['admin', 'dashboard'],
    queryFn: async () => {
      const { data } = await api.get('/admin/dashboard');
      return data.data;
    },
  });
}

export function useAdminUsers(params = {}) {
  return useQuery({
    queryKey: ['admin', 'users', params],
    queryFn: async () => {
      const { data } = await api.get('/admin/users', { params });
      return data;
    },
  });
}

export function useToggleUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.put(`/admin/users/${id}/toggle`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'users'] });
      toast.success('Statut mis à jour.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useAdminPendingExperts() {
  return useQuery({
    queryKey: ['admin', 'experts', 'pending'],
    queryFn: async () => {
      const { data } = await api.get('/admin/experts/pending');
      return data.data;
    },
  });
}

export function useValidateExpert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.put(`/admin/experts/${id}/validate`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'experts'] });
      toast.success('Expert validé.');
    },
    onError: () => toast.error('Erreur lors de la validation.'),
  });
}

export function useRejectExpert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, reason }) => api.put(`/admin/experts/${id}/reject`, { reason }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'experts'] });
      toast.success('Expert rejeté.');
    },
    onError: () => toast.error('Erreur lors du rejet.'),
  });
}

export function useAdminConversations(params = {}) {
  return useQuery({
    queryKey: ['admin', 'conversations', params],
    queryFn: async () => {
      const { data } = await api.get('/admin/conversations', { params });
      return data;
    },
  });
}

export function useAdminPayments(params = {}) {
  return useQuery({
    queryKey: ['admin', 'payments', params],
    queryFn: async () => {
      const { data } = await api.get('/admin/payments', { params });
      return data;
    },
  });
}

export function useAdminCategories() {
  return useQuery({
    queryKey: ['admin', 'categories'],
    queryFn: async () => {
      const { data } = await api.get('/admin/categories');
      return data.data;
    },
  });
}

export function useCreateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload) => api.post('/admin/categories', payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'categories'] });
      toast.success('Catégorie créée.');
    },
    onError: () => toast.error('Erreur lors de la création.'),
  });
}

export function useUpdateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...payload }) => api.put(`/admin/categories/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'categories'] });
      toast.success('Catégorie mise à jour.');
    },
    onError: () => toast.error('Erreur lors de la mise à jour.'),
  });
}

export function useDeleteCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.delete(`/admin/categories/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'categories'] });
      toast.success('Catégorie supprimée.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

// ── Knowledge base ───────────────────────────────────────────────
export function useAdminKnowledge(params = {}) {
  return useQuery({
    queryKey: ['admin', 'knowledge', params],
    queryFn: async () => {
      const { data } = await api.get('/admin/knowledge', { params });
      return data;
    },
  });
}

export function useCreateKnowledge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload) => api.post('/admin/knowledge', payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'knowledge'] });
      toast.success('Entrée créée.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur lors de la création.'),
  });
}

export function useUpdateKnowledge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...payload }) => api.put(`/admin/knowledge/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'knowledge'] });
      toast.success('Entrée mise à jour.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useDeleteKnowledge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.delete(`/admin/knowledge/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin', 'knowledge'] });
      toast.success('Entrée supprimée.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}
