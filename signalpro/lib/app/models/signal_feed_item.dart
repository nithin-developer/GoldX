class SignalFeedItem {
  const SignalFeedItem({
    required this.id,
    required this.asset,
    required this.direction,
    required this.profitPercent,
    required this.durationHours,
    required this.status,
    required this.vipOnly,
    required this.createdAt,
  });

  final String id;
  final String asset;
  final String direction;
  final double profitPercent;
  final int durationHours;
  final String status;
  final bool vipOnly;
  final DateTime createdAt;

  bool get isLive => status.toLowerCase() == 'active' && !hasExpired();

  DateTime get expiresAt {
    final safeDuration = durationHours > 0 ? durationHours : 0;
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

  String get durationLabel => '${durationHours}h';

  factory SignalFeedItem.fromJson(Map<String, dynamic> json) {
    final profit = json['profit_percent'];
    final duration = json['duration_hours'];

    return SignalFeedItem(
      id: (json['id'] as String? ?? '').trim(),
      asset: (json['asset'] as String? ?? '--').toUpperCase(),
      direction: (json['direction'] as String? ?? '--'),
      profitPercent: double.tryParse(profit.toString()) ?? 0,
      durationHours: int.tryParse(duration.toString()) ?? 0,
      status: (json['status'] as String? ?? 'unknown'),
      vipOnly: json['vip_only'] == true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
