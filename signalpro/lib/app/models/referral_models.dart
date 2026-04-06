class ReferralStats {
  const ReferralStats({
    required this.totalReferrals,
    required this.qualifiedReferrals,
    required this.totalBonusEarned,
    required this.inviteCode,
    required this.vipLevel,
    required this.teamProfitRatePercent,
    required this.nextVipLevel,
    required this.nextVipReferralTarget,
    required this.referralsNeededForNextVip,
    required this.minimumReferralDeposit,
  });

  final int totalReferrals;
  final int qualifiedReferrals;
  final double totalBonusEarned;
  final String? inviteCode;
  final int vipLevel;
  final double teamProfitRatePercent;
  final int? nextVipLevel;
  final int? nextVipReferralTarget;
  final int referralsNeededForNextVip;
  final double minimumReferralDeposit;

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    final total = json['total_referrals'];
    final qualified = json['qualified_referrals'];
    final bonus = json['total_bonus_earned'];
    final vipLevel = json['vip_level'];
    final teamProfitRate = json['team_profit_rate_percent'];
    final nextVipLevel = json['next_vip_level'];
    final nextVipTarget = json['next_vip_referral_target'];
    final referralsNeeded = json['referrals_needed_for_next_vip'];
    final minimumDeposit = json['minimum_referral_deposit'];

    return ReferralStats(
      totalReferrals: int.tryParse(total.toString()) ?? 0,
      qualifiedReferrals: int.tryParse(qualified.toString()) ?? 0,
      totalBonusEarned: double.tryParse(bonus.toString()) ?? 0,
      inviteCode: json['invite_code'] as String?,
      vipLevel: int.tryParse(vipLevel.toString()) ?? 0,
      teamProfitRatePercent: double.tryParse(teamProfitRate.toString()) ?? 0,
      nextVipLevel: nextVipLevel == null
          ? null
          : int.tryParse(nextVipLevel.toString()),
      nextVipReferralTarget: nextVipTarget == null
          ? null
          : int.tryParse(nextVipTarget.toString()),
      referralsNeededForNextVip: int.tryParse(referralsNeeded.toString()) ?? 0,
      minimumReferralDeposit: double.tryParse(minimumDeposit.toString()) ?? 500,
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
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
