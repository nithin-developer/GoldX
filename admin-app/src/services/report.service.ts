import api from './api';

// ----------------------------------------------------------------------

export type ReportData = {
  total_users: number;
  total_deposits: number;
  active_signals: number;
  vip_users: number;
  daily_profit: number;
  revenue?: number;
  withdrawals?: number;
};

export const reportService = {
  getReports: async (): Promise<ReportData> => {
    const { data } = await api.get<ReportData>('/admin/reports');
    return data;
  },
};
