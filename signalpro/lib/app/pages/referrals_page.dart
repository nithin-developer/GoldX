import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/models/referral_models.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';
import 'package:signalpro/app/widgets/section_header.dart';

const List<_VipLevelSpec> _vipLevelSpecs = <_VipLevelSpec>[
  _VipLevelSpec(level: 1, minQualifiedReferrals: 5, teamProfitRatePercent: 0.5),
  _VipLevelSpec(
    level: 2,
    minQualifiedReferrals: 10,
    teamProfitRatePercent: 0.6,
  ),
  _VipLevelSpec(
    level: 3,
    minQualifiedReferrals: 20,
    teamProfitRatePercent: 0.7,
  ),
  _VipLevelSpec(
    level: 4,
    minQualifiedReferrals: 30,
    teamProfitRatePercent: 0.8,
  ),
  _VipLevelSpec(
    level: 5,
    minQualifiedReferrals: 40,
    teamProfitRatePercent: 0.9,
  ),
  _VipLevelSpec(
    level: 6,
    minQualifiedReferrals: 50,
    teamProfitRatePercent: 1.0,
  ),
];

class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends State<ReferralsPage> {
  AppDataApi? _api;
  Future<_ReferralData>? _future;

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyInviteCode(String inviteCode) async {
    final l10n = context.l10n;
    final code = inviteCode.trim();

    if (code.isEmpty) {
      _showMessage(l10n.tr('Invite code is not available yet.'));
      return;
    }

    await Clipboard.setData(ClipboardData(text: code));
    _showMessage(l10n.tr('Invite code copied to clipboard'));
  }

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
    final l10n = context.l10n;

    return FutureBuilder<_ReferralData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : l10n.tr('Unable to load referrals');
          return _ErrorState(message: message, onRetry: _refresh);
        }

        final data = snapshot.data;
        if (data == null) {
          return EmptyStateIllustration(
            title: l10n.tr('No Data Found'),
            subtitle: l10n.tr('Referral information is unavailable right now.'),
            icon: Icons.group_off_rounded,
          );
        }

        final stats = data.stats;
        final referrals = data.referrals;
        final inviteCode = (stats.inviteCode ?? '').trim();
        final nextTarget =
            stats.nextVipReferralTarget ??
            _vipLevelSpecs.last.minQualifiedReferrals;
        final progressTarget = nextTarget <= 0 ? 1 : nextTarget;
        final progressValue = (stats.qualifiedReferrals / progressTarget)
            .clamp(0, 1)
            .toDouble();
        final nextVipMessage = stats.nextVipLevel == null
            ? l10n.tr('Maximum VIP reached')
            : l10n.tr(
                'Need {count} more qualified referrals for VIP {level}.',
                params: <String, String>{
                  'count': stats.referralsNeededForNextVip.toString(),
                  'level': stats.nextVipLevel.toString(),
                },
              );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.tr('Invite & Earn'),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.tr('Affiliate Portal'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.tr('Referral Progress'))),
                        Chip(
                          label: Text(
                            l10n.tr(
                              'VIP {level}',
                              params: <String, String>{
                                'level': stats.vipLevel.toString(),
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stats.qualifiedReferrals} / $progressTarget',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 8,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.tr(
                        'Each referral qualifies after approved deposits reach {amount} USD.',
                        params: <String, String>{
                          'amount': stats.minimumReferralDeposit
                              .toStringAsFixed(0),
                        },
                      ),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextVipMessage,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: l10n.tr('Total Referrals'),
                      value: '${stats.totalReferrals}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: l10n.tr('Earned'),
                      value: '\$${stats.totalBonusEarned.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: l10n.tr('Current VIP'),
                      value: 'VIP ${stats.vipLevel}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: l10n.tr('Team Profit Rate'),
                      value:
                          '${stats.teamProfitRatePercent.toStringAsFixed(1)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('Invite Code'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inviteCode.isEmpty
                                ? l10n.tr('Not available')
                                : inviteCode,
                            style: const TextStyle(
                              fontSize: 18,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: inviteCode.isEmpty
                              ? null
                              : () => _copyInviteCode(inviteCode),
                          tooltip: l10n.tr('Copy invite code'),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionHeader(title: l10n.tr('VIP Levels')),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    const _VipLevelHeader(),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _vipLevelSpecs.length; i++) ...[
                      _VipLevelRow(
                        spec: _vipLevelSpecs[i],
                        currentVipLevel: stats.vipLevel,
                        qualifiedReferrals: stats.qualifiedReferrals,
                      ),
                      if (i != _vipLevelSpecs.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionHeader(title: l10n.tr('Recent Activity')),
              const SizedBox(height: 8),
              if (referrals.isEmpty)
                GlassCard(
                  child: EmptyStateIllustration(
                    title: l10n.tr('No Referrals Yet'),
                    subtitle: l10n.tr(
                      'Share your invite code to start seeing referral activity.',
                    ),
                    icon: Icons.group_add_outlined,
                  ),
                )
              else
                GlassCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < referrals.length; i++) ...[
                        _ReferralRow(item: referrals[i]),
                        if (i != referrals.length - 1)
                          const SizedBox(height: 10),
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

class _VipLevelSpec {
  const _VipLevelSpec({
    required this.level,
    required this.minQualifiedReferrals,
    required this.teamProfitRatePercent,
  });

  final int level;
  final int minQualifiedReferrals;
  final double teamProfitRatePercent;
}

class _VipLevelHeader extends StatelessWidget {
  const _VipLevelHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.tr('Current VIP'),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            l10n.tr('Qualified Referrals'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            l10n.tr('Team Profit Rate'),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _VipLevelRow extends StatelessWidget {
  const _VipLevelRow({
    required this.spec,
    required this.currentVipLevel,
    required this.qualifiedReferrals,
  });

  final _VipLevelSpec spec;
  final int currentVipLevel;
  final int qualifiedReferrals;

  @override
  Widget build(BuildContext context) {
    final isCurrent = currentVipLevel == spec.level;
    final isUnlocked = qualifiedReferrals >= spec.minQualifiedReferrals;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.surfaceSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'VIP ${spec.level}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${spec.minQualifiedReferrals}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${spec.teamProfitRatePercent.toStringAsFixed(1)}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isUnlocked ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
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
    final l10n = context.l10n;
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
              Text(
                item.referredEmail ??
                    l10n.tr(
                      'User #{id}',
                      params: <String, String>{
                        'id': item.referredUserId.toString(),
                      },
                    ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${item.status.toUpperCase()} • ${formatter.format(item.createdAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          bonusValue,
          style: TextStyle(
            color: item.bonusAmount > 0
                ? AppColors.success
                : AppColors.textSecondary,
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
                l10n.tr('Unable to load referrals'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              PrimaryButton(text: l10n.tr('Retry'), onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
