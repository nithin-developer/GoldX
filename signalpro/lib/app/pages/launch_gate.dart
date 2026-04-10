import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signalpro/app/pages/app_shell.dart';
import 'package:signalpro/app/pages/login_page.dart';
import 'package:signalpro/app/pages/register_page.dart';
import 'package:signalpro/app/pages/verification_page.dart';
import 'package:signalpro/app/services/auth_controller.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/pages/splash_page.dart';

enum _UnauthView { login, register }

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  _UnauthView _unauthView = _UnauthView.login;
  Timer? _timer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (_showSplash || auth.status == AuthStatus.checking) {
      return const SplashPage();
    }

    if (auth.status == AuthStatus.authenticated) {
      final verificationStatus =
          auth.currentUser?.verificationStatus ?? 'not_submitted';

      if (verificationStatus != 'approved') {
        return VerificationPage(
          onApproved: () async {
            await auth.reloadUser();
          },
        );
      }

      return AppShell(onLogout: auth.logout);
    }

    switch (_unauthView) {
      case _UnauthView.login:
        return LoginPage(
          onLogin: auth.login,
          onRegister: () => setState(() => _unauthView = _UnauthView.register),
          isLoading: auth.isSubmitting,
        );
      case _UnauthView.register:
        return RegisterPage(
          onLoginTap: () => setState(() => _unauthView = _UnauthView.login),
          onRegister: ({
            required String fullName,
            required String email,
            required String password,
            required String inviteCode,
          }) async {
            final error = await auth.register(
              fullName: fullName,
              email: email,
              password: password,
              inviteCode: inviteCode,
            );

            if (error != null) {
              throw Exception(error);
            }
          },
        );
    }
  }
}
