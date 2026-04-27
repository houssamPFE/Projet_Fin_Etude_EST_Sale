import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../lib/api';
import useAuthStore from '../stores/authStore';

export function useMessages(conversationId) {
  return useQuery({
    queryKey: ['messages', conversationId],
    queryFn: async () => {
      const { data } = await api.get(`/conversations/${conversationId}/messages?per_page=100`);
      return data;
    },
    enabled: !!conversationId,
    staleTime: 0,
  });
}

export function useSendMessage(conversationId) {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);

  return useMutation({
    mutationFn: (content) =>
      api.post(`/conversations/${conversationId}/messages`, { content, type: 'text' }),

    // Optimistic update — show the user's message instantly, before the AI replies
    onMutate: async (content) => {
      await queryClient.cancelQueries({ queryKey: ['messages', conversationId] });
      const previous = queryClient.getQueryData(['messages', conversationId]);

      const tempMessage = {
        id: `temp-${Date.now()}`,
        conversation_id: conversationId,
        sender_type: 'user',
        sender_id: user?.id,
        type: 'text',
        content,
        created_at: new Date().toISOString(),
        _optimistic: true,
      };

      queryClient.setQueryData(['messages', conversationId], (old) => {
        if (!old) return { data: [tempMessage] };
        return { ...old, data: [...(old.data ?? []), tempMessage] };
      });

      return { previous };
    },

    onError: (_err, _content, context) => {
      // Roll back on failure
      if (context?.previous) {
        queryClient.setQueryData(['messages', conversationId], context.previous);
      }
    },

    onSettled: () => {
      // Refetch to replace the temp message with the real one (and pick up AI reply)
      queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}

export function useSendAudio(conversationId) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (blob) => {
      const form = new FormData();
      const ext = blob.type.includes('webm') ? 'webm'
        : blob.type.includes('ogg') ? 'ogg'
        : 'webm';
      form.append('audio', blob, `voice-${Date.now()}.${ext}`);

      const { data } = await api.post(
        `/conversations/${conversationId}/messages/audio`,
        form,
        { headers: { 'Content-Type': 'multipart/form-data' } }
      );
      return data;
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}

export function useCreateConversation() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (payload) => api.post('/conversations', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}
