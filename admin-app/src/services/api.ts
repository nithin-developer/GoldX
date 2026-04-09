import axios from 'axios';

import { CONFIG } from 'src/config-global';

// ----------------------------------------------------------------------

export type PaginatedResponse<T> = {
  items: T[];
  total: number;
  skip: number;
  limit: number;
};

// ----------------------------------------------------------------------

const api = axios.create({
  baseURL: CONFIG.apiUrl,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach JWT token to every request
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Handle 401 responses globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const requestUrl: string = error.config?.url ?? '';
      const isLoginRequest = requestUrl.includes('/auth/login');

      if (isLoginRequest) {
        return Promise.reject(error);
      }

      localStorage.removeItem('access_token');
      localStorage.removeItem('admin_user');
      window.location.href = '/sign-in';
    }
    return Promise.reject(error);
  }
);

export default api;
