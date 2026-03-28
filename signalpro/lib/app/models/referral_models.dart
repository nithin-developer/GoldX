class ReferralStats {
  const ReferralStats({
    required this.totalReferrals,
    required this.qualifiedReferrals,
    required this.totalBonusEarned,
    required this.inviteCode,
  });

  final int totalReferrals;
  final int qualifiedReferrals;
  final double totalBonusEarned;
  final String? inviteCode;

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    final total = json['total_referrals'];
    final qualified = json['qualified_referrals'];
    final bonus = json['total_bonus_earned'];

    return ReferralStats(
      totalReferrals: int.tryParse(total.toString()) ?? 0,
      qualifiedReferrals: int.tryParse(qualified.toString()) ?? 0,
      totalBonusEarned: double.tryParse(bonus.toString()) ?? 0,
      inviteCode: json['invite_code'] as String?,
    );
  }
}

class ReferralItem {
  const ReferralItem({
    required this.id,
    required this.referredUserId,
    required this.referredEmail,
    required this.depositAmount,
    required this.bonusAmount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int referredUserId;
  final String? referredEmail;
  final double depositAmount;
  final double bonusAmount;
  final String status;
  final DateTime createdAt;

  factory ReferralItem.fromJson(Map<String, dynamic> json) {
    final deposit = json['deposit_amount'];
    final bonus = json['bonus_amount'];

    return ReferralItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      referredUserId: (json['referred_user_id'] as num?)?.toInt() ?? 0,
      referredEmail: json['referred_email'] as String?,
      depositAmount: double.tryParse(deposit.toString()) ?? 0,
      bonusAmount: double.tryParse(bonus.toString()) ?? 0,
      status: (json['status'] as String? ?? 'pending'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
