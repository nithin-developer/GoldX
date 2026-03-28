import 'package:flutter/material.dart';
import 'package:signalpro/app/models/signal_feed_item.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class SignalsPage extends StatefulWidget {
  const SignalsPage({required this.onFollowSignal, super.key});

  final VoidCallback onFollowSignal;

  @override
  State<SignalsPage> createState() => _SignalsPageState();
}

class _SignalsPageState extends State<SignalsPage> {
  AppDataApi? _api;
  Future<List<SignalFeedItem>>? _signalsFuture;
  List<SignalFeedItem> _cachedSignals = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = _api ?? AppDataApi(dio: AuthScope.of(context).apiClient.dio);
    _api = api;
    _cachedSignals = api.getCachedSignals() ?? const [];
    _signalsFuture ??= api.getSignals();
  }

  Future<void> _refresh() async {
    setState(() {
      _signalsFuture = _api!.getSignals(forceRefresh: true);
    });
    final pending = _signalsFuture;
    if (pending != null) {
      await pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SignalFeedItem>>(
      future: _signalsFuture,
      builder: (context, snapshot) {
        final canUseCache = _cachedSignals.isNotEmpty;

        if (snapshot.connectionState == ConnectionState.waiting) {
          if (canUseCache) {
            return _SignalsList(
              signals: _cachedSignals,
              onFollowSignal: widget.onFollowSignal,
              onRefresh: _refresh,
              showRefreshingBanner: true,
            );
          }
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Failed to load signals.';

          if (canUseCache) {
            return _SignalsList(
              signals: _cachedSignals,
              onFollowSignal: widget.onFollowSignal,
              onRefresh: _refresh,
              topMessage: 'Showing cached signals. $message',
            );
          }

          return _ErrorState(
            title: 'Unable to load signals',
            message: message,
            onRetry: () {
              _refresh();
            },
          );
        }

        final signals = snapshot.data ?? const <SignalFeedItem>[];
        _cachedSignals = signals;

        if (signals.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              children: const [
                _SignalsHeader(),
                SizedBox(height: 20),
                EmptyStateIllustration(
                  title: 'No Signals Found',
                  subtitle: 'No signal records are available in the backend database yet.',
                  icon: Icons.bolt_outlined,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16),
            itemCount: signals.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const _SignalsHeader();
              }

              final item = signals[index - 1];
              return _SignalCard(item: item, onFollowSignal: widget.onFollowSignal);
            },
          ),
        );
      },
    );
  }
}

class _SignalsList extends StatelessWidget {
  const _SignalsList({
    required this.signals,
    required this.onFollowSignal,
    required this.onRefresh,
    this.topMessage,
    this.showRefreshingBanner = false,
  });

  final List<SignalFeedItem> signals;
  final VoidCallback onFollowSignal;
  final Future<void> Function() onRefresh;
  final String? topMessage;
  final bool showRefreshingBanner;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        itemCount: signals.length + 1 + (topMessage == null && !showRefreshingBanner ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final hasBanner = topMessage != null || showRefreshingBanner;

          if (index == 0) {
            return const _SignalsHeader();
          }

          if (hasBanner && index == 1) {
            return _InlineNotice(
              message: topMessage ?? 'Refreshing from backend...',
              isError: topMessage != null,
            );
          }

          final signalIndex = index - 1 - (hasBanner ? 1 : 0);
          final item = signals[signalIndex];
          return _SignalCard(item: item, onFollowSignal: onFollowSignal);
        },
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.danger.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.danger : AppColors.primary,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.info_outline_rounded : Icons.sync_rounded,
            size: 16,
            color: isError ? AppColors.danger : AppColors.primaryBright,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalsHeader extends StatelessWidget {
  const _SignalsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE FEED',
                style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.textSecondary),
              ),
              SizedBox(height: 3),
              Text('Active Signals', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_done_outlined, size: 18),
              SizedBox(width: 4),
              Text('Live API'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.item, required this.onFollowSignal});

  final SignalFeedItem item;
  final VoidCallback onFollowSignal;

  @override
  Widget build(BuildContext context) {
    final positive = item.direction.toLowerCase() == 'long';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stacked_line_chart_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.asset, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      item.isLive ? 'LIVE NOW' : item.status.toUpperCase(),
                      style: TextStyle(
                        color: item.isLive ? AppColors.success : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.direction.toUpperCase(),
                style: TextStyle(
                  color: positive ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Metric(title: 'Expected Profit', value: '${item.profitPercent}%')),
              const SizedBox(width: 10),
              Expanded(child: _Metric(title: 'Duration', value: item.durationLabel)),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(text: 'Activate Signal', onPressed: onFollowSignal),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.backgroundSecondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 34),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              PrimaryButton(text: 'Retry', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
