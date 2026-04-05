import api from './api';

// ----------------------------------------------------------------------

export type NotificationData = {
  id: number;
  user_id: number;
  title: string;
  message: string;
  type: string;
  is_read: boolean;
  created_at: string;
};

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

type AnnouncementApiResponse = {
  id: number;
  title: string;
  message?: string;
  content?: string;
  duration_hours?: number | null;
  created_at: string;
  expires_at?: string | null;
  end_date?: string | null;
  start_date?: string | null;
};

function mapAnnouncement(response: AnnouncementApiResponse): AnnouncementData {
  const content = response.content ?? response.message ?? '';

  let duration = response.duration_hours ?? 24;
  if (!duration && response.start_date && response.end_date) {
    const start = new Date(response.start_date).getTime();
    const end = new Date(response.end_date).getTime();
    const diffHours = Math.round((end - start) / (1000 * 60 * 60));
    duration = Number.isFinite(diffHours) && diffHours > 0 ? diffHours : 24;
  }

  const expiresAt = response.expires_at ?? response.end_date ?? response.created_at;

  return {
    id: response.id,
    title: response.title,
    content,
    duration_hours: duration,
    created_at: response.created_at,
    expires_at: expiresAt,
  };
}

export const notificationService = {
  sendNotification: async (payload: SendNotificationPayload): Promise<void> => {
    await api.post('/admin/notifications', payload);
  },

  createAnnouncement: async (payload: AnnouncementPayload): Promise<AnnouncementData> => {
    const { data } = await api.post<AnnouncementApiResponse>('/admin/announcements', payload);
    return mapAnnouncement(data);
  },

  getAnnouncements: async (): Promise<AnnouncementData[]> => {
    const { data } = await api.get<AnnouncementApiResponse[]>('/admin/announcements');
    return (data ?? []).map(mapAnnouncement);
  },

  getNotifications: async (): Promise<NotificationData[]> => {
    const { data } = await api.get<NotificationData[]>('/admin/notifications');
    return data;
  },

  deleteNotification: async (id: number): Promise<void> => {
    await api.delete(`/admin/notifications/${id}`);
  },
};
