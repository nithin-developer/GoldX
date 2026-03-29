import 'package:flutter/material.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class WithdrawalPasswordPage extends StatefulWidget {
  const WithdrawalPasswordPage({
    required this.hasExistingPassword,
    super.key,
  });

  final bool hasExistingPassword;

  @override
  State<WithdrawalPasswordPage> createState() => _WithdrawalPasswordPageState();
}

class _WithdrawalPasswordPageState extends State<WithdrawalPasswordPage> {
  WalletApi? _walletApi;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isUpdateMode => widget.hasExistingPassword;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletApi ??= WalletApi(dio: AuthScope.of(context).apiClient.dio);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (_isUpdateMode && currentPassword.isEmpty) {
      _showMessage('Please enter your current withdrawal password.');
      return;
    }

    if (newPassword.isEmpty) {
      _showMessage('Please enter a new withdrawal password.');
      return;
    }

    if (newPassword.length < 6) {
      _showMessage('Withdrawal password must be at least 6 characters.');
      return;
    }

    if (confirmPassword != newPassword) {
      _showMessage('New password and confirmation do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _walletApi!.setOrUpdateWithdrawalPassword(
        newWithdrawalPassword: newPassword,
        currentWithdrawalPassword: _isUpdateMode ? currentPassword : null,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _isUpdateMode
            ? 'Withdrawal password updated successfully.'
            : 'Withdrawal password set successfully.',
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isUpdateMode ? 'Update Withdrawal Password' : 'Set Withdrawal Password';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SECURITY STATUS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isUpdateMode ? Icons.lock_reset_rounded : Icons.lock_open_rounded,
                        color: AppColors.primaryBright,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isUpdateMode
                            ? 'Your account is protected. Enter current password to update it.'
                            : 'No withdrawal password set yet. Create one to secure withdrawals.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isUpdateMode) ...[
            _PasswordInput(
              label: 'CURRENT WITHDRAWAL PASSWORD',
              controller: _currentPasswordController,
              hint: 'Enter current password',
              obscureText: _obscureCurrentPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          _PasswordInput(
            label: 'NEW WITHDRAWAL PASSWORD',
            controller: _newPasswordController,
            hint: 'Enter at least 6 characters',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
          ),
          const SizedBox(height: 16),
          _PasswordInput(
            label: 'CONFIRM NEW PASSWORD',
            controller: _confirmPasswordController,
            hint: 'Re-enter new password',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SecurityTipRow(text: 'Use at least 6 characters.'),
                SizedBox(height: 10),
                _SecurityTipRow(text: 'Do not reuse your login password.'),
                SizedBox(height: 10),
                _SecurityTipRow(text: 'You will need this password for every withdrawal request.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: _isSubmitting
                ? (_isUpdateMode ? 'Updating Password...' : 'Setting Password...')
                : (_isUpdateMode ? 'Update Withdrawal Password' : 'Set Withdrawal Password'),
            onPressed: _isSubmitting ? null : _submit,
            icon: _isUpdateMode ? Icons.lock_reset_rounded : Icons.lock_rounded,
          ),
        ],
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput({
    required this.label,
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityTipRow extends StatelessWidget {
  const _SecurityTipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
