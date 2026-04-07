class SignalFeedItem {
  const SignalFeedItem({
    required this.id,
    required this.asset,
    required this.direction,
    required this.profitPercent,
    required this.durationHours,
    required this.durationUnit,
    required this.status,
    required this.vipOnly,
    required this.createdAt,
    required this.alreadyActivated,
    required this.activatedUsersCount,
  });

  final String id;
  final String asset;
  final String direction;
  final double profitPercent;
  final int durationHours;
  final String durationUnit;
  final String status;
  final bool vipOnly;
  final DateTime createdAt;
  final bool alreadyActivated;
  final int activatedUsersCount;

  bool get isLive => status.toLowerCase() == 'active' && !hasExpired();

  DateTime get expiresAt {
    final safeDuration = durationHours > 0 ? durationHours : 0;
    if (durationUnit.toLowerCase() == 'minutes') {
      return createdAt.add(Duration(minutes: safeDuration));
    }
    return createdAt.add(Duration(hours: safeDuration));
  }

  bool hasExpired({DateTime? at}) {
    if (status.toLowerCase() == 'expired') {
      return true;
    }

    if (durationHours <= 0) {
      return false;
    }

    final referenceTime = at ?? DateTime.now();
    return !referenceTime.isBefore(expiresAt);
  }

  String get durationLabel {
    if (durationUnit.toLowerCase() == 'minutes') {
      return '${durationHours}m';
    }
    return '${durationHours}h';
  }

  factory SignalFeedItem.fromJson(Map<String, dynamic> json) {
    final profit = json['profit_percent'];
    final duration = json['duration_hours'];

    return SignalFeedItem(
      id: (json['id'] as String? ?? '').trim(),
      asset: (json['asset'] as String? ?? '--').toUpperCase(),
      direction: (json['direction'] as String? ?? '--'),
      profitPercent: double.tryParse(profit.toString()) ?? 0,
      durationHours: int.tryParse(duration.toString()) ?? 0,
      durationUnit: (json['duration_unit'] as String? ?? 'hours')
          .trim()
          .toLowerCase(),
      status: (json['status'] as String? ?? 'unknown'),
      vipOnly: json['vip_only'] == true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      alreadyActivated: json['already_activated'] == true,
      activatedUsersCount:
          int.tryParse((json['activated_users_count'] ?? 0).toString()) ?? 0,
    );
  }
}
