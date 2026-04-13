import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  WalletApi? _walletApi;
  WalletSummary _walletSummary = WalletSummary.empty;

  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletApi ??= WalletApi(dio: AuthScope.of(context).apiClient.dio);

    if (_isLoading) {
      _loadWallet();
    }
  }

  Future<void> _loadWallet() async {
    try {
      final summary = await _walletApi!.getWalletSummary();
      if (!mounted) {
        return;
      }

      setState(() {
        _walletSummary = summary;
      });
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestWithdrawal() async {
    final l10n = context.l10n;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final address = _addressController.text.trim();
    final password = _passwordController.text.trim();

    if (_walletSummary.pendingWithdrawals > 0) {
      _showMessage(
        l10n.tr(
          'You already have a pending withdrawal request. Please wait for admin approval or rejection before submitting a new one.',
        ),
      );
      return;
    }

    if (amount <= 0) {
      _showMessage(l10n.tr('Please enter a valid withdrawal amount.'));
      return;
    }

    if (password.isEmpty) {
      _showMessage(l10n.tr('Withdrawal password is required.'));
      return;
    }

    if (amount > _walletSummary.withdrawableBalance) {
      _showMessage(
        l10n.tr('Requested amount exceeds your withdrawable balance.'),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _walletApi!.createWithdrawal(
        amount: amount,
        withdrawalPassword: password,
        walletAddress: address.isEmpty ? null : address,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        l10n.tr(
          'Withdrawal request submitted. Net payout {amount} after 10% fee.',
          params: <String, String>{
            'amount': _currencyFormatter.format(result.netAmount),
          },
        ),
      );

      _amountController.clear();
      _addressController.clear();
      _passwordController.clear();

      await _loadWallet();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPendingWithdrawal = _walletSummary.pendingWithdrawals > 0;
    final lockEndsAt = _walletSummary.capitalLockEndsAt;
    final lockEndsText = lockEndsAt == null
        ? '--'
        : DateFormat('dd MMM yyyy, hh:mm a').format(lockEndsAt.toLocal());
    final requestedAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    final feePercent = _walletSummary.withdrawalFeePercent > 0
        ? _walletSummary.withdrawalFeePercent
        : 10;
    final estimatedFee = (requestedAmount * feePercent) / 100;
    final estimatedNet = (requestedAmount - estimatedFee).clamp(
      0,
      double.infinity,
    );
    final feeNotice = _walletSummary.withdrawalFeeNotice.trim().isEmpty
        ? l10n.tr('10% withdrawal fee will be deducted from any withdrawal')
        : _walletSummary.withdrawalFeeNotice;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Withdraw Funds')),
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
                Text(
                  l10n.tr('WITHDRAWABLE BALANCE'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currencyFormatter.format(_walletSummary.withdrawableBalance),
                  style: const TextStyle(
                    fontSize: 36,
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tr(
                    'Total Balance: {amount}',
                    params: {
                      'amount': _currencyFormatter.format(
                        _walletSummary.balance,
                      ),
                    },
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        title: l10n.tr('Capital'),
                        value: _currencyFormatter.format(
                          _walletSummary.capitalBalance,
                        ),
                        icon: Icons.account_balance_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        title: l10n.tr('Signal Profits'),
                        value: _currencyFormatter.format(
                          _walletSummary.signalProfitBalance,
                        ),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        title: l10n.tr('Team Rewards'),
                        value: _currencyFormatter.format(
                          _walletSummary.rewardBalance,
                        ),
                        icon: Icons.groups_rounded,
                        color: AppColors.highlight,
                      ),
                    ),
                  ],
                ),
                if (_walletSummary.capitalLockActive) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      l10n.tr(
                        'First capital deposit lock: {amount} remains locked for {days} day(s), until {date}.',
                        params: {
                          'amount': _currencyFormatter.format(
                            _walletSummary.lockedCapitalBalance,
                          ),
                          'days': _walletSummary.capitalLockDaysRemaining
                              .toString(),
                          'date': lockEndsText,
                        },
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        title: l10n.tr('Pending Deposits'),
                        value: _currencyFormatter.format(
                          _walletSummary.pendingDeposits,
                        ),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BalanceCard(
                        title: l10n.tr('Pending Withdrawals'),
                        value: _currencyFormatter.format(
                          _walletSummary.pendingWithdrawals,
                        ),
                        icon: Icons.pending_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasPendingWithdrawal) ...[
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.primaryBright,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tr(
                        'Pending withdrawal request detected. New withdrawal requests are disabled until the current one is reviewed.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _InputField(
            label: l10n.tr('WITHDRAWAL AMOUNT'),
            controller: _amountController,
            showCurrencyPrefix: true,
            hint: l10n.tr('0.00'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          if (requestedAmount > 0) ...[
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeePreviewRow(
                    label: l10n.tr('Requested Amount'),
                    value: _currencyFormatter.format(requestedAmount),
                  ),
                  const SizedBox(height: 8),
                  _FeePreviewRow(
                    label: l10n.tr(
                      'Withdrawal Fee ({percent}%)',
                      params: <String, String>{
                        'percent': feePercent.toStringAsFixed(0),
                      },
                    ),
                    value: '-${_currencyFormatter.format(estimatedFee)}',
                    valueColor: AppColors.danger,
                  ),
                  const SizedBox(height: 8),
                  _FeePreviewRow(
                    label: l10n.tr('Net Payout'),
                    value: _currencyFormatter.format(estimatedNet),
                    valueColor: AppColors.success,
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _InputField(
            label: l10n.tr('DESTINATION ADDRESS / USDT (TRC20 / ERC20)'),
            controller: _addressController,
            hint: l10n.tr('Enter wallet or bank details'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _InputField(
            label: l10n.tr('WITHDRAWAL PASSWORD'),
            controller: _passwordController,
            hint: l10n.tr('Enter your withdrawal password'),
            obscureText: true,
            suffix: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.percent_rounded,
                    size: 18,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feeNotice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.background,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.tr(
                      'Capital from your first approved deposit is locked for 12 days. Signal profits and team rewards remain withdrawable.',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: _isProcessing
                ? l10n.tr('Processing...')
                : _isLoading
                ? l10n.tr('Loading wallet...')
                : l10n.tr('Request Withdrawal'),
            onPressed: (_isProcessing || _isLoading || hasPendingWithdrawal)
                ? null
                : _requestWithdrawal,
            icon: _isProcessing
                ? Icons.hourglass_bottom_rounded
                : Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeePreviewRow extends StatelessWidget {
  const _FeePreviewRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: emphasize ? 16 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.showCurrencyPrefix = false,
    required this.hint,
    this.suffix,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool showCurrencyPrefix;
  final String hint;
  final IconData? suffix;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            prefixIcon: showCurrencyPrefix
                ? const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Text(
                      r'$',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: showCurrencyPrefix
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
            suffixIcon: suffix == null
                ? null
                : const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: showCurrencyPrefix ? 0 : 16,
              vertical: maxLines > 1 ? 16 : 18,
            ),
          ),
        ),
      ],
    );
  }
}
