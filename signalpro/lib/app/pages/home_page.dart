import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/section_header.dart';
import 'package:signalpro/app/widgets/skeleton_box.dart';

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
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Market Alert: BTC signals above 57% this session',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1C4EA8), Color(0xFF4F8CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL BALANCE', style: TextStyle(fontSize: 11, color: Colors.white70)),
                SizedBox(height: 8),
                Text('\$4,892.50', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
                SizedBox(height: 10),
                Text('+ \$1,240.00 today', style: TextStyle(color: Color(0xFFC6F6D5))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.arrow_downward_rounded,
                label: 'Deposit',
                onTap: widget.onDeposit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.arrow_upward_rounded,
                label: 'Withdraw',
                onTap: widget.onWithdraw,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.support_agent_rounded,
                label: 'Support',
                onTap: widget.onSupport,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Market Snapshot', actionText: 'View Market'),
        const SizedBox(height: 10),
        if (_loading)
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 92)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 92)),
              SizedBox(width: 10),
              Expanded(child: SkeletonBox(height: 92)),
            ],
          )
        else
          const Row(
            children: [
              Expanded(child: _AssetCard(asset: 'BTC', pair: 'BTC/USDT', price: '\$68,432.12', gain: '+4.28%')),
              SizedBox(width: 10),
              Expanded(child: _AssetCard(asset: 'ETH', pair: 'ETH/USDT', price: '\$3,842.15', gain: '+2.18%')),
              SizedBox(width: 10),
              Expanded(child: _AssetCard(asset: 'SOL', pair: 'SOL/USDT', price: '\$145.06', gain: '+6.32%')),
            ],
          ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Recent Activity'),
        const SizedBox(height: 8),
        const GlassCard(
          child: Column(
            children: [
              _ActivityRow(
                title: 'Signal Executed BTC/USDT',
                time: 'Today, 02:45 PM',
                value: '+\$420.00',
                positive: true,
              ),
              SizedBox(height: 10),
              _ActivityRow(
                title: 'Deposit Confirmed',
                time: 'Yesterday, 11:40 AM',
                value: '+\$5,000.00',
                positive: true,
              ),
              SizedBox(height: 10),
              _ActivityRow(
                title: 'Referral Bonus Received',
                time: '22 Oct, 03:15 AM',
                value: '-\$15.00',
                positive: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBright),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.asset,
    required this.pair,
    required this.price,
    required this.gain,
  });

  final String asset;
  final String pair;
  final String price;
  final String gain;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(asset, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(pair, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 8),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(gain, style: const TextStyle(color: AppColors.success, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.time,
    required this.value,
    required this.positive,
  });

  final String title;
  final String time;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.insights_rounded, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(time, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: positive ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
