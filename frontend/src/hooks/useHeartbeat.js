import { useEffect } from 'react';
import useAuthStore from '../stores/authStore';
import api from '../lib/api';

/**
 * Manages online presence for the authenticated user.
 *
 * - Sends a heartbeat every `intervalMs` ms (Redis TTL reset)
 * - On tab hidden / minimized / closed  → POST /users/offline instantly
 * - On tab visible again (came back)    → POST /users/heartbeat instantly
 *
 * Note: visibilitychange fires before page unload in all modern browsers,
 * so it also covers tab/window close without needing sendBeacon.
 */
export function useHeartbeat(intervalMs = 30_000) {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);

  useEffect(() => {
    if (!isAuthenticated) return;

    const sendHeartbeat = () => api.post('/users/heartbeat').catch(() => {});
    const sendOffline   = () => api.post('/users/offline').catch(() => {});

    // Fire immediately on mount so the user appears online right away
    sendHeartbeat();
    const id = setInterval(sendHeartbeat, intervalMs);

    // Page Visibility API — covers: tab switch, minimize, tab close, window close
    const handleVisibility = () => {
      if (document.visibilityState === 'hidden') {
        sendOffline();
      } else {
        sendHeartbeat(); // returning to foreground
      }
    };

    document.addEventListener('visibilitychange', handleVisibility);

    return () => {
      clearInterval(id);
      document.removeEventListener('visibilitychange', handleVisibility);
    };
  }, [isAuthenticated, intervalMs]);
}
