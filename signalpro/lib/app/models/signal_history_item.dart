import 'package:signalpro/app/models/signal_feed_item.dart';

class SignalHistoryItem {
  const SignalHistoryItem({
    required this.id,
    required this.userId,
    required this.signalId,
    required this.entryBalance,
    required this.participationAmount,
    required this.profitPercent,
    required this.profitAmount,
    required this.status,
    required this.startedAt,
    required this.endsAt,
    this.completedAt,
    this.signal,
  });

  final int id;
  final int userId;
  final String signalId;
  final double entryBalance;
  final double participationAmount;
  final double profitPercent;
  final double profitAmount;
  final String status;
  final DateTime startedAt;
  final DateTime endsAt;
  final DateTime? completedAt;
  final SignalFeedItem? signal;

  bool get isActive => status.toLowerCase() == 'active';

  bool get isExpired => status.toLowerCase() == 'expired';

  bool get isCompleted => status.toLowerCase() == 'completed';

  String get asset => signal?.asset ?? 'UNKNOWN';

  String get direction => signal?.direction ?? '--';

  String get durationLabel {
    final signalItem = signal;
    if (signalItem != null) {
      return signalItem.durationLabel;
    }

    final hours = endsAt.difference(startedAt).inHours;
    return '${hours > 0 ? hours : 0}h';
  }

  DateTime get displayTime => completedAt ?? endsAt;

  factory SignalHistoryItem.fromJson(Map<String, dynamic> json) {
    final nestedSignal = json['signal'];

    return SignalHistoryItem(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      signalId: (json['signal_id'] as String? ?? '').trim(),
      entryBalance: _toDouble(json['entry_balance']),
      participationAmount: _toDouble(json['participation_amount']),
      profitPercent: _toDouble(json['profit_percent']),
      profitAmount: _toDouble(json['profit_amount']),
      status: (json['status'] as String? ?? 'unknown').trim(),
      startedAt:
          DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      endsAt:
          DateTime.tryParse(json['ends_at'] as String? ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(json['completed_at'] as String? ?? ''),
      signal: nestedSignal is Map<String, dynamic>
          ? SignalFeedItem.fromJson(nestedSignal)
          : null,
    );
  }

  static int _toInt(dynamic value) {
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value.toString()) ?? 0;
  }
}
