import api from './api';

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
  qr_code_url?: string | null;
  updated_at?: string | null;
};

export type UpdateDepositSettingsPayload = {
  currency: string;
  network?: string;
  wallet_address?: string;
  instructions?: string;
  qr_code?: File;
};

const buildStatusParams = (status?: string) => {
  if (!status || status === 'all') {
    return undefined;
  }

  return { status };
};

export const walletAdminService = {
  getDeposits: async (status = 'all'): Promise<AdminDeposit[]> => {
    const { data } = await api.get<AdminDeposit[]>('/admin/deposits', {
      params: buildStatusParams(status),
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

  getWithdrawals: async (status = 'all'): Promise<AdminWithdrawal[]> => {
    const { data } = await api.get<AdminWithdrawal[]>('/admin/withdrawals', {
      params: buildStatusParams(status),
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
