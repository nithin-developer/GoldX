import api, { type PaginatedResponse } from './api';

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

export type GetReferralListParams = {
  skip?: number;
  limit?: number;
};

export const referralService = {
  getReferrals: async (
    params?: GetReferralListParams
  ): Promise<PaginatedResponse<ReferralData>> => {
    const { data } = await api.get<PaginatedResponse<ReferralData>>('/admin/referrals', {
      params: {
        skip: params?.skip,
        limit: params?.limit,
      },
    });
    return data;
  },

  getVipUsers: async (
    params?: GetReferralListParams
  ): Promise<PaginatedResponse<VipUserData>> => {
    const { data } = await api.get<PaginatedResponse<VipUserData>>('/admin/vip-users', {
      params: {
        skip: params?.skip,
        limit: params?.limit,
      },
    });
    return data;
  },
};
