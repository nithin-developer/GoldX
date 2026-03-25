import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF081126), Color(0xFF0C1730), Color(0xFF0B1220)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBright, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66528DFF),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.signal_cellular_alt_rounded, size: 62, color: AppColors.background),
              ),
              const SizedBox(height: 18),
              const Text('SignalPro', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800)),
              const Spacer(),
              const Text(
                'SECURELY CONNECTING TO SIGNALPRO...',
                style: TextStyle(fontSize: 11, letterSpacing: 2, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Container(
                width: 240,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, AppColors.primary, Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DotLabel(label: 'ENCRYPTED'),
                  SizedBox(width: 20),
                  _DotLabel(label: 'LIVE SYNC'),
                ],
              ),
              const SizedBox(height: 42),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotLabel extends StatelessWidget {
  const _DotLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.4)),
      ],
    );
  }
}
