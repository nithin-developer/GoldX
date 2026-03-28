import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.onSupport,
    required this.onLogout,
    required this.user,
    super.key,
  });

  final VoidCallback onSupport;
  final VoidCallback onLogout;
  final UserProfile? user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AppDataApi? _api;
  Future<UserProfile>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= AppDataApi(dio: AuthScope.of(context).apiClient.dio);
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && widget.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && widget.user == null) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : 'Unable to load profile.';
          return _ErrorState(message: message, onRetry: _refresh);
        }

        final user = snapshot.data ?? widget.user;
        if (user == null) {
          return const EmptyStateIllustration(
            title: 'No Profile Data Found',
            subtitle: 'Please refresh or login again to load your profile.',
            icon: Icons.person_off_outlined,
          );
        }

        final displayName = user.fullName?.trim().isNotEmpty == true
            ? user.fullName!.trim()
            : 'SignalPro User';
        final displayEmail = user.email;
        final displayId = user.id.toString();
        final joinedAt = DateFormat('dd MMM yyyy').format(user.createdAt.toLocal());

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
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
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
                        _InfoChip(label: 'VIP ${user.vipLevel}'),
                        _InfoChip(label: user.isActive ? 'Active' : 'Inactive'),
                        _InfoChip(label: 'Joined $joinedAt'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _SectionTag('ACCOUNT'),
              const SizedBox(height: 8),
              _TileCard(
                title: 'Invite Code',
                subtitle: user.inviteCode?.isNotEmpty == true ? user.inviteCode! : 'Not generated yet',
                icon: Icons.confirmation_number_outlined,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: 'Wallet Balance',
                subtitle: '\$${user.walletBalance.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: 'Withdrawal Password',
                subtitle: user.hasWithdrawalPassword ? 'Configured' : 'Not configured',
                icon: Icons.password_rounded,
              ),
              const SizedBox(height: 10),
              const _SectionTag('SUPPORT'),
              const SizedBox(height: 8),
              _TileCard(
                title: 'Customer Support',
                subtitle: 'Talk to a live agent',
                icon: Icons.forum_outlined,
                onTap: widget.onSupport,
              ),
              const SizedBox(height: 10),
              _TileCard(
                title: 'Logout',
                subtitle: 'End active sessions',
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
            child: Icon(icon, color: danger ? AppColors.danger : AppColors.primaryBright),
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
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 34),
              const SizedBox(height: 8),
              const Text('Unable to load profile', style: TextStyle(fontWeight: FontWeight.w700)),
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
