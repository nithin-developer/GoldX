import 'package:flutter/material.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/theme/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: Container(
        width: double.infinity,
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
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                width: 180,
                height: 180,
                // child: const Icon(Icons.signal_cellular_alt_rounded, size: 62, color: AppColors.background),
                child: const Image(
                  image: AssetImage('splash_screen.png'),
                  height: 180,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 18),
              // Text(
              //   l10n.tr('GoldX'),
              //   style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
              // ),
              const Spacer(),
              Text(
                l10n.tr('SECURELY CONNECTING TO GOLDX...'),
                style: const TextStyle(fontSize: 11, letterSpacing: 2, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DotLabel(label: l10n.tr('ENCRYPTED')),
                  const SizedBox(width: 20),
                  _DotLabel(label: l10n.tr('LIVE SYNC')),
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
