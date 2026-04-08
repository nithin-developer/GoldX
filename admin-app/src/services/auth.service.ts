import type { AxiosError } from 'axios';

import api from './api';

// ----------------------------------------------------------------------

export type LoginPayload = {
  email: string;
  password: string;
};

export type LoginResponse = {
  access_token: string;
  refresh_token?: string;
  email: string;
  full_name?: string | null;
  role: string;
};

type ErrorPayload = {
  detail?: string;
  message?: string;
};

type UserProfileResponse = {
  email: string;
  full_name?: string | null;
  role: string;
};

export function getApiErrorMessage(error: unknown, fallback = 'Request failed. Please try again.') {
  const axiosError = error as AxiosError<ErrorPayload>;

  if (axiosError?.response?.data?.detail) {
    return axiosError.response.data.detail;
  }

  if (axiosError?.response?.data?.message) {
    return axiosError.response.data.message;
  }

  if (axiosError?.message) {
    return axiosError.message;
  }

  return fallback;
}

export const authService = {
  login: async (payload: LoginPayload): Promise<LoginResponse> => {
    const { data } = await api.post<{ access_token: string; refresh_token?: string }>('/auth/login', payload);

    localStorage.setItem('access_token', data.access_token);

    const me = await api.get<UserProfileResponse>('/auth/me');

    return {
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      email: me.data.email,
      full_name: me.data.full_name,
      role: me.data.role,
    };
  },

  logout: () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('admin_user');
  },
};
