import 'package:flutter/material.dart';
import 'package:signalpro/app/models/signal_item.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class SignalsPage extends StatelessWidget {
  const SignalsPage({required this.onFollowSignal, super.key});

  final VoidCallback onFollowSignal;

  @override
  Widget build(BuildContext context) {
    const signals = [
      SignalItem(asset: 'BTC/USDT', direction: 'Long', participation: 84.2, duration: '24h', live: true),
      SignalItem(asset: 'SOL/USDT', direction: 'Long', participation: 61.5, duration: '12h', live: false),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LIVE FEED', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: AppColors.textSecondary)),
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
                  Icon(Icons.filter_list_rounded, size: 18),
                  SizedBox(width: 4),
                  Text('Filters'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SignalCard(item: signals[0], onFollowSignal: onFollowSignal),
        const SizedBox(height: 12),
        const _LockedCard(),
        const SizedBox(height: 12),
        _SignalCard(item: signals[1], onFollowSignal: onFollowSignal),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.item, required this.onFollowSignal});

  final SignalItem item;
  final VoidCallback onFollowSignal;

  @override
  Widget build(BuildContext context) {
    final positive = item.direction == 'Long';
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
                      item.live ? 'LIVE NOW' : 'SCHEDULED',
                      style: const TextStyle(color: AppColors.success, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                item.direction,
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
              Expanded(child: _Metric(title: 'Participation', value: '${item.participation}%')),
              const SizedBox(width: 10),
              Expanded(child: _Metric(title: 'Duration', value: item.duration)),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(text: 'Activate Signal', onPressed: onFollowSignal),
        ],
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.35,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('ETH/USDT', style: TextStyle(fontWeight: FontWeight.w700)),
                    Spacer(),
                    Text('Short', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: _Metric(title: 'Participation', value: 'Locked')),
                    SizedBox(width: 10),
                    Expanded(child: _Metric(title: 'Duration', value: '4h')),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfaceSoft,
                  ),
                  child: const Text('Upgrade to Unlock'),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, color: AppColors.tertiary),
                  SizedBox(height: 2),
                  Text('VIP ACCESS ONLY', style: TextStyle(fontSize: 10, color: AppColors.tertiary, letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ),
      ],
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
