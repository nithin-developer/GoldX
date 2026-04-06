class HomeAnnouncement {
  const HomeAnnouncement({
    required this.id,
    required this.title,
    required this.message,
  });

  final int id;
  final String title;
  final String message;

  factory HomeAnnouncement.fromJson(Map<String, dynamic> json) {
    return HomeAnnouncement(
      id: _toInt(json['id']),
      title: (json['title'] as String? ?? '').trim(),
      message: (json['message'] as String? ?? '').trim(),
    );
  }
}

class HomeRecentActivity {
  const HomeRecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.tag,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? subtitle;
  final double? amount;
  final bool? isPositive;
  final String tag;
  final DateTime createdAt;

  factory HomeRecentActivity.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'] as String?;

    return HomeRecentActivity(
      id: (json['id'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      subtitle: (json['subtitle'] as String?)?.trim(),
      amount: _toNullableDouble(json['amount']),
      isPositive: json['is_positive'] as bool?,
      tag: (json['tag'] as String? ?? '').trim(),
      createdAt: createdAtRaw == null || createdAtRaw.isEmpty
          ? DateTime.now()
          : DateTime.parse(createdAtRaw),
    );
  }
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.balance,
    required this.capitalBalance,
    required this.signalProfitBalance,
    required this.rewardBalance,
    required this.withdrawableBalance,
    required this.lockedCapitalBalance,
    required this.capitalLockActive,
    required this.capitalLockEndsAt,
    required this.capitalLockDaysRemaining,
    required this.todayProfit,
    required this.totalProfit,
    required this.activeSignals,
    required this.vipLevel,
    required this.totalReferrals,
    required this.announcements,
    required this.activeSignalAlerts,
    required this.recentActivities,
  });

  final double balance;
  final double capitalBalance;
  final double signalProfitBalance;
  final double rewardBalance;
  final double withdrawableBalance;
  final double lockedCapitalBalance;
  final bool capitalLockActive;
  final DateTime? capitalLockEndsAt;
  final int capitalLockDaysRemaining;
  final double todayProfit;
  final double totalProfit;
  final int activeSignals;
  final int vipLevel;
  final int totalReferrals;
  final List<HomeAnnouncement> announcements;
  final List<String> activeSignalAlerts;
  final List<HomeRecentActivity> recentActivities;

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    final announcementsRaw = json['announcements'];
    final activeSignalAlertsRaw = json['active_signal_alerts'];
    final activitiesRaw = json['recent_activities'];

    return HomeDashboardData(
      balance: _toDouble(json['balance']),
      capitalBalance: _toDouble(json['capital_balance']),
      signalProfitBalance: _toDouble(json['signal_profit_balance']),
      rewardBalance: _toDouble(json['reward_balance']),
      withdrawableBalance: _toDouble(json['withdrawable_balance']),
      lockedCapitalBalance: _toDouble(json['locked_capital_balance']),
      capitalLockActive: json['capital_lock_active'] == true,
      capitalLockEndsAt: _toNullableDateTime(json['capital_lock_ends_at']),
      capitalLockDaysRemaining: _toInt(json['capital_lock_days_remaining']),
      todayProfit: _toDouble(json['today_profit']),
      totalProfit: _toDouble(json['total_profit']),
      activeSignals: _toInt(json['active_signals']),
      vipLevel: _toInt(json['vip_level']),
      totalReferrals: _toInt(json['total_referrals']),
      announcements: announcementsRaw is List
          ? announcementsRaw
                .whereType<Map<String, dynamic>>()
                .map(HomeAnnouncement.fromJson)
                .toList()
          : const <HomeAnnouncement>[],
      activeSignalAlerts: activeSignalAlertsRaw is List
          ? activeSignalAlertsRaw
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const <String>[],
      recentActivities: activitiesRaw is List
          ? activitiesRaw
                .whereType<Map<String, dynamic>>()
                .map(HomeRecentActivity.fromJson)
                .toList()
          : const <HomeRecentActivity>[],
    );
  }
}

DateTime? _toNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  final parsed = DateTime.tryParse(value.toString());
  return parsed;
}

double _toDouble(dynamic value) {
  return double.tryParse(value.toString()) ?? 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  return double.tryParse(value.toString());
}

int _toInt(dynamic value) {
  return int.tryParse(value.toString()) ?? 0;
}
