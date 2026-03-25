import 'package:flutter/material.dart';
import 'package:signalpro/app/models/user_profile.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';

class ProfilePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final displayName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : 'SignalPro User';
    final displayEmail = user?.email ?? 'No email';
    final displayId = user?.id.toString() ?? '--';

    return ListView(
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _SectionTag('ACCOUNT'),
        const SizedBox(height: 8),
        const _TileCard(
          title: 'Account Settings',
          subtitle: 'Profile details and KYC status',
          icon: Icons.account_box_outlined,
        ),
        const SizedBox(height: 10),
        const _TileCard(
          title: 'Withdrawal Password',
          subtitle: 'Secure your withdrawals',
          icon: Icons.password_rounded,
        ),
        const SizedBox(height: 10),
        const _SectionTag('SECURITY'),
        const SizedBox(height: 8),
        const _TileCard(
          title: 'Security Settings',
          subtitle: '2FA and session controls',
          icon: Icons.security_outlined,
        ),
        const SizedBox(height: 10),
        const _SectionTag('PREFERENCES'),
        const SizedBox(height: 8),
        const _SwitchCard(),
        const SizedBox(height: 10),
        _TileCard(
          title: 'Customer Support',
          subtitle: 'Talk to a live agent',
          icon: Icons.forum_outlined,
          onTap: onSupport,
        ),
        const SizedBox(height: 10),
        _TileCard(
          title: 'Logout',
          subtitle: 'End active sessions',
          icon: Icons.logout_rounded,
          danger: true,
          onTap: onLogout,
        ),
      ],
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

class _SwitchCard extends StatefulWidget {
  const _SwitchCard();

  @override
  State<_SwitchCard> createState() => _SwitchCardState();
}

class _SwitchCardState extends State<_SwitchCard> {
  bool notifications = true;
  bool darkMode = true;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: notifications,
            onChanged: (value) => setState(() => notifications = value),
            title: const Text('Notifications'),
            subtitle: const Text('Price alerts and signal triggers'),
          ),
          const Divider(height: 8),
          SwitchListTile.adaptive(
            value: darkMode,
            onChanged: (value) => setState(() => darkMode = value),
            title: const Text('Dark Mode'),
            subtitle: const Text('Optimized for low luminance'),
          ),
        ],
      ),
    );
  }
}
