import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';
import 'package:signalpro/app/pages/deposit_history_page.dart';
import 'package:signalpro/app/pages/reward_history_page.dart';
import 'package:signalpro/app/pages/withdrawal_history_page.dart';
import 'package:signalpro/app/pages/withdrawal_password_page.dart';
import 'package:signalpro/app/pages/change_password_page.dart';
import 'package:signalpro/app/pages/about_us_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.onSupport,
    required this.onDownloadAndroidApp,
    required this.onLogout,
    required this.user,
    super.key,
  });

  final VoidCallback onSupport;
  final VoidCallback onDownloadAndroidApp;
  final VoidCallback onLogout;
  final UserProfile? user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppDataApi? _api;
  Future<UserProfile>? _future;
  int? _sessionRevision;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.of(context);
    final revision = auth.sessionRevision;

    if (_sessionRevision != revision) {
      _sessionRevision = revision;
      _api = AppDataApi(dio: auth.apiClient.dio);
      _future = _api!.getProfile(forceRefresh: true);
      return;
    }

    _api ??= AppDataApi(dio: auth.apiClient.dio);
    _future ??= _api!.getProfile();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api!.getProfile(forceRefresh: true);
    });
    final pending = _future;
    if (pending != null) {
      await pending;
    }
  }

  Future<void> _openWithdrawalPasswordPage(UserProfile user) async {
    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WithdrawalPasswordPage(
          hasExistingPassword: user.hasWithdrawalPassword,
        ),
      ),
    );

    if (didUpdate == true && mounted) {
      try {
        await _refresh();
      } catch (_) {
        // FutureBuilder will render the error state if refresh fails.
      }
    }
  }

  void _openChangePasswordPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()));
  }

  void _openDepositHistoryPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DepositHistoryPage()));
  }

  void _openWithdrawalHistoryPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WithdrawalHistoryPage()),
    );
  }

  void _openRewardHistoryPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RewardHistoryPage()));
  }

  void _openAboutUsPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AboutUsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<UserProfile>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            widget.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && widget.user == null) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : l10n.tr('Unable to load profile.');
          return _ErrorState(message: message, onRetry: _refresh);
        }

        final user = snapshot.data ?? widget.user;
        if (user == null) {
          return EmptyStateIllustration(
            title: l10n.tr('No Profile Data Found'),
            subtitle: l10n.tr(
              'Please refresh or login again to load your profile.',
            ),
            icon: Icons.person_off_outlined,
          );
        }

        final displayName = user.fullName?.trim().isNotEmpty == true
            ? user.fullName!.trim()
            : l10n.tr('GoldX User');
        final displayEmail = user.email;
        final displayId = user.id.toString();
        final joinedAt = DateFormat(
          'dd MMM yyyy',
        ).format(user.createdAt.toLocal());

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.backgroundSecondary,
                      child: Icon(Icons.person_outline_rounded, size: 34),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$displayEmail - ID: $displayId',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _InfoChip(
                          label: l10n.tr(
                            'VIP {level}',
                            params: <String, String>{
                              'level': user.vipLevel.toString(),
                            },
                          ),
                        ),
                        _InfoChip(
                          label: user.isActive
                              ? l10n.tr('Active')
                              : l10n.tr('Inactive'),
                        ),
                        _InfoChip(
                          label: l10n.tr(
                            'Joined {date}',
                            params: <String, String>{'date': joinedAt},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionTag(l10n.tr('ACCOUNT')),
              const SizedBox(height: 8),
              // _TileCard(
              //   title: 'Invite Code',
              //   subtitle: user.inviteCode?.isNotEmpty == true
              //       ? user.inviteCode!
              //       : 'Not generated yet',
              //   icon: Icons.confirmation_number_outlined,
              // ),
              // const SizedBox(height: 10),
              // _TileCard(
              //   title: 'Wallet Balance',
              //   subtitle: '\$${user.walletBalance.toStringAsFixed(2)}',
              //   icon: Icons.account_balance_wallet_outlined,
              // ),
              // const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Deposit History'),
                subtitle: l10n.tr(
                  'Track requests, approvals, and deposit details',
                ),
                icon: Icons.history_rounded,
                onTap: _openDepositHistoryPage,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Withdrawal History'),
                subtitle: l10n.tr('Monitor payouts, status updates, and notes'),
                icon: Icons.outbox_outlined,
                onTap: _openWithdrawalHistoryPage,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Rewards & Team Profit History'),
                subtitle: l10n.tr('View reward credits, types, and timestamps'),
                icon: Icons.auto_graph_rounded,
                onTap: _openRewardHistoryPage,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Withdrawal Password'),
                subtitle: user.hasWithdrawalPassword
                    ? l10n.tr('Configured')
                    : l10n.tr('Not configured'),
                icon: Icons.password_rounded,
                onTap: () => _openWithdrawalPasswordPage(user),
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Login Password'),
                subtitle: l10n.tr(
                  'Change your account login password securely',
                ),
                icon: Icons.lock_outline_rounded,
                onTap: _openChangePasswordPage,
              ),
              const SizedBox(height: 10),
              _SectionTag(l10n.tr('SUPPORT')),
              const SizedBox(height: 8),
              _TileCard(
                title: l10n.tr('About Us'),
                subtitle: l10n.tr('Company profile, PDFs, and certificate'),
                icon: Icons.info_outline_rounded,
                onTap: _openAboutUsPage,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Download Android App'),
                subtitle: l10n.tr('Download latest GoldX APK'),
                icon: Icons.android_rounded,
                onTap: widget.onDownloadAndroidApp,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Customer Support'),
                subtitle: l10n.tr('Open external support link'),
                icon: Icons.forum_outlined,
                // ontap opens external link
                onTap: widget.onSupport,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: l10n.tr('Logout'),
                subtitle: l10n.tr('End active sessions'),
                icon: Icons.logout_rounded,
                danger: true,
                onTap: widget.onLogout,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

class _SectionTag extends StatelessWidget {
  const _SectionTag(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.8,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.danger = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: danger ? AppColors.danger : AppColors.primaryBright,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: danger ? AppColors.danger : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
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
                l10n.tr('Unable to load profile'),
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
