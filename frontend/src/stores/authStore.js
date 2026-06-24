import { create } from 'zustand';
import api from '../lib/api';
import { disconnectEcho } from '../lib/echo';

const useAuthStore = create((set) => ({
  user: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,

  // Initialize — check if we have a stored token and fetch user
  init: async () => {
    const token = localStorage.getItem('access_token');
    if (!token) {
      set({ isLoading: false, isAuthenticated: false });
      return;
    }
    try {
      const { data } = await api.get('/auth/me');
      set({ user: data.data, isAuthenticated: true, isLoading: false });
    } catch {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      set({ user: null, isAuthenticated: false, isLoading: false });
    }
  },

  // Login
  login: async (email, password) => {
    set({ error: null });
    try {
      const { data } = await api.post('/auth/login', { email, password });

      // Check if 2FA is required
      if (data.requires_2fa_setup) {
        return { requires2fa: true, requires2faSetup: true, token: data.two_factor_token, setupData: data.setup_data };
      }
      if (data.requires_2fa) {
        return { requires2fa: true, requires2faSetup: false, token: data.two_factor_token };
      }

      localStorage.setItem('access_token', data.data.token.access_token);
      localStorage.setItem('refresh_token', data.data.token.refresh_token);
      set({ user: data.data.user, isAuthenticated: true });
      return { success: true, user: data.data.user };
    } catch (err) {
      const message = err.response?.data?.message || 'Erreur de connexion.';
      const maintenance = err.response?.data?.maintenance === true;
      set({ error: maintenance ? null : message });
      return { success: false, error: message, maintenance };
    }
  },

  // Verify 2FA
  verify2fa: async (twoFactorToken, code) => {
    set({ error: null });
    try {
      const { data } = await api.post('/auth/2fa/verify', {
        two_factor_token: twoFactorToken,
        code,
      });
      localStorage.setItem('access_token', data.data.token.access_token);
      localStorage.setItem('refresh_token', data.data.token.refresh_token);
      set({ user: data.data.user, isAuthenticated: true });
      return { success: true, user: data.data.user };
    } catch (err) {
      const message = err.response?.data?.message || 'Code invalide.';
      set({ error: message });
      return { success: false, error: message };
    }
  },

  completeAuth: async (accessToken, refreshToken) => {
    set({ error: null });
    localStorage.setItem('access_token', accessToken);
    localStorage.setItem('refresh_token', refreshToken);

    try {
      const { data } = await api.get('/auth/me');
      set({ user: data.data, isAuthenticated: true });
      return { success: true, user: data.data };
    } catch (err) {
      localStorage.removeItem('access_token');
      localStorage.removeItem('refresh_token');
      set({ user: null, isAuthenticated: false });
      const message = err.response?.data?.message || 'Connexion sociale impossible.';
      set({ error: message });
      return { success: false, error: message };
    }
  },

  // Register
  register: async (name, email, password, passwordConfirmation) => {
    set({ error: null });
    try {
      const { data } = await api.post('/auth/register', {
        name,
        email,
        password,
        password_confirmation: passwordConfirmation,
      });
      return { success: true, message: data.message };
    } catch (err) {
      const message = err.response?.data?.message || 'Erreur d\'inscription.';
      const errors = err.response?.data?.errors || {};
      set({ error: message });
      return { success: false, error: message, errors };
    }
  },

  // Logout
  logout: async () => {
    try {
      await api.post('/auth/logout');
    } catch {
      // Ignore errors
    }
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    disconnectEcho();
    set({ user: null, isAuthenticated: false });
  },

  clearError: () => set({ error: null }),
}));

export default useAuthStore;
