import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/models/home_dashboard.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/skeleton_box.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onDeposit,
    required this.onWithdraw,
    required this.onSupport,
    super.key,
  });

  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onSupport;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<_MarketCoin> _coins = [
    _MarketCoin(
      symbol: 'BTC',
      pair: 'BTCUSDT',
      label: 'BTC / USDT',
      logoAsset: 'assets/coins/btc.png',
    ),
    _MarketCoin(
      symbol: 'ETH',
      pair: 'ETHUSDT',
      label: 'ETH / USDT',
      logoAsset: 'assets/coins/eth.png',
    ),
    _MarketCoin(
      symbol: 'SOL',
      pair: 'SOLUSDT',
      label: 'SOL / USDT',
      logoAsset: 'assets/coins/sol.png',
    ),
    _MarketCoin(
      symbol: 'AVAX',
      pair: 'AVAXUSDT',
      label: 'AVAX / USDT',
      logoAsset: 'assets/coins/avax.png',
    ),
  ];

  final NumberFormat _priceFormat = NumberFormat('#,##0.00');

  AppDataApi? _api;
  Future<HomeDashboardData>? _future;
  int? _sessionRevision;

  WebSocketChannel? _tickerChannel;
  StreamSubscription<dynamic>? _tickerSubscription;
  Timer? _reconnectTimer;

  final Map<String, double> _latestPrices = {};
  final Map<String, double> _dailyChangePercent = {};

  bool _isDisposed = false;
  bool _isActiveInTree = true;
  String? _streamError;

  String get _streamReconnectMessage =>
      context.l10n.tr('Live market feed disconnected. Reconnecting...');

  @override
  void initState() {
    super.initState();
    _connectTickerStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    final revision = auth.sessionRevision;

    if (_sessionRevision != revision) {
      _sessionRevision = revision;
      _api = AppDataApi(dio: auth.apiClient.dio);
      _future = _api!.getHomeDashboard(forceRefresh: true, activityLimit: 5);
      return;
    }

    _api ??= AppDataApi(dio: auth.apiClient.dio);
    _future ??= _api!.getHomeDashboard(activityLimit: 5);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _tickerSubscription?.cancel();
    _tickerChannel?.sink.close();
    super.dispose();
  }

  @override
  void deactivate() {
    _isActiveInTree = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isActiveInTree = true;
  }

  bool get _canMutateState => mounted && !_isDisposed && _isActiveInTree;

  Future<void> _refresh() async {
    final api = _api;
    if (api == null) {
      return;
    }

    setState(() {
      _future = api.getHomeDashboard(forceRefresh: true, activityLimit: 5);
    });

    final pending = _future;
    if (pending != null) {
      await pending;
    }
  }

  void _connectTickerStream() {
    if (_isDisposed) {
      return;
    }

    _reconnectTimer?.cancel();
    _tickerSubscription?.cancel();
    _tickerChannel?.sink.close();

    final streams = _coins
        .map((coin) => '${coin.pair.toLowerCase()}@kline_1d')
        .join('/');

    _tickerChannel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/stream?streams=$streams'),
    );

    _tickerSubscription = _tickerChannel!.stream.listen(
      (message) {
        final parsed = jsonDecode(message as String);
        final data = parsed['data'];

        if (data is! Map<String, dynamic>) {
          return;
        }

        final kline = data['k'];
        if (kline is! Map<String, dynamic>) {
          return;
        }

        final pair = kline['s']?.toString();
        final openPrice = double.tryParse(kline['o'].toString());
        final closePrice = double.tryParse(kline['c'].toString());

        if (pair == null ||
            openPrice == null ||
            openPrice <= 0 ||
            closePrice == null ||
            !_canMutateState) {
          return;
        }

        final dayPercent = ((closePrice - openPrice) / openPrice) * 100;

        setState(() {
          _latestPrices[pair] = closePrice;
          _dailyChangePercent[pair] = dayPercent;
          _streamError = null;
        });
      },
      onError: (_) {
        if (!_canMutateState) {
          return;
        }

        setState(() {
          _streamError = _streamReconnectMessage;
        });

        _scheduleReconnect();
      },
      onDone: () {
        if (!_canMutateState) {
          return;
        }

        setState(() {
          _streamError = _streamReconnectMessage;
        });

        _scheduleReconnect();
      },
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_isDisposed) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_canMutateState) {
        return;
      }
      _connectTickerStream();
    });
  }

  String _formatPrice(double? price) {
    if (price == null) {
      return '\$ --';
    }
    return '\$${_priceFormat.format(price)}';
  }

  String _buildAlertText(
    List<HomeAnnouncement> announcements,
    List<String> activeSignalAlerts,
    AppLocalizations l10n,
  ) {
    final announcementSegments = announcements
        .map((item) {
          final title = item.title.trim();
          final message = item.message.trim();
          if (title.isNotEmpty && message.isNotEmpty) {
            return '$title: $message';
          }
          if (message.isNotEmpty) {
            return message;
          }
          return title;
        })
        .where((item) => item.isNotEmpty)
        .take(4)
        .toList();

    final signalSegments = activeSignalAlerts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(4)
        .toList();

    final allSegments = <String>[...announcementSegments, ...signalSegments];

    if (allSegments.isEmpty) {
      return l10n.tr(
        'Market Alert: BTC above \$72k | New ETH signals live | Refer and earn rewards',
      );
    }

    return allSegments.join('  |  ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<HomeDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _api?.getCachedHomeDashboard();

        if (snapshot.connectionState == ConnectionState.waiting &&
            data == null) {
          return _HomeLoadingView(
            onDeposit: widget.onDeposit,
            onWithdraw: widget.onWithdraw,
            onSupport: widget.onSupport,
          );
        }

        if (snapshot.hasError && data == null) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : l10n.tr('Unable to load dashboard data.');
          return _HomeErrorState(message: message, onRetry: _refresh);
        }

        if (data == null) {
          return _HomeErrorState(
            message: l10n.tr('Dashboard data is unavailable.'),
            onRetry: _refresh,
          );
        }

        final activities = data.recentActivities.take(5).toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background,
                  AppColors.accent,
                  AppColors.backgroundSecondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _MarketAlertBanner(
                  text: _buildAlertText(
                    data.announcements,
                    data.activeSignalAlerts,
                    l10n,
                  ),
                ),
                const SizedBox(height: 16),
                _BalanceHeroCard(data: data),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.south_west_rounded,
                        label: l10n.tr('Deposit'),
                        iconColor: AppColors.secondary,
                        onTap: widget.onDeposit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.north_east_rounded,
                        label: l10n.tr('Withdraw'),
                        iconColor: AppColors.highlight,
                        onTap: widget.onWithdraw,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.support_agent_rounded,
                        label: l10n.tr('Support'),
                        iconColor: AppColors.secondary,
                        onTap: widget.onSupport,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(
                  title: l10n.tr('Market Snapshot'),
                  actionText: l10n.tr('LIVE'),
                ),
                const SizedBox(height: 10),
                _SnapshotScroller(
                  coins: _coins,
                  latestPrices: _latestPrices,
                  dailyChangePercent: _dailyChangePercent,
                  formatPrice: _formatPrice,
                ),
                if (_streamError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _streamError!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _SectionTitle(title: l10n.tr('Recent Activity')),
                const SizedBox(height: 10),
                _RecentActivityCard(activities: activities),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView({
    required this.onDeposit,
    required this.onWithdraw,
    required this.onSupport,
  });

  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.background,
            AppColors.accent,
            AppColors.backgroundSecondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const SkeletonBox(height: 46, radius: 14),
          const SizedBox(height: 16),
          const SkeletonBox(height: 168, radius: 24),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.south_west_rounded,
                  label: l10n.tr('Deposit'),
                  iconColor: AppColors.secondary,
                  onTap: onDeposit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.north_east_rounded,
                  label: l10n.tr('Withdraw'),
                  iconColor: AppColors.highlight,
                  onTap: onWithdraw,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.support_agent_rounded,
                  label: l10n.tr('Support'),
                  iconColor: AppColors.secondary,
                  onTap: onSupport,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: l10n.tr('Market Snapshot'),
            actionText: l10n.tr('LIVE'),
          ),
          const SizedBox(height: 10),
          const _SnapshotSkeletons(),
          const SizedBox(height: 20),
          _SectionTitle(title: l10n.tr('Recent Activity')),
          const SizedBox(height: 10),
          const SkeletonBox(height: 210, radius: 22),
        ],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tr('Unable to load home dashboard'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => onRetry(),
                child: Text(l10n.tr('Retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketAlertBanner extends StatelessWidget {
  const _MarketAlertBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_rounded,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MarqueeText(
              text: text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  const _MarqueeText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segment = '${widget.text}   |   ';
    final painter = TextPainter(
      text: TextSpan(text: segment, style: widget.style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final segmentWidth = painter.width;
    if (segmentWidth <= 0) {
      return Text(
        widget.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }

    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        child: Text(segment, maxLines: 1, softWrap: false, style: widget.style),
        builder: (context, child) {
          final dx = -segmentWidth * _controller.value;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Row(children: [child!, child]),
          );
        },
      ),
    );
  }
}

class _BalanceHeroCard extends StatelessWidget {
  const _BalanceHeroCard({required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balance = _MoneyFormatters.currency(data.balance);
    final withdrawable = _MoneyFormatters.currency(data.withdrawableBalance);
    final capital = _MoneyFormatters.currency(data.capitalBalance);
    final signalProfits = _MoneyFormatters.currency(data.signalProfitBalance);
    final teamRewards = _MoneyFormatters.currency(data.rewardBalance);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFE6C65C), Color(0xFFF4F1EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('TOTAL BALANCE'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        balance,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                          color: AppColors.onSurface,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                _PerformanceChip(
                  vipLevel: data.vipLevel,
                  totalReferrals: data.totalReferrals,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('WITHDRAWABLE NOW'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.secondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        withdrawable,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                _AssetCircleRow(),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BreakdownPill(
                    title: l10n.tr('Capital'),
                    value: capital,
                    icon: Icons.account_balance_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BreakdownPill(
                    title: l10n.tr('Signal Profits'),
                    value: signalProfits,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BreakdownPill(
                    title: l10n.tr('Team Rewards'),
                    value: teamRewards,
                    icon: Icons.groups_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.tr(
                        'Withdrawal Fee: 20% for capital or full balance. 10% for signal profits and team rewards only.',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceChip extends StatelessWidget {
  const _PerformanceChip({
    required this.vipLevel,
    required this.totalReferrals,
  });

  final int vipLevel;
  final int totalReferrals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                l10n.tr(
                  'VIP {level} Level',
                  params: <String, String>{'level': vipLevel.toString()},
                ),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tr('Referrals: {count}', params: {'count': totalReferrals.toString()}),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownPill extends StatelessWidget {
  const _BreakdownPill({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetCircleRow extends StatelessWidget {
  const _AssetCircleRow();

  @override
  Widget build(BuildContext context) {
    final overlapOffset = context.l10n.isArabic
        ? 8.0
        : -8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AssetCircle(icon: Icons.currency_bitcoin_rounded),
        Transform.translate(
          offset: Offset(overlapOffset, 0),
          child: const _AssetCircle(icon: Icons.eco_rounded),
        ),
      ], 
    );
  }
}

class _AssetCircle extends StatelessWidget {
  const _AssetCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderRadius: 16,
      borderColor: AppColors.outlineVariant,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionText});

  final String title;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.onSurface,
            ),
          ),
        ),
        if (actionText != null)
          Text(
            actionText!,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.secondary,
            ),
          ),
      ],
    );
  }
}

class _SnapshotSkeletons extends StatelessWidget {
  const _SnapshotSkeletons();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 146,
            child: SkeletonBox(height: 112, radius: 14),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemCount: 4,
      ),
    );
  }
}

class _SnapshotScroller extends StatelessWidget {
  const _SnapshotScroller({
    required this.coins,
    required this.latestPrices,
    required this.dailyChangePercent,
    required this.formatPrice,
  });

  final List<_MarketCoin> coins;
  final Map<String, double> latestPrices;
  final Map<String, double> dailyChangePercent;
  final String Function(double? price) formatPrice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: coins.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final coin = coins[index];
          final price = latestPrices[coin.pair];
          final change = dailyChangePercent[coin.pair];

          return _SnapshotAssetCard(
            asset: l10n.tr(coin.label),
            logoAsset: coin.logoAsset,
            price: formatPrice(price),
            gain: _MoneyFormatters.percent(change),
            positive: change == null ? null : change >= 0,
          );
        },
      ),
    );
  }
}

class _SnapshotAssetCard extends StatelessWidget {
  const _SnapshotAssetCard({
    required this.asset,
    required this.logoAsset,
    required this.price,
    required this.gain,
    required this.positive,
  });

  final String asset;
  final String logoAsset;
  final String price;
  final String gain;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: GlassCard(
        borderRadius: 16,
        borderColor: AppColors.outlineVariant,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoinAvatar(logoAsset: logoAsset, size: 30),
                const SizedBox(height: 10),
                Text(
                  asset,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  gain,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: positive == true
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinAvatar extends StatelessWidget {
  const _CoinAvatar({required this.logoAsset, required this.size});

  final String logoAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        logoAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.token_rounded,
            size: size * 0.55,
            color: AppColors.textMuted,
          );
        },
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.activities});

  final List<HomeRecentActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      final l10n = context.l10n;

      return GlassCard(
        borderRadius: 22,
        borderColor: AppColors.outlineVariant,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.tr(
              'No recent activity yet. Your latest deposits, withdrawals, signals, and referrals will appear here.',
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return GlassCard(
      borderRadius: 22,
      borderColor: AppColors.outlineVariant,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < activities.length; i++) ...[
            _ActivityRow(activity: activities[i]),
            if (i != activities.length - 1)
              const Divider(height: 1, color: AppColors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final HomeRecentActivity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visual = _ActivityVisual.forType(activity.type);
    final title = _localizedTitle(l10n);
    final subtitle = _localizedSubtitle(l10n);
    final tag = _localizedTag(l10n);
    final valueText = _MoneyFormatters.activityAmount(
      activity.amount,
      activity.isPositive,
    );
    final valueColor = activity.isPositive == true
        ? AppColors.secondary
        : (activity.isPositive == false
              ? AppColors.danger
              : AppColors.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(visual.icon, size: 22, color: visual.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle?.trim().isNotEmpty == true
                      ? subtitle!
                      : _MoneyFormatters.activityTime(activity.createdAt, l10n),
                  style: const TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valueText,
                style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tag,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _localizedTitle(AppLocalizations l10n) {
    switch (activity.type) {
      case 'deposit_requested':
        return l10n.tr('Deposit Request Submitted');
      case 'deposit_approved':
        return l10n.tr('Deposit Approved');
      case 'deposit_rejected':
        return l10n.tr('Deposit Rejected');
      case 'withdrawal_requested':
        return l10n.tr('Withdrawal Request Submitted');
      case 'withdrawal_approved':
        return l10n.tr('Withdrawal Approved');
      case 'withdrawal_rejected':
        return l10n.tr('Withdrawal Rejected');
      case 'signal_activated':
        final asset = _extractSuffixAfterColon(activity.title);
        return l10n.tr(
          'Signal Activated: {asset}',
          params: <String, String>{'asset': asset.isNotEmpty ? asset : 'SIGNAL'},
        );
      case 'referral_rewarded':
        final user = _localizedUserLabel(_extractSuffixAfterColon(activity.title), l10n);
        return l10n.tr(
          'Referral Rewarded: {user}',
          params: <String, String>{'user': user},
        );
      case 'referral_qualified':
        final user = _localizedUserLabel(_extractSuffixAfterColon(activity.title), l10n);
        return l10n.tr(
          'Referral Qualified: {user}',
          params: <String, String>{'user': user},
        );
      case 'referral_joined':
        final user = _localizedUserLabel(_extractSuffixAfterColon(activity.title), l10n);
        return l10n.tr(
          'Referral Joined: {user}',
          params: <String, String>{'user': user},
        );
      default:
        return l10n.tr(activity.title);
    }
  }

  String? _localizedSubtitle(AppLocalizations l10n) {
    final subtitle = activity.subtitle?.trim();
    if (subtitle == null || subtitle.isEmpty) {
      return null;
    }

    switch (activity.type) {
      case 'deposit_requested':
        final ref = _extractValueAfterPrefix(subtitle, 'Reference:');
        if (ref != null) {
          return l10n.tr(
            'Reference: {value}',
            params: <String, String>{'value': ref},
          );
        }
        if (_matchesExact(subtitle, 'Awaiting admin review')) {
          return l10n.tr('Awaiting admin review');
        }
        return subtitle;
      case 'deposit_approved':
        if (_matchesExact(subtitle, 'Funds were credited to your wallet')) {
          return l10n.tr('Funds were credited to your wallet');
        }
        return subtitle;
      case 'deposit_rejected':
        if (_matchesExact(subtitle, 'Request was rejected by admin')) {
          return l10n.tr('Request was rejected by admin');
        }
        return subtitle;
      case 'withdrawal_requested':
        final destination = _extractValueAfterPrefix(subtitle, 'Destination:');
        if (destination != null) {
          return l10n.tr(
            'Destination: {value}',
            params: <String, String>{'value': destination},
          );
        }
        if (_matchesExact(subtitle, 'Awaiting admin approval')) {
          return l10n.tr('Awaiting admin approval');
        }
        return subtitle;
      case 'withdrawal_approved':
        if (_matchesExact(subtitle, 'Funds were debited from your wallet')) {
          return l10n.tr('Funds were debited from your wallet');
        }
        return subtitle;
      case 'withdrawal_rejected':
        if (_matchesExact(subtitle, 'Request was rejected by admin')) {
          return l10n.tr('Request was rejected by admin');
        }
        return subtitle;
      case 'signal_activated':
        final percent = _extractPercentValue(subtitle);
        if (percent != null) {
          return l10n.tr(
            'Target +{percent}% before expiry',
            params: <String, String>{'percent': percent},
          );
        }
        return subtitle;
      case 'referral_rewarded':
        if (_matchesExact(subtitle, 'Referral bonus has been credited')) {
          return l10n.tr('Referral bonus has been credited');
        }
        return subtitle;
      case 'referral_qualified':
        if (_matchesExact(subtitle, 'Deposit requirement completed')) {
          return l10n.tr('Deposit requirement completed');
        }
        return subtitle;
      case 'referral_joined':
        if (_matchesExact(subtitle, 'Awaiting qualifying deposit')) {
          return l10n.tr('Awaiting qualifying deposit');
        }
        return subtitle;
      default:
        return l10n.tr(subtitle);
    }
  }

  String _localizedTag(AppLocalizations l10n) {
    switch (activity.type) {
      case 'deposit_requested':
        return l10n.tr('DEPOSIT');
      case 'deposit_approved':
        return l10n.tr('Approved');
      case 'deposit_rejected':
        return l10n.tr('Rejected');
      case 'withdrawal_requested':
        return l10n.tr('WITHDRAW');
      case 'withdrawal_approved':
        return l10n.tr('Approved');
      case 'withdrawal_rejected':
        return l10n.tr('Rejected');
      case 'signal_activated':
        return l10n.tr('SIGNAL');
      case 'referral_rewarded':
        return l10n.tr('REWARD');
      case 'referral_qualified':
        return l10n.tr('QUALIFIED');
      case 'referral_joined':
        return l10n.tr('REFERRAL');
      default:
        return l10n.tr(activity.tag);
    }
  }

  String _extractSuffixAfterColon(String value) {
    final index = value.indexOf(':');
    if (index < 0 || index >= value.length - 1) {
      return '';
    }
    return value.substring(index + 1).trim();
  }

  String? _extractValueAfterPrefix(String value, String prefix) {
    if (!value.startsWith(prefix)) {
      return null;
    }

    final extracted = value.substring(prefix.length).trim();
    if (extracted.isEmpty) {
      return null;
    }

    return extracted;
  }

  String _localizedUserLabel(String raw, AppLocalizations l10n) {
    if (raw.isEmpty) {
      return l10n.tr('Not available');
    }

    final userMatch = RegExp(
      r'^User\s*#\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (userMatch == null) {
      return raw;
    }

    return l10n.tr(
      'User #{id}',
      params: <String, String>{'id': userMatch.group(1)!},
    );
  }

  String? _extractPercentValue(String value) {
    final match = RegExp(r'([+-]?\d+(?:\.\d+)?)\s*%').firstMatch(value);
    if (match == null) {
      return null;
    }

    final parsed = double.tryParse(match.group(1)!);
    if (parsed == null) {
      return match.group(1);
    }

    final fixed = parsed.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  bool _matchesExact(String value, String expected) {
    return value.trim().toLowerCase() == expected.toLowerCase();
  }
}

class _ActivityVisual {
  const _ActivityVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static _ActivityVisual forType(String type) {
    switch (type) {
      case 'deposit_requested':
        return const _ActivityVisual(
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.highlight,
        );
      case 'deposit_approved':
        return const _ActivityVisual(
          icon: Icons.check_circle_rounded,
          color: AppColors.secondary,
        );
      case 'deposit_rejected':
        return const _ActivityVisual(
          icon: Icons.cancel_rounded,
          color: AppColors.danger,
        );
      case 'withdrawal_requested':
        return const _ActivityVisual(
          icon: Icons.outbox_rounded,
          color: AppColors.highlight,
        );
      case 'withdrawal_approved':
        return const _ActivityVisual(
          icon: Icons.task_alt_rounded,
          color: AppColors.danger,
        );
      case 'withdrawal_rejected':
        return const _ActivityVisual(
          icon: Icons.block_rounded,
          color: AppColors.danger,
        );
      case 'signal_activated':
        return const _ActivityVisual(
          icon: Icons.bolt_rounded,
          color: AppColors.secondary,
        );
      case 'referral_rewarded':
        return const _ActivityVisual(
          icon: Icons.workspace_premium_rounded,
          color: AppColors.secondary,
        );
      case 'referral_qualified':
        return const _ActivityVisual(
          icon: Icons.verified_rounded,
          color: AppColors.secondary,
        );
      default:
        return const _ActivityVisual(
          icon: Icons.groups_rounded,
          color: AppColors.highlight,
        );
    }
  }
}

class _MarketCoin {
  const _MarketCoin({
    required this.symbol,
    required this.pair,
    required this.label,
    required this.logoAsset,
  });

  final String symbol;
  final String pair;
  final String label;
  final String logoAsset;
}

class _MoneyFormatters {
  static final NumberFormat _amountFormat = NumberFormat('#,##0.00');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM, hh:mm a');

  static String currency(double value) => '\$${_amountFormat.format(value)}';

  static String percent(double? value) {
    if (value == null) {
      return '--';
    }

    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String activityAmount(double? amount, bool? isPositive) {
    if (amount == null) {
      return '--';
    }

    final normalized = '\$${_amountFormat.format(amount.abs())}';
    if (isPositive == true) {
      return '+$normalized';
    }
    if (isPositive == false) {
      return '-$normalized';
    }
    return normalized;
  }

  static String activityTime(DateTime createdAt, AppLocalizations l10n) {
    final local = createdAt.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    if (isToday) {
      return l10n.tr(
        'Today, {time}',
        params: <String, String>{'time': _timeFormat.format(local)},
      );
    }

    return _dateTimeFormat.format(local);
  }
}
