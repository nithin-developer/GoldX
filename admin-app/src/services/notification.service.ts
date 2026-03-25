import api from './api';

// ----------------------------------------------------------------------

export type SendNotificationPayload = {
  title: string;
  message: string;
  target?: string; // 'all' or specific user_id
};

export type AnnouncementPayload = {
  title: string;
  content: string;
  duration_hours: number;
};

export type AnnouncementData = {
  id: number;
  title: string;
  content: string;
  duration_hours: number;
  created_at: string;
  expires_at: string;
};

export const notificationService = {
  sendNotification: async (payload: SendNotificationPayload): Promise<void> => {
    await api.post('/admin/notifications', payload);
  },

  createAnnouncement: async (payload: AnnouncementPayload): Promise<AnnouncementData> => {
    const { data } = await api.post<AnnouncementData>('/admin/announcements', payload);
    return data;
  },

  getAnnouncements: async (): Promise<AnnouncementData[]> => {
    const { data } = await api.get<AnnouncementData[]>('/admin/announcements');
    return data;
  },
};
