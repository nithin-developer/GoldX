import api from './api';

// ----------------------------------------------------------------------

export type ReferralData = {
  id: number;
  referrer: string;
  referred_user: string;
  deposit: number;
  status: string;
};

export type VipUserData = {
  id: number;
  email: string;
  vip_level: number;
  referrals_count: number;
};

export const referralService = {
  getReferrals: async (): Promise<ReferralData[]> => {
    const { data } = await api.get<ReferralData[]>('/admin/referrals');
    return data;
  },

  getVipUsers: async (): Promise<VipUserData[]> => {
    const { data } = await api.get<VipUserData[]>('/admin/vip-users');
    return data;
  },
};
