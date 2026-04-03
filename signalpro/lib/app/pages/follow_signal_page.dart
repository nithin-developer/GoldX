import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

enum FollowState { idle, loading, success, error }

class FollowSignalPage extends StatefulWidget {
  const FollowSignalPage({super.key});

  @override
  State<FollowSignalPage> createState() => _FollowSignalPageState();
}

class _FollowSignalPageState extends State<FollowSignalPage> {
  final TextEditingController _codeController = TextEditingController();
  FollowState _state = FollowState.idle;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _state = FollowState.loading);

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final code = _codeController.text.trim().toUpperCase();
      final isValid = code.startsWith('SIG-') && code.length >= 8;
      setState(() => _state = isValid ? FollowState.success : FollowState.error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('Follow Signal'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Text(
              l10n.tr(
                'Enter a signal code from your analyst or GoldX channel. Valid examples look like SIG-X922.',
              ),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(letterSpacing: 1.2),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: l10n.tr('SIG-XXXX'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            text: _state == FollowState.loading
                ? l10n.tr('Validating...')
                : l10n.tr('Activate Signal'),
            onPressed: _state == FollowState.loading ? null : _submit,
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _buildStateWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildStateWidget() {
    final l10n = context.l10n;

    switch (_state) {
      case FollowState.loading:
        return GlassCard(
          key: ValueKey('loading'),
          child: Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(l10n.tr('Checking signal integrity and market lock...')),
            ],
          ),
        );
      case FollowState.success:
        return GlassCard(
          key: const ValueKey('success'),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.tr(
                    'Signal activated successfully. Position is now tracking real-time updates.',
                  ),
                ),
              ),
            ],
          ),
        );
      case FollowState.error:
        return GlassCard(
          key: const ValueKey('error'),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.tr(
                    'Invalid code. Please verify with your analyst and try again.',
                  ),
                ),
              ),
            ],
          ),
        );
      case FollowState.idle:
        return const SizedBox.shrink(key: ValueKey('idle'));
    }
  }
}
