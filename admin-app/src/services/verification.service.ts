import api, { type PaginatedResponse } from './api';

// ----------------------------------------------------------------------

export type VerificationStatus =
  | 'not_submitted'
  | 'pending'
  | 'approved'
  | 'rejected';

export type VerificationItem = {
  verification_id: number;
  user_id: number;
  user_email: string;
  user_full_name?: string | null;
  status: VerificationStatus;
  id_document_url?: string | null;
  selfie_document_url?: string | null;
  address_document_url?: string | null;
  submitted_at?: string | null;
  reviewed_at?: string | null;
  reviewed_by_admin_id?: number | null;
  rejection_reason?: string | null;
  created_at: string;
  updated_at: string;
};

export type GetVerificationsParams = {
  status?: VerificationStatus | 'all';
  skip?: number;
  limit?: number;
};

export const verificationService = {
  getVerifications: async (
    params?: GetVerificationsParams
  ): Promise<PaginatedResponse<VerificationItem>> => {
    const { data } = await api.get<PaginatedResponse<VerificationItem>>('/admin/verifications', {
      params: {
        status: params?.status,
        skip: params?.skip,
        limit: params?.limit,
      },
    });

    return data;
  },

  approveVerification: async (userId: number): Promise<VerificationItem> => {
    const { data } = await api.put<VerificationItem>(`/admin/verifications/${userId}/approve`, {});
    return data;
  },

  rejectVerification: async (
    userId: number,
    rejectionReason: string
  ): Promise<VerificationItem> => {
    const { data } = await api.put<VerificationItem>(`/admin/verifications/${userId}/reject`, {
      rejection_reason: rejectionReason,
    });
    return data;
  },
};
