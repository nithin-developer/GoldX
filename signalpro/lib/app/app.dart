import 'package:flutter/material.dart';
import 'package:signalpro/app/pages/launch_gate.dart';
import 'package:signalpro/app/services/auth_controller.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_theme.dart';

class SignalProApp extends StatefulWidget {
  const SignalProApp({super.key});

  @override
  State<SignalProApp> createState() => _SignalProAppState();
}

class _SignalProAppState extends State<SignalProApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.initialize();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SignalPro',
        theme: AppTheme.dark(),
        home: const LaunchGate(),
      ),
    );
  }
}
