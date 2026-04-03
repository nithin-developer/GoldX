import 'package:flutter/material.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/localization/locale_scope.dart';
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
    final l10n = context.l10n;
    final localeController = LocaleScope.of(context);
    final languageCode = localeController.locale.languageCode.toUpperCase();

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
          PopupMenuButton<Locale>(
            tooltip: l10n.tr('Change language'),
            onSelected: (locale) {
              localeController.setLocale(locale);
            },
            itemBuilder: (context) {
              return <PopupMenuEntry<Locale>>[
                PopupMenuItem<Locale>(
                  value: const Locale('en'),
                  child: Text(l10n.tr('English')),
                ),
                PopupMenuItem<Locale>(
                  value: const Locale('ar'),
                  child: Text(l10n.tr('Arabic')),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    languageCode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
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
