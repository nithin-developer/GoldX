import api, { type PaginatedResponse } from './api';

// ----------------------------------------------------------------------

export type AdminDeposit = {
  id: string;
  user_id: number;
  amount: number | string;
  status: string;
  transaction_ref?: string | null;
  payment_proof_url?: string | null;
  admin_note?: string | null;
  created_at: string;
};

export type AdminWithdrawal = {
  id: string;
  user_id: number;
  amount: number | string;
  status: string;
  wallet_address?: string | null;
  admin_note?: string | null;
  created_at: string;
};

export type DepositSettings = {
  currency: string;
  network?: string | null;
  wallet_address?: string | null;
  instructions?: string | null;
  support_url?: string | null;
  qr_code_url?: string | null;
  updated_at?: string | null;
};

export type UpdateDepositSettingsPayload = {
  currency: string;
  network?: string;
  wallet_address?: string;
  instructions?: string;
  support_url?: string;
  qr_code?: File;
};

export type GetAdminListParams = {
  status?: string;
  skip?: number;
  limit?: number;
};

const buildStatusParams = (status?: string) => {
  if (!status || status === 'all') {
    return undefined;
  }

  return { status };
};

const buildListParams = (params?: GetAdminListParams) => ({
  ...buildStatusParams(params?.status),
  skip: params?.skip,
  limit: params?.limit,
});

export const walletAdminService = {
  getDeposits: async (params?: GetAdminListParams): Promise<PaginatedResponse<AdminDeposit>> => {
    const { data } = await api.get<PaginatedResponse<AdminDeposit>>('/admin/deposits', {
      params: buildListParams(params),
    });
    return data;
  },

  approveDeposit: async (depositId: string, adminNote?: string): Promise<AdminDeposit> => {
    const { data } = await api.put<AdminDeposit>(`/admin/deposits/${depositId}/approve`, {
      admin_note: adminNote,
    });
    return data;
  },

  rejectDeposit: async (depositId: string, adminNote?: string): Promise<AdminDeposit> => {
    const { data } = await api.put<AdminDeposit>(`/admin/deposits/${depositId}/reject`, {
      admin_note: adminNote,
    });
    return data;
  },

  getWithdrawals: async (
    params?: GetAdminListParams
  ): Promise<PaginatedResponse<AdminWithdrawal>> => {
    const { data } = await api.get<PaginatedResponse<AdminWithdrawal>>('/admin/withdrawals', {
      params: buildListParams(params),
    });
    return data;
  },

  approveWithdrawal: async (withdrawalId: string, adminNote?: string): Promise<AdminWithdrawal> => {
    const { data } = await api.put<AdminWithdrawal>(`/admin/withdrawals/${withdrawalId}/approve`, {
      admin_note: adminNote,
    });
    return data;
  },

  rejectWithdrawal: async (withdrawalId: string, adminNote?: string): Promise<AdminWithdrawal> => {
    const { data } = await api.put<AdminWithdrawal>(`/admin/withdrawals/${withdrawalId}/reject`, {
      admin_note: adminNote,
    });
    return data;
  },

  getDepositSettings: async (): Promise<DepositSettings> => {
    const { data } = await api.get<DepositSettings>('/admin/settings/deposit');
    return data;
  },

  updateDepositSettings: async (
    payload: UpdateDepositSettingsPayload
  ): Promise<DepositSettings> => {
    const formData = new FormData();
    formData.append('currency', payload.currency);

    if (payload.network !== undefined) {
      formData.append('network', payload.network);
    }

    if (payload.wallet_address !== undefined) {
      formData.append('wallet_address', payload.wallet_address);
    }

    if (payload.instructions !== undefined) {
      formData.append('instructions', payload.instructions);
    }

    if (payload.support_url !== undefined) {
      formData.append('support_url', payload.support_url);
    }

    if (payload.qr_code) {
      formData.append('qr_code', payload.qr_code);
    }

    const { data } = await api.put<DepositSettings>('/admin/settings/deposit', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });

    return data;
  },
};
