import 'package:flutter/material.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/localization/locale_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class AuthLanguageSwitcher extends StatelessWidget {
  const AuthLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeController = LocaleScope.of(context);
    final languageCode = localeController.locale.languageCode.toUpperCase();

    return PopupMenuButton<Locale>(
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
    );
  }
}