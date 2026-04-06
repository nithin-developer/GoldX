import api from './api';

// ----------------------------------------------------------------------

export type UserData = {
  id: number;
  email: string;
  full_name?: string | null;
  wallet_balance?: number | string | null;
  capital_balance?: number | string | null;
  signal_profit_balance?: number | string | null;
  reward_balance?: number | string | null;
  withdrawable_balance?: number | string | null;
  locked_capital_balance?: number | string | null;
  wallet_address?: string | null;
  referral_count?: number | null;
  referral_total_deposits?: number | string | null;
  vip_level?: number | null;
  is_active?: boolean;
  created_at?: string;
};

export type GetUsersParams = {
  search?: string;
  role?: 'user' | 'admin';
  skip?: number;
  limit?: number;
};

export type UserReferralItem = {
  referral_id: number;
  referred_user_id: number;
  referred_email?: string | null;
  referred_full_name?: string | null;
  deposit_amount: number | string;
  bonus_amount: number | string;
  status: string;
  created_at: string;
};

export const userService = {
  getUsers: async (params?: GetUsersParams): Promise<UserData[]> => {
    const { data } = await api.get<UserData[]>('/admin/users', {
      params: {
        search: params?.search?.trim() || undefined,
        role: params?.role,
        skip: params?.skip,
        limit: params?.limit,
      },
    });
    return data;
  },

  updateUser: async (id: number, payload: Partial<UserData>): Promise<UserData> => {
    const { data } = await api.put<UserData>(`/admin/users/${id}`, payload);
    return data;
  },

  resetWithdrawalPassword: async (id: number): Promise<void> => {
    await api.post(`/admin/users/${id}/reset-withdrawal-password`);
  },

  getUserReferrals: async (id: number): Promise<UserReferralItem[]> => {
    const { data } = await api.get<UserReferralItem[]>(`/admin/users/${id}/referrals`);
    return data;
  },

  deleteUser: async (id: number): Promise<void> => {
    await api.delete(`/admin/users/${id}`);
  },
};
