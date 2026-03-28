import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/models/referral_models.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';
import 'package:signalpro/app/widgets/section_header.dart';

class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends State<ReferralsPage> {
  AppDataApi? _api;
  Future<_ReferralData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= AppDataApi(dio: AuthScope.of(context).apiClient.dio);
    _future ??= _load();
  }

  Future<_ReferralData> _load({bool forceRefresh = false}) async {
    final results = await Future.wait<dynamic>([
      _api!.getReferralStats(forceRefresh: forceRefresh),
      _api!.getReferrals(limit: 20, forceRefresh: forceRefresh),
    ]);

    return _ReferralData(
      stats: results[0] as ReferralStats,
      referrals: results[1] as List<ReferralItem>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load(forceRefresh: true);
    });
    final pending = _future;
    if (pending != null) {
      await pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReferralData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Failed to load referral data.';
          return _ErrorState(message: message, onRetry: _refresh);
        }

        final data = snapshot.data;
        if (data == null) {
          return const EmptyStateIllustration(
            title: 'No Data Found',
            subtitle: 'Referral information is unavailable right now.',
            icon: Icons.group_off_rounded,
          );
        }

        final stats = data.stats;
        final referrals = data.referrals;
        final inviteCode = (stats.inviteCode ?? '').trim();
        final inviteLink = inviteCode.isEmpty
            ? '--'
            : 'signalpro.app/join/ref/${inviteCode.toLowerCase()}';

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Invite & Earn', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Affiliate Portal', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Referral Progress')),
                        Chip(label: Text('QUALIFIED ${stats.qualifiedReferrals}')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stats.qualifiedReferrals} / ${stats.totalReferrals}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: stats.totalReferrals == 0
                          ? 0
                          : (stats.qualifiedReferrals / stats.totalReferrals).clamp(0, 1),
                      minHeight: 8,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Invite users and increase qualified deposits to unlock higher rewards.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Total Referrals', value: '${stats.totalReferrals}')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(title: 'Earned', value: '\$${stats.totalBonusEarned.toStringAsFixed(2)}')),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invite Code', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text(
                      inviteCode.isEmpty ? 'Not available' : inviteCode,
                      style: const TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    const Text('Invite Link', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(inviteLink),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Recent Activity'),
              const SizedBox(height: 8),
              if (referrals.isEmpty)
                const GlassCard(
                  child: EmptyStateIllustration(
                    title: 'No Referrals Yet',
                    subtitle: 'Share your invite code to start seeing referral activity.',
                    icon: Icons.group_add_outlined,
                  ),
                )
              else
                GlassCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < referrals.length; i++) ...[
                        _ReferralRow(item: referrals[i]),
                        if (i != referrals.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReferralData {
  const _ReferralData({required this.stats, required this.referrals});

  final ReferralStats stats;
  final List<ReferralItem> referrals;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReferralRow extends StatelessWidget {
  const _ReferralRow({required this.item});

  final ReferralItem item;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy');
    final bonusValue = item.bonusAmount > 0
        ? '+\$${item.bonusAmount.toStringAsFixed(2)}'
        : '\$0.00';

    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.surfaceSoft,
          child: Icon(Icons.person, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.referredEmail ?? 'User #${item.referredUserId}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${item.status.toUpperCase()} • ${formatter.format(item.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          bonusValue,
          style: TextStyle(
            color: item.bonusAmount > 0 ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
              const SizedBox(height: 8),
              const Text('Unable to load referrals', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              PrimaryButton(text: 'Retry', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
