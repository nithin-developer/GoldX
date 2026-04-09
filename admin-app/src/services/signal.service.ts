import api, { type PaginatedResponse } from './api';

// ----------------------------------------------------------------------

export type SignalData = {
  id: string;
  asset: string;
  direction: string;
  profit_percent: number;
  duration_hours: number;
  duration_unit?: 'hours' | 'minutes';
  status: string;
  vip_only: boolean;
  activated_users_count?: number;
  created_at?: string;
};

export type CreateSignalPayload = {
  asset: string;
  direction: string;
  profit_percent: number;
  duration_hours: number;
  duration_unit: 'hours' | 'minutes';
  vip_only: boolean;
};

export type GetSignalsParams = {
  skip?: number;
  limit?: number;
};

export type SignalCodeResponse = {
  id?: number;
  signal_id?: string;
  code: string;
  expires_at: string;
  activated_users_count: number;
  created_at?: string;
};

type SignalCodeApiResponse = SignalCodeResponse | SignalCodeResponse[];

export const signalService = {
  getSignals: async (params?: GetSignalsParams): Promise<PaginatedResponse<SignalData>> => {
    const { data } = await api.get<PaginatedResponse<SignalData>>('/admin/signals', {
      params: {
        skip: params?.skip,
        limit: params?.limit,
      },
    });
    return data;
  },

  createSignal: async (payload: CreateSignalPayload): Promise<SignalData> => {
    const { data } = await api.post<SignalData>('/admin/signals', payload);
    return data;
  },

  deleteSignal: async (id: string): Promise<void> => {
    await api.delete(`/admin/signals/${id}`);
  },

  generateCode: async (signalId: string): Promise<SignalCodeResponse> => {
    const { data } = await api.post<SignalCodeApiResponse>(`/admin/signals/${signalId}/generate-code`);

    const resolved = Array.isArray(data) ? data[0] : data;
    if (!resolved?.code || !resolved?.expires_at) {
      throw new Error('Invalid signal code response');
    }

    return {
      ...resolved,
      activated_users_count: Number(resolved.activated_users_count ?? 0),
    };
  },
};
