import 'package:flutter/material.dart';
import 'package:signalpro/app/pages/deposit_page.dart';
import 'package:signalpro/app/pages/home_page.dart';
import 'package:signalpro/app/pages/market_page.dart';
import 'package:signalpro/app/pages/notifications_page.dart';
import 'package:signalpro/app/pages/profile_page.dart';
import 'package:signalpro/app/pages/referrals_page.dart';
import 'package:signalpro/app/pages/signals_page.dart';
import 'package:signalpro/app/pages/withdraw_page.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/app_header.dart';
import 'package:url_launcher/url_launcher.dart';

enum AppTab { home, signals, market, referrals, profile }

class AppShell extends StatefulWidget {
  const AppShell({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _currentTab = AppTab.home;
  WalletApi? _walletApi;
  bool _openingSupportLink = false;

  void _openDeposit() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const DepositPage()));

  void _openWithdraw() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const WithdrawPage()));

  void _openSupport() {
    _openSupportExternalLink();
  }

  Future<void> _openSupportExternalLink() async {
    if (_openingSupportLink) {
      return;
    }

    _openingSupportLink = true;
    _walletApi ??= WalletApi(dio: AuthScope.of(context).apiClient.dio);

    try {
      final details = await _walletApi!.getDepositWalletDetails();
      final supportUrl = details.supportUrl?.trim();

      if (supportUrl == null || supportUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support link is not configured yet.'),
            ),
          );
        }
        return;
      }

      final normalizedUrl =
          supportUrl.startsWith('http://') || supportUrl.startsWith('https://')
          ? supportUrl
          : 'https://$supportUrl';

      final launchUri = Uri.tryParse(normalizedUrl);
      if (launchUri == null || !launchUri.hasScheme) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Support link is invalid. Contact administrator.'),
            ),
          );
        }
        return;
      }

      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open support link on this device.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load support link. Please try again.'),
          ),
        );
      }
    } finally {
      _openingSupportLink = false;
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final page = _buildCurrentPage();
    final wide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surfaceSoft,
              AppColors.backgroundSecondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentTab.index,
                      onDestinationSelected: (index) {
                        setState(() => _currentTab = AppTab.values[index]);
                      },
                      backgroundColor: Colors.transparent,
                      selectedIconTheme: const IconThemeData(
                        color: AppColors.primaryBright,
                      ),
                      unselectedIconTheme: const IconThemeData(
                        color: AppColors.textMuted,
                      ),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home_rounded),
                          label: Text('Home'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.bolt_outlined),
                          selectedIcon: Icon(Icons.bolt_rounded),
                          label: Text('Signals'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.candlestick_chart_outlined),
                          selectedIcon: Icon(Icons.candlestick_chart_rounded),
                          label: Text('Market'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.groups_outlined),
                          selectedIcon: Icon(Icons.groups_2_rounded),
                          label: Text('Referrals'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                    const VerticalDivider(color: AppColors.border, width: 1),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: _BodyLayout(
                            tab: _currentTab,
                            onNotificationsTap: _openNotifications,
                            child: page,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : _BodyLayout(
                  tab: _currentTab,
                  onNotificationsTap: _openNotifications,
                  child: page,
                ),
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _currentTab.index,
              onDestinationSelected: (index) {
                setState(() => _currentTab = AppTab.values[index]);
              },
              backgroundColor: AppColors.surface.withValues(alpha: 0.95),
              indicatorColor: AppColors.primary.withValues(alpha: 0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bolt_outlined),
                  selectedIcon: Icon(Icons.bolt),
                  label: 'Signals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.candlestick_chart_outlined),
                  selectedIcon: Icon(Icons.candlestick_chart),
                  label: 'Market',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Referrals',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentTab) {
      case AppTab.home:
        return HomePage(
          onDeposit: _openDeposit,
          onWithdraw: _openWithdraw,
          onSupport: _openSupport,
        );
      case AppTab.signals:
        return const SignalsPage();
      case AppTab.market:
        return const MarketPage();
      case AppTab.referrals:
        return const ReferralsPage();
      case AppTab.profile:
        final auth = AuthScope.of(context);
        return ProfilePage(
          user: auth.currentUser,
          onSupport: _openSupport,
          onLogout: widget.onLogout,
        );
    }
  }
}

class _BodyLayout extends StatelessWidget {
  const _BodyLayout({
    required this.child,
    required this.tab,
    required this.onNotificationsTap,
  });

  final Widget child;
  final AppTab tab;
  final Future<void> Function() onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppHeader(
            title: 'SignalPro',
            subtitle: _tabSubtitle(tab),
            onNotificationsTap: onNotificationsTap,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: child,
          ),
        ),
      ],
    );
  }

  String _tabSubtitle(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return 'Dashboard';
      case AppTab.signals:
        return 'Active Signals';
      case AppTab.market:
        return 'Live Market';
      case AppTab.referrals:
        return 'Invite & VIP';
      case AppTab.profile:
        return 'Account';
    }
  }
}
