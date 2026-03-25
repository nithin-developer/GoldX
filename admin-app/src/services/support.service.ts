import api from './api';

// ----------------------------------------------------------------------

export type SupportMessage = {
  id: number;
  message: string;
  sender: 'user' | 'admin';
  created_at: string;
};

export type SupportChat = {
  id: number;
  user_email: string;
  user_id: number;
  messages: SupportMessage[];
  updated_at: string;
};

export type ReplyPayload = {
  chat_id: number;
  message: string;
};

export const supportService = {
  getChats: async (): Promise<SupportChat[]> => {
    const { data } = await api.get<SupportChat[]>('/admin/support');
    return data;
  },

  replyToChat: async (payload: ReplyPayload): Promise<void> => {
    await api.post('/admin/support/reply', payload);
  },
};
