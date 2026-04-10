class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.inviteCode,
    required this.walletBalance,
    required this.vipLevel,
    required this.hasWithdrawalPassword,
    required this.verificationStatus,
    required this.verificationSubmittedAt,
    required this.verificationReviewedAt,
    required this.verificationRejectionReason,
    required this.verificationIdDocumentUrl,
    required this.verificationSelfieDocumentUrl,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String? fullName;
  final String? phone;
  final String role;
  final bool isActive;
  final String? inviteCode;
  final double walletBalance;
  final int vipLevel;
  final bool hasWithdrawalPassword;
  final String verificationStatus;
  final DateTime? verificationSubmittedAt;
  final DateTime? verificationReviewedAt;
  final String? verificationRejectionReason;
  final String? verificationIdDocumentUrl;
  final String? verificationSelfieDocumentUrl;
  final DateTime createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final balance = json['wallet_balance'];
    final vip = json['vip_level'];
    final rawVerificationStatus = (json['verification_status'] as String?)
        ?.trim()
        .toLowerCase();
    final verificationStatus =
        rawVerificationStatus == null || rawVerificationStatus.isEmpty
        ? 'not_submitted'
        : rawVerificationStatus;

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) {
        return null;
      }

      final parsed = DateTime.tryParse(value.toString());
      return parsed;
    }

    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      inviteCode: json['invite_code'] as String?,
      walletBalance: double.tryParse(balance.toString()) ?? 0,
      vipLevel: int.tryParse(vip.toString()) ?? 0,
      hasWithdrawalPassword:
          (json['has_withdrawal_password'] as bool?) ?? false,
      verificationStatus: verificationStatus,
      verificationSubmittedAt: parseNullableDate(
        json['verification_submitted_at'],
      ),
      verificationReviewedAt: parseNullableDate(
        json['verification_reviewed_at'],
      ),
      verificationRejectionReason:
          json['verification_rejection_reason'] as String?,
      verificationIdDocumentUrl:
          json['verification_id_document_url'] as String?,
      verificationSelfieDocumentUrl:
          (json['verification_selfie_document_url'] ??
                  json['verification_address_document_url'])
              as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
