class SignalItem {
  const SignalItem({
    required this.asset,
    required this.direction,
    required this.participation,
    required this.duration,
    required this.live,
  });

  final String asset;
  final String direction;
  final double participation;
  final String duration;
  final bool live;
}
