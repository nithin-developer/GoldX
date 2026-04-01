import 'package:flutter/material.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.onNotificationsTap,
  });

  final String title;
  final String? subtitle;
  final Future<void> Function()? onNotificationsTap;

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  AppDataApi? _api;
  Future<int>? _unreadFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= AppDataApi(dio: AuthScope.of(context).apiClient.dio);
    _unreadFuture ??= _api!.getUnreadNotificationsCount();
  }

  void _refreshUnread() {
    setState(() {
      _unreadFuture = _api!.getUnreadNotificationsCount(forceRefresh: true);
    });
  }

  Future<void> _handleNotificationsTap() async {
    if (widget.onNotificationsTap == null) {
      _refreshUnread();
      return;
    }

    await widget.onNotificationsTap!.call();
    if (!mounted) {
      return;
    }

    _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Image(
            image: AssetImage('logo.png'),
            height: 55,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          FutureBuilder<int>(
            future: _unreadFuture,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: _handleNotificationsTap,
                    icon: const Icon(Icons.notifications_none_rounded, size: 26),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
