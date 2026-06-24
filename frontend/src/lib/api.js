import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Attach access token to every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  // When sending FormData (file uploads), remove the default Content-Type
  // so the browser sets it automatically with the correct multipart boundary.
  if (config.data instanceof FormData) {
    delete config.headers['Content-Type'];
  }
  return config;
});

// --- Refresh-token coordination ---
// Only one refresh call flies at a time; other 401s wait on the same promise.
let isRefreshing = false;
let pendingQueue = [];

function resolveQueue(newToken) {
  pendingQueue.forEach(({ resolve }) => resolve(newToken));
  pendingQueue = [];
}

function rejectQueue(error) {
  pendingQueue.forEach(({ reject }) => reject(error));
  pendingQueue = [];
}

function forceLogout() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  if (window.location.pathname !== '/login') {
    window.location.href = '/login';
  }
}

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    const status = error.response?.status;

    // Maintenance mode — redirect unless this is the login endpoint
    // (login page handles it inline with a banner).
    if (status === 503 && error.response?.data?.maintenance) {
      const isLoginCall = originalRequest?.url?.includes('/auth/login');
      if (!isLoginCall && window.location.pathname !== '/maintenance') {
        window.location.href = '/maintenance';
      }
      return Promise.reject(error);
    }

    // Not a 401, or the request that failed WAS the refresh itself, or
    // we've already retried this request once → bail out.
    const isRefreshCall = originalRequest?.url?.includes('/auth/refresh');
    if (status !== 401 || isRefreshCall || originalRequest?._retry) {
      if (status === 401 && isRefreshCall) forceLogout();
      return Promise.reject(error);
    }

    const refreshToken = localStorage.getItem('refresh_token');
    if (!refreshToken) {
      forceLogout();
      return Promise.reject(error);
    }

    originalRequest._retry = true;

    // If a refresh is already in flight, queue this request until it resolves.
    if (isRefreshing) {
      return new Promise((resolve, reject) => {
        pendingQueue.push({
          resolve: (token) => {
            originalRequest.headers.Authorization = `Bearer ${token}`;
            resolve(api(originalRequest));
          },
          reject,
        });
      });
    }

    isRefreshing = true;
    try {
      const { data } = await api.post('/auth/refresh', {
        refresh_token: refreshToken,
      });
      // Accept both { data: { token: { access_token, refresh_token } } }
      // and { access_token, refresh_token } shapes.
      const payload = data?.data?.token ?? data?.data ?? data;
      const newAccess = payload.access_token;
      const newRefresh = payload.refresh_token ?? refreshToken;

      if (!newAccess) throw new Error('Malformed refresh response');

      localStorage.setItem('access_token', newAccess);
      localStorage.setItem('refresh_token', newRefresh);

      resolveQueue(newAccess);
      originalRequest.headers.Authorization = `Bearer ${newAccess}`;
      return api(originalRequest);
    } catch (refreshErr) {
      rejectQueue(refreshErr);
      forceLogout();
      return Promise.reject(refreshErr);
    } finally {
      isRefreshing = false;
    }
  }
);

export default api;
