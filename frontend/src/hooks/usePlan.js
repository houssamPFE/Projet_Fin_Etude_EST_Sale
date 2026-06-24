import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../lib/api';
import useAuthStore from '../stores/authStore';

export const PLANS_META = {
  free: {
    label: 'Gratuit',
    color: '#6b7280',
    gradient: 'linear-gradient(135deg, #4b5563, #6b7280)',
    consultations: 0,
    price: 0,
  },
  pro: {
    label: 'Pro',
    color: '#2563eb',
    gradient: 'linear-gradient(135deg, #1d4ed8, #2563eb)',
    consultations: 3,
    price: 249,
  },
  premium: {
    label: 'Premium',
    color: '#7c3aed',
    gradient: 'linear-gradient(135deg, #6d28d9, #7c3aed, #a855f7)',
    consultations: 6,
    price: 449,
  },
};

export const EXTRA_CREDIT_PRICE = 89;

export function usePlan() {
  const { isAuthenticated } = useAuthStore();

  return useQuery({
    queryKey: ['plan'],
    queryFn: async () => {
      const { data } = await api.get('/users/plan');
      return data.data;
    },
    enabled: isAuthenticated,
    staleTime: 1000 * 60 * 5, // 5 min
  });
}

export function useCreatePaymentIntent() {
  return useMutation({
    mutationFn: async (type) => {
      const { data } = await api.post('/payments/stripe/intent', { type });
      return data.data;
    },
  });
}

export function useConfirmPayment() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (paymentIntentId) => {
      const { data } = await api.post('/payments/stripe/confirm', {
        payment_intent_id: paymentIntentId,
      });
      return data;
    },
    onSuccess: () => {
      // Refresh plan data after successful payment
      queryClient.invalidateQueries({ queryKey: ['plan'] });
    },
  });
}

export function useInitiateCmi() {
  return useMutation({
    mutationFn: async (type) => {
      const { data } = await api.post('/payments/cmi/initiate', { type });
      return data.data;
    },
  });
}
