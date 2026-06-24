import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../lib/api';
import useAuthStore from '../stores/authStore';

export function useMessages(conversationId, { refetchInterval } = {}) {
  return useQuery({
    queryKey: ['messages', conversationId],
    queryFn: async () => {
      const { data } = await api.get(`/conversations/${conversationId}/messages?per_page=100`);
      return data;
    },
    enabled: !!conversationId,
    staleTime: 0,
    // Fallback poll so missed WebSocket events are caught within 15 s
    refetchInterval: refetchInterval ?? 15_000,
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
        sender_type: user?.role === 'expert' ? 'expert' : 'user',
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
      // Do NOT invalidate messages here — the WebSocket .message.sent event handles
      // replacing the temp optimistic message with the real one. Invalidating here
      // causes the "double bubble" flicker (temp id → real id key change).
      // Just update the conversations list for unread count / last message preview.
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}

export function useSendAudio(conversationId) {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);

  return useMutation({
    mutationFn: async (blob) => {
      const form = new FormData();
      const ext = blob.type.includes('webm') ? 'webm'
        : blob.type.includes('ogg') ? 'ogg'
        : 'webm';
      form.append('audio', blob, `voice-${Date.now()}.${ext}`);

      // Do NOT set Content-Type manually — browser must set it automatically
      // with the correct multipart boundary. Manual override breaks the request.
      const { data } = await api.post(
        `/conversations/${conversationId}/messages/audio`,
        form
      );
      return data;
    },

    // Show a local blob preview immediately while uploading
    onMutate: async (blob) => {
      await queryClient.cancelQueries({ queryKey: ['messages', conversationId] });
      const previous = queryClient.getQueryData(['messages', conversationId]);

      const tempMessage = {
        id: `temp-audio-${Date.now()}`,
        conversation_id: conversationId,
        sender_type: user?.role === 'expert' ? 'expert' : 'user',
        sender_id: user?.id,
        type: 'audio',
        audio_url: URL.createObjectURL(blob),
        created_at: new Date().toISOString(),
        _optimistic: true,
      };

      queryClient.setQueryData(['messages', conversationId], (old) => {
        if (!old) return { data: [tempMessage] };
        return { ...old, data: [...(old.data ?? []), tempMessage] };
      });

      return { previous };
    },

    onError: (_err, _blob, context) => {
      if (context?.previous) {
        queryClient.setQueryData(['messages', conversationId], context.previous);
      }
    },

    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}

export function useSendFile(conversationId) {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);

  return useMutation({
    mutationFn: async (file) => {
      const form = new FormData();
      form.append('file', file);
      const { data } = await api.post(
        `/conversations/${conversationId}/messages/file`,
        form
      );
      return data;
    },

    onMutate: async (file) => {
      await queryClient.cancelQueries({ queryKey: ['messages', conversationId] });
      const previous = queryClient.getQueryData(['messages', conversationId]);

      const isImage = file.type.startsWith('image/');
      const tempMessage = {
        id: `temp-file-${Date.now()}`,
        conversation_id: conversationId,
        sender_type: user?.role === 'expert' ? 'expert' : 'user',
        sender_id: user?.id,
        type: 'file',
        content: file.name,
        media_url: isImage ? URL.createObjectURL(file) : null,
        _optimistic: true,
        _isImage: isImage,
      };

      queryClient.setQueryData(['messages', conversationId], (old) => {
        if (!old) return { data: [tempMessage] };
        return { ...old, data: [...(old.data ?? []), tempMessage] };
      });

      return { previous };
    },

    onError: (_err, _file, context) => {
      if (context?.previous) {
        queryClient.setQueryData(['messages', conversationId], context.previous);
      }
    },

    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });
}

/**
 * Mark all messages in a conversation as read for the current user.
 * Call this when the user opens a conversation so the unread badge clears.
 */
export function useMarkAllRead(conversationId) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: () =>
      api.put(`/conversations/${conversationId}/messages/read-all`),
    onSuccess: () => {
      // Refresh the conversations list so the unread badge disappears instantly
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
