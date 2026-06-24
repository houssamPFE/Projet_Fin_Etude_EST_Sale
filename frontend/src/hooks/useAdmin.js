import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../lib/api';
import toast from 'react-hot-toast';

const invalidate = (qc, key) => qc.invalidateQueries({ queryKey: key, exact: false });

export function useAdminDashboard() {
  return useQuery({
    queryKey: ['admin', 'dashboard'],
    queryFn: async () => {
      const { data } = await api.get('/admin/dashboard');
      return data.data;
    },
    staleTime: 60_000,
    retry: 2,
    retryDelay: 1500,
  });
}

export function useAdminUsers(params = {}) {
  return useQuery({
    queryKey: ['admin', 'users', params],
    queryFn: async () => {
      const { data } = await api.get('/admin/users', { params });
      return data;
    },
    staleTime: 30_000,
    placeholderData: (prev) => prev,
  });
}

export function useAdminUserStats() {
  return useQuery({
    queryKey: ['admin', 'users', 'stats'],
    queryFn: async () => {
      const { data } = await api.get('/admin/users/stats');
      return data.data;
    },
    staleTime: 30_000,
  });
}

export function useBulkSuspendUsers() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (ids) => api.put('/admin/users/bulk-suspend', { ids }),
    onSuccess: async (res) => {
      await invalidate(qc, ['admin', 'users']);
      toast.success(res.data?.message || 'Utilisateurs suspendus.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useToggleUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (userId) => api.put(`/admin/users/${userId}/toggle`),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'users']);
      toast.success('Statut mis à jour.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useUpdateUserSecurity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, data }) => api.put(`/admin/users/${userId}/security`, data),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'users']);
      toast.success('Paramètres de sécurité mis à jour.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useUpdateUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }) => api.put(`/admin/users/${id}`, payload),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'users']);
      toast.success('Utilisateur mis à jour.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useAdminChangePlan() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, plan, credits, expiresAt }) =>
      api.put(`/admin/users/${userId}/plan`, {
        plan,
        consultation_credits: credits,
        plan_expires_at: expiresAt || null,
      }),
    onSuccess: async (res) => {
      await invalidate(qc, ['admin', 'users']);
      toast.success(res.data?.message || 'Plan mis à jour.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur lors du changement de plan.'),
  });
}

export function useAdminPendingExperts() {
  return useQuery({
    queryKey: ['admin', 'experts', 'queue'],
    queryFn: async () => {
      const { data } = await api.get('/admin/experts', { params: { per_page: 200 } });
      const all   = Array.isArray(data.data) ? data.data : [];
      const stats = data.stats ?? {};
      return { all, stats };
    },
  });
}

export function useAdminExperts(params = {}) {
  return useQuery({
    queryKey: ['admin', 'experts', params],
    queryFn: async () => {
      const { data } = await api.get('/admin/experts', { params });
      return data;
    },
  });
}

export function useToggleExpert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.put(`/admin/experts/${id}/toggle`),
    onSuccess: async (res) => {
      await invalidate(qc, ['admin', 'experts']);
      toast.success(res.data?.message || 'Disponibilité modifiée.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useValidateExpert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.put(`/admin/experts/${id}/validate`),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'experts']);
      toast.success('Expert validé.');
    },
    onError: () => toast.error('Erreur lors de la validation.'),
  });
}

export function useRejectExpert() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, reason }) => api.put(`/admin/experts/${id}/reject`, { reason }),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'experts']);
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
      return Array.isArray(data.data) ? data.data : [];
    },
  });
}

export function useConversationCleanupPreview(params) {
  return useQuery({
    queryKey: ['admin', 'conversations', 'cleanup', 'preview', params],
    queryFn: async () => {
      const { data } = await api.get('/admin/conversations/cleanup/preview', { params });
      return data.count ?? 0;
    },
    enabled: !!params,
  });
}

export function useConversationCleanup() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (params) => {
      const { data } = await api.delete('/admin/conversations/cleanup', { data: params });
      return data;
    },
    onSuccess: (data) => {
      toast.success(data.message ?? 'Conversations supprimées.');
      invalidate(qc, ['admin', 'conversations']);
    },
    onError: () => toast.error('Erreur lors de la suppression.'),
  });
}

export function useCreateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload) => api.post('/admin/categories', payload),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'categories']);
      toast.success('Catégorie créée.');
    },
    onError: () => toast.error('Erreur lors de la création.'),
  });
}

export function useUpdateCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...payload }) => api.put(`/admin/categories/${id}`, payload),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'categories']);
      toast.success('Catégorie mise à jour.');
    },
    onError: () => toast.error('Erreur lors de la mise à jour.'),
  });
}

export function useDeleteCategory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.delete(`/admin/categories/${id}`),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'categories']);
      toast.success('Catégorie supprimée.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

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
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'knowledge']);
      toast.success('Entrée créée.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur lors de la création.'),
  });
}

export function useUpdateKnowledge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...payload }) => api.put(`/admin/knowledge/${id}`, payload),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'knowledge']);
      toast.success('Entrée mise à jour.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useDeleteKnowledge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id) => api.delete(`/admin/knowledge/${id}`),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'knowledge']);
      toast.success('Entrée supprimée.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur.'),
  });
}

export function useAdminSettings() {
  return useQuery({
    queryKey: ['admin', 'settings'],
    queryFn: async () => {
      const { data } = await api.get('/admin/settings');
      return data;
    },
  });
}

export function useUpdateAdminSettings() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload) => api.put('/admin/settings', payload),
    onSuccess: async () => {
      await invalidate(qc, ['admin', 'settings']);
      toast.success('Paramètres mis à jour avec succès.');
    },
    onError: (err) => toast.error(err.response?.data?.message || 'Erreur lors de la mise à jour.'),
  });
}
