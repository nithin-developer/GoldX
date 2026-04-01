import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
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
          const _MarketAlertBanner(),
          const SizedBox(height: 16),
          const _BalanceHeroCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.south_west_rounded,
                  label: 'Deposit',
                  iconColor: AppColors.secondary,
                  onTap: widget.onDeposit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.north_east_rounded,
                  label: 'Withdraw',
                  iconColor: AppColors.highlight,
                  onTap: widget.onWithdraw,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  iconColor: AppColors.secondary,
                  onTap: widget.onSupport,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Market Snapshot',
            actionText: 'VIEW MARKET',
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _loading
                ? const _SnapshotSkeletons(key: ValueKey<String>('skeleton'))
                : const _SnapshotScroller(key: ValueKey<String>('snapshot')),
          ),
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Recent Activity'),
          const SizedBox(height: 10),
          const _RecentActivityCard(),
        ],
      ),
    );
  }
}

class _MarketAlertBanner extends StatelessWidget {
  const _MarketAlertBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.campaign_rounded, size: 18, color: AppColors.secondary),
          SizedBox(width: 8),
          Expanded(
            child: _MarqueeText(
              text:
                  'Market Alert: BTC Surges above \$72k | New Signals for ETH/USDT live now | Refer a friend and earn 20%',
              style: TextStyle(
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
      duration: const Duration(seconds: 18),
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
  const _BalanceHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryShimmer,
            AppColors.primaryDark,
          ],
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
      child: Stack(
        children: [
          Positioned(
            top: -56,
            right: -40,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -64,
            left: -46,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(18),
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
                            'TOTAL BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '\$42,892.50',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PerformanceChip(),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY PROFIT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '+\$1,240.00',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldSuccessTint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _AssetCircleRow(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceChip extends StatelessWidget {
  const _PerformanceChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 14, color: AppColors.secondary),
          SizedBox(width: 4),
          Text(
            '+12.4%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _AssetCircle(icon: Icons.currency_bitcoin_rounded),
        Transform.translate(
          offset: const Offset(-8, 0),
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
  const _SnapshotSkeletons({super.key});

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
        itemCount: 3,
      ),
    );
  }
}

class _SnapshotScroller extends StatelessWidget {
  const _SnapshotScroller({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _SnapshotAssetCard(
            asset: 'BTC/USDT',
            price: '\$72,431.2',
            gain: '+2.45%',
            icon: Icons.currency_bitcoin_rounded,
            iconColor: Color(0xFFF7931A),
            positive: true,
          ),
          SizedBox(width: 10),
          _SnapshotAssetCard(
            asset: 'ETH/USDT',
            price: '\$3,842.15',
            gain: '+1.12%',
            icon: Icons.eco_rounded,
            iconColor: Color(0xFF627EEA),
            positive: true,
          ),
          SizedBox(width: 10),
          _SnapshotAssetCard(
            asset: 'SOL/USDT',
            price: '\$145.02',
            gain: '-0.84%',
            icon: Icons.show_chart_rounded,
            iconColor: AppColors.highlight,
            positive: false,
          ),
        ],
      ),
    );
  }
}

class _SnapshotAssetCard extends StatelessWidget {
  const _SnapshotAssetCard({
    required this.asset,
    required this.price,
    required this.gain,
    required this.icon,
    required this.iconColor,
    required this.positive,
  });

  final String asset;
  final String price;
  final String gain;
  final IconData icon;
  final Color iconColor;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      borderColor: AppColors.outlineVariant,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: positive ? AppColors.primary : AppColors.highlight,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            asset,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
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
              color: positive ? AppColors.secondary : AppColors.highlight,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      borderColor: AppColors.outlineVariant,
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _ActivityRow(
            title: 'Signal Executed: BTC/USDT',
            time: 'Today, 02:45 PM',
            value: '+\$420.00',
            tag: 'PROFIT',
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.secondary,
            positive: true,
          ),
          Divider(height: 1, color: AppColors.outlineVariant),
          _ActivityRow(
            title: 'Deposit Confirmed',
            time: 'Yesterday, 11:20 AM',
            value: '+\$5,000.00',
            tag: 'USDT',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.highlight,
            positive: true,
          ),
          Divider(height: 1, color: AppColors.outlineVariant),
          _ActivityRow(
            title: 'Referral Bonus Received',
            time: '22 Oct, 09:15 AM',
            value: '+\$15.00',
            tag: 'COMMISSION',
            icon: Icons.recommend_rounded,
            iconColor: AppColors.secondary,
            positive: true,
          ),
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
    required this.tag,
    required this.icon,
    required this.iconColor,
    required this.positive,
  });

  final String title;
  final String time;
  final String value;
  final String tag;
  final IconData icon;
  final Color iconColor;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: iconColor),
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
                  time,
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
                value,
                style: TextStyle(
                  color: positive ? AppColors.secondary : AppColors.danger,
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
}
