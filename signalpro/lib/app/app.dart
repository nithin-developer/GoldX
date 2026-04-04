import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/pages/launch_gate.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/localization/locale_controller.dart';
import 'package:signalpro/app/localization/locale_scope.dart';
import 'package:signalpro/app/services/auth_controller.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_theme.dart';
import 'package:flutter/foundation.dart';

class GoldXApp extends StatefulWidget {
  const GoldXApp({super.key});

  @override
  State<GoldXApp> createState() => _GoldXAppState();
}

class _GoldXAppState extends State<GoldXApp> {
  late final AuthController _authController;
  late final LocaleController _localeController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.initialize();
    _localeController = LocaleController();
    _localeController.initialize();
  }

  @override
  void dispose() {
    _localeController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: LocaleScope(
        controller: _localeController,
        child: AnimatedBuilder(
          animation: _localeController,
          builder: (context, _) {
            Intl.defaultLocale = _localeController.locale.languageCode;

            return MaterialApp(
              builder: (context, child) {
                if (kIsWeb) {
                  return Container(
                    color: Colors.grey[100], // background like web page
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Container(
                          child: child,
                        ),
                      ),
                    ),
                  );
                }

                return child!;
              },
              debugShowCheckedModeBanner: false,
              locale: _localeController.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              title: 'GoldX',
              theme: AppTheme.light(),
              home: const LaunchGate(),
            );
          },
        ),
      ),
    );
  }
}
