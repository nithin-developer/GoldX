import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _transactionIdController = TextEditingController();

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
    final address = _walletDetails?.walletAddress ?? '';
    if (address.trim().isEmpty) {
      _showMessage('Wallet address is not configured yet.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: address));
    _showMessage('Wallet address copied to clipboard');
  }

  Future<void> _confirmDeposit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showMessage('Please enter a valid deposit amount');
      return;
    }

    if (_paymentScreenshot == null) {
      _showMessage('Please upload payment proof screenshot');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _walletApi!.createDeposit(
        amount: amount,
        paymentProof: _paymentScreenshot!,
        transactionRef: _transactionIdController.text,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Deposit request #${result.id} submitted successfully for review.',
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
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickPaymentScreenshot() async {
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
        _showMessage('Screenshot selection cancelled');
        return;
      }

      setState(() {
        _paymentScreenshot = picked;
      });
      _showMessage('Payment proof selected');
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
    // USDT (TRC20)
    final currency = (_walletDetails?.currency ?? 'USDT').trim();
    final network = (_walletDetails?.network ?? '').trim();
    final walletTitle = network.isNotEmpty ? '$currency ($network)' : currency;

    final walletAddress = (_walletDetails?.walletAddress ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Funds'),
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
                  'CURRENT BALANCE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currencyFormatter.format(_walletSummary.balance),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatusPill(
                        title: 'Pending Deposits',
                        value: _currencyFormatter.format(_walletSummary.pendingDeposits),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatusPill(
                        title: 'Pending Withdrawals',
                        value: _currencyFormatter.format(_walletSummary.pendingWithdrawals),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Deposit Amount',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: '0.00',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick Amounts',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _AmountChip(value: 100, onTap: () => _selectAmount(100))),
              const SizedBox(width: 8),
              Expanded(child: _AmountChip(value: 500, onTap: () => _selectAmount(500))),
              const SizedBox(width: 8),
              Expanded(child: _AmountChip(value: 1000, onTap: () => _selectAmount(1000))),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Transaction Reference (Optional)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transactionIdController,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: 'Enter transaction ID if available',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAYMENT PROOF',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _paymentScreenshot == null
                      ? 'Upload a screenshot of your payment transaction.'
                      : 'Selected file: ${_paymentScreenshot!.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  text: _isPickingProof
                      ? 'Selecting...'
                      : _paymentScreenshot == null
                      ? 'Upload Screenshot'
                      : 'Change Screenshot',
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
                        'Deposit $walletTitle',
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
                const Text(
                  'WALLET ADDRESS',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          walletAddress.isEmpty ? 'Wallet address not configured yet.' : walletAddress,
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
              children: const [
                Icon(Icons.info_outline_rounded, color: AppColors.primaryBright, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deposits are queued for admin approval. Add transaction reference to speed up verification.',
                    style: TextStyle(
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
            text: _isSubmitting ? 'Submitting...' : 'Submit Deposit Request',
            onPressed: _isSubmitting || _isLoading || _isPickingProof
                ? null
                : _confirmDeposit,
            icon: _isSubmitting ? Icons.hourglass_bottom_rounded : Icons.send_rounded,
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
