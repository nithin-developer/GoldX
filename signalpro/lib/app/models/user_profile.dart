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
  final DateTime createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final balance = json['wallet_balance'];
    final vip = json['vip_level'];

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
      hasWithdrawalPassword: (json['has_withdrawal_password'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
