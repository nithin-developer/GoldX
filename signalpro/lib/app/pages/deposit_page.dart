import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  final ImagePicker _imagePicker = ImagePicker();

  WalletApi? _walletApi;
  WalletSummary _walletSummary = WalletSummary.empty;
  DepositWalletDetails? _walletDetails;
  XFile? _paymentScreenshot;

  bool _isLoading = true;
  bool _isPickingProof = false;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletApi ??= WalletApi(dio: AuthScope.of(context).apiClient.dio);

    if (_isLoading) {
      _loadDepositData();
    }
  }

  Future<void> _loadDepositData() async {
    try {
      final results = await Future.wait<dynamic>([
        _walletApi!.getWalletSummary(),
        _walletApi!.getDepositWalletDetails(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _walletSummary = results[0] as WalletSummary;
        _walletDetails = results[1] as DepositWalletDetails;
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

  void _selectAmount(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  Future<void> _copyAddress() async {
    final l10n = context.l10n;
    final address = _walletDetails?.walletAddress ?? '';
    if (address.trim().isEmpty) {
      _showMessage(l10n.tr('Wallet address is not configured yet.'));
      return;
    }

    await Clipboard.setData(ClipboardData(text: address));
    _showMessage(l10n.tr('Wallet address copied to clipboard'));
  }

  Future<void> _confirmDeposit() async {
    final l10n = context.l10n;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final transactionId = _transactionIdController.text.trim();

    if (_walletSummary.pendingDeposits > 0) {
      _showMessage(
        l10n.tr(
          'You already have a pending deposit request. Please wait for admin approval or rejection before submitting a new one.',
        ),
      );
      return;
    }

    if (amount <= 0) {
      _showMessage(l10n.tr('Please enter a valid deposit amount'));
      return;
    }

    if (transactionId.isEmpty) {
      _showMessage(l10n.tr('Transaction ID is required.'));
      return;
    }

    if (_paymentScreenshot == null) {
      _showMessage(l10n.tr('Please upload payment proof screenshot'));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _walletApi!.createDeposit(
        amount: amount,
        paymentProof: _paymentScreenshot!,
        transactionRef: transactionId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        l10n.tr(
          'Deposit request #{id} submitted successfully for review.',
          params: <String, String>{'id': result.id},
        ),
      );

      setState(() {
        _amountController.clear();
        _transactionIdController.clear();
        _paymentScreenshot = null;
      });

      await _loadDepositData();
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

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _pickPaymentScreenshot() async {
    final l10n = context.l10n;

    setState(() {
      _isPickingProof = true;
    });

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (!mounted) {
        return;
      }

      if (picked == null) {
        _showMessage(l10n.tr('Screenshot selection cancelled'));
        return;
      }

      setState(() {
        _paymentScreenshot = picked;
      });
      _showMessage(l10n.tr('Payment proof selected'));
    } finally {
      if (mounted) {
        setState(() {
          _isPickingProof = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPendingDeposit = _walletSummary.pendingDeposits > 0;
    // USDT (TRC20)
    final currency = (_walletDetails?.currency ?? 'USDT').trim();
    final network = (_walletDetails?.network ?? '').trim();
    final walletTitle = network.isNotEmpty ? '$currency ($network)' : currency;

    final walletAddress = (_walletDetails?.walletAddress ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Deposit Funds')),
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
                  l10n.tr('CURRENT BALANCE'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currencyFormatter.format(_walletSummary.balance),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatusPill(
                        title: l10n.tr('Pending Deposits'),
                        value: _currencyFormatter.format(
                          _walletSummary.pendingDeposits,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatusPill(
                        title: l10n.tr('Pending Withdrawals'),
                        value: _currencyFormatter.format(
                          _walletSummary.pendingWithdrawals,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasPendingDeposit) ...[
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
                        'Pending deposit request detected. New deposit requests are disabled until the current one is reviewed.',
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
          Text(
            l10n.tr('Deposit Amount'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  r'$',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              hintText: l10n.tr('0.00'),
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
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.tr('Quick Amounts'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AmountChip(value: 100, onTap: () => _selectAmount(100)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountChip(value: 500, onTap: () => _selectAmount(500)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountChip(
                  value: 1000,
                  onTap: () => _selectAmount(1000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('Deposit & Referral Reward Rules'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tr(
                    'Standard deposit reward: 6% (example: \$500 -> \$30, \$1000 -> \$60, \$2000 -> \$120).',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tr(
                    'If the deposit is from an invited user: inviter gets 6%, invited user gets 3%.',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.tr('Transaction ID'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transactionIdController,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: l10n.tr('Enter transaction ID'),
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
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('PAYMENT PROOF'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _paymentScreenshot == null
                      ? l10n.tr(
                          'Upload a screenshot of your payment transaction.',
                        )
                      : l10n.tr(
                          'Selected file: {name}',
                          params: <String, String>{
                            'name': _paymentScreenshot!.name,
                          },
                        ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  text: _isPickingProof
                      ? l10n.tr('Selecting...')
                      : _paymentScreenshot == null
                      ? l10n.tr('Upload Screenshot')
                      : l10n.tr('Change Screenshot'),
                  onPressed: (_isPickingProof || _isSubmitting || _isLoading)
                      ? null
                      : _pickPaymentScreenshot,
                  icon: Icons.image_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.tr(
                          'Deposit {walletTitle}',
                          params: <String, String>{'walletTitle': walletTitle},
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _buildQrCodeWidget(),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.tr('WALLET ADDRESS'),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          walletAddress.isEmpty
                              ? l10n.tr('Wallet address not configured yet.')
                              : walletAddress,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: walletAddress.isEmpty ? null : _copyAddress,
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: AppColors.primaryBright,
                        ),
                      ),
                    ],
                  ),
                ),
                if ((_walletDetails?.instructions ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _walletDetails!.instructions!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryBright,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.tr(
                      'Deposits are queued for admin approval. Transaction ID is required for verification.',
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
          const SizedBox(height: 20),
          PrimaryButton(
            text: _isSubmitting
                ? l10n.tr('Submitting...')
                : l10n.tr('Submit Deposit Request'),
            onPressed:
                _isSubmitting ||
                    _isLoading ||
                    _isPickingProof ||
                    hasPendingDeposit
                ? null
                : _confirmDeposit,
            icon: _isSubmitting
                ? Icons.hourglass_bottom_rounded
                : Icons.send_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeWidget() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final qrCodeUrl = _walletDetails?.qrCodeUrl;
    if (qrCodeUrl == null || qrCodeUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.qr_code_2_rounded,
          size: 92,
          color: AppColors.background,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        qrCodeUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
          );
        },
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.value, required this.onTap});

  final double value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Center(
          child: Text(
            '\$${value.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.primaryBright,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
