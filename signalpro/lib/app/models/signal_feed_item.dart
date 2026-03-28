class SignalFeedItem {
  const SignalFeedItem({
    required this.id,
    required this.asset,
    required this.direction,
    required this.profitPercent,
    required this.durationHours,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String asset;
  final String direction;
  final double profitPercent;
  final int durationHours;
  final String status;
  final DateTime createdAt;

  bool get isLive => status.toLowerCase() == 'active';

  String get durationLabel => '${durationHours}h';

  factory SignalFeedItem.fromJson(Map<String, dynamic> json) {
    final profit = json['profit_percent'];
    final duration = json['duration_hours'];

    return SignalFeedItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      asset: (json['asset'] as String? ?? '--').toUpperCase(),
      direction: (json['direction'] as String? ?? '--'),
      profitPercent: double.tryParse(profit.toString()) ?? 0,
      durationHours: int.tryParse(duration.toString()) ?? 0,
      status: (json['status'] as String? ?? 'unknown'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
