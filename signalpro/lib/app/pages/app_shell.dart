import 'package:flutter/material.dart';
import 'package:signalpro/app/pages/deposit_page.dart';
import 'package:signalpro/app/pages/follow_signal_page.dart';
import 'package:signalpro/app/pages/home_page.dart';
import 'package:signalpro/app/pages/market_page.dart';
import 'package:signalpro/app/pages/profile_page.dart';
import 'package:signalpro/app/pages/referrals_page.dart';
import 'package:signalpro/app/pages/signals_page.dart';
import 'package:signalpro/app/pages/support_chat_page.dart';
import 'package:signalpro/app/pages/withdraw_page.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/app_header.dart';

enum AppTab { home, signals, market, referrals, profile }

class AppShell extends StatefulWidget {
  const AppShell({required this.onLogout, super.key});

  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _currentTab = AppTab.home;

  void _openDeposit() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DepositPage()));

  void _openWithdraw() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WithdrawPage()));

  void _openSupport() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SupportChatPage()));

  void _openFollowSignal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FollowSignalPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _buildCurrentPage();
    final wide = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1220), Color(0xFF0D1830)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                      selectedIconTheme: const IconThemeData(color: AppColors.primaryBright),
                      unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
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
                          child: _BodyLayout(tab: _currentTab, child: page),
                        ),
                      ),
                    ),
                  ],
                )
              : _BodyLayout(tab: _currentTab, child: page),
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
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Signals'),
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
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
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
        return SignalsPage(onFollowSignal: _openFollowSignal);
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
  const _BodyLayout({required this.child, required this.tab});

  final Widget child;
  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppHeader(
            title: 'SignalPro',
            subtitle: _tabSubtitle(tab),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: child)),
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
