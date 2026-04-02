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
    required this.todayProfit,
    required this.totalProfit,
    required this.activeSignals,
    required this.vipLevel,
    required this.totalReferrals,
    required this.announcements,
    required this.recentActivities,
  });

  final double balance;
  final double todayProfit;
  final double totalProfit;
  final int activeSignals;
  final int vipLevel;
  final int totalReferrals;
  final List<HomeAnnouncement> announcements;
  final List<HomeRecentActivity> recentActivities;

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    final announcementsRaw = json['announcements'];
    final activitiesRaw = json['recent_activities'];

    return HomeDashboardData(
      balance: _toDouble(json['balance']),
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
      recentActivities: activitiesRaw is List
          ? activitiesRaw
                .whereType<Map<String, dynamic>>()
                .map(HomeRecentActivity.fromJson)
                .toList()
          : const <HomeRecentActivity>[],
    );
  }
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
