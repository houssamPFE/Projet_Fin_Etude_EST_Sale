import { useQuery } from '@tanstack/react-query';
import api from '../lib/api';

export function useExperts(params = {}) {
  return useQuery({
    queryKey: ['experts', params],
    queryFn: async () => {
      const { data } = await api.get('/experts', { params });
      return data;
    },
    refetchInterval: 20_000, // refresh every 20 s for live online dots
  });
}

export function useExpert(id) {
  return useQuery({
    queryKey: ['experts', id],
    queryFn: async () => {
      const { data } = await api.get(`/experts/${id}`);
      return data.data;
    },
    enabled: !!id,
    refetchInterval: 20_000, // refresh every 20 s for live online dot on profile
  });
}

export function useExpertReviews(id, params = {}) {
  return useQuery({
    queryKey: ['experts', id, 'reviews', params],
    queryFn: async () => {
      const { data } = await api.get(`/experts/${id}/reviews`, { params });
      return data;
    },
    enabled: !!id,
  });
}

export function useCategories() {
  return useQuery({
    queryKey: ['categories'],
    queryFn: async () => {
      const { data } = await api.get('/categories');
      return Array.isArray(data.data) ? data.data : [];
    },
    staleTime: 1000 * 60 * 10,
  });
}
