import api from './api';

// ----------------------------------------------------------------------

export type UserData = {
  id: number;
  email: string;
  wallet_balance?: number | string | null;
  vip_level?: number | null;
  status?: string;
  is_active?: boolean;
  created_at?: string;
};

export const userService = {
  getUsers: async (): Promise<UserData[]> => {
    const { data } = await api.get<UserData[]>('/admin/users');
    return data;
  },

  updateUser: async (id: number, payload: Partial<UserData>): Promise<UserData> => {
    const { data } = await api.put<UserData>(`/admin/users/${id}`, payload);
    return data;
  },
};
