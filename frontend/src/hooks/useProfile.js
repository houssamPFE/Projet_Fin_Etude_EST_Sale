import { useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../lib/api';
import useAuthStore from '../stores/authStore';

export function useUpdateProfile() {
  const queryClient = useQueryClient();
  const setUser     = useAuthStore((s) => s.init);

  return useMutation({
    mutationFn: (data) => api.put('/users/profile', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['me'] });
      setUser(); // refresh user in store
    },
  });
}

export function useUploadAvatar() {
  const setUser = useAuthStore((s) => s.init);

  return useMutation({
    mutationFn: (file) => {
      const form = new FormData();
      form.append('avatar', file);
      return api.post('/users/avatar', form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    },
    onSuccess: () => setUser(),
  });
}

export function useApplyExpert() {
  return useMutation({
    mutationFn: (formData) =>
      api.post('/expert/apply', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      }),
  });
}
