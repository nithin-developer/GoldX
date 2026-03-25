import api from './api';

// ----------------------------------------------------------------------

export type SignalData = {
  id: number;
  asset: string;
  direction: string;
  profit_percent: number;
  duration_hours: number;
  status: string;
  created_at?: string;
};

export type CreateSignalPayload = {
  asset: string;
  direction: string;
  profit_percent: number;
  duration_hours: number;
};

export type SignalCodeResponse = {
  code: string;
  expires_at: string;
};

export const signalService = {
  getSignals: async (): Promise<SignalData[]> => {
    const { data } = await api.get<SignalData[]>('/admin/signals');
    return data;
  },

  createSignal: async (payload: CreateSignalPayload): Promise<SignalData> => {
    const { data } = await api.post<SignalData>('/admin/signals', payload);
    return data;
  },

  deleteSignal: async (id: number): Promise<void> => {
    await api.delete(`/admin/signals/${id}`);
  },

  generateCode: async (signalId: number): Promise<SignalCodeResponse> => {
    const { data } = await api.post<SignalCodeResponse>(`/admin/signals/${signalId}/generate-code`);
    return data;
  },
};
