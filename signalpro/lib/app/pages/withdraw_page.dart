import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class WithdrawPage extends StatelessWidget {
  const WithdrawPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AVAILABLE LIQUIDITY', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          const Text('\$42,890.42', style: TextStyle(fontSize: 40, color: AppColors.primaryBright, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: _MiniBalance(title: 'Trading Equity', value: '\$38,200')),
              SizedBox(width: 8),
              Expanded(child: _MiniBalance(title: 'Uncleared', value: '\$4,690', warn: true)),
            ],
          ),
          const SizedBox(height: 16),
          const _Field(label: 'WITHDRAWAL AMOUNT', hint: '0.00', prefix: '\$ '),
          const SizedBox(height: 10),
          const _Field(label: 'DESTINATION ADDRESS / IBAN', hint: 'Enter wallet or bank details'),
          const SizedBox(height: 10),
          const _Field(label: 'WITHDRAWAL PASSWORD', hint: '••••••••', suffix: Icons.lock_outline_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.tertiary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Standard processing time is 24-48 hours. Please ensure the destination address is accurate.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(text: 'Request Withdrawal', onPressed: () {}, icon: Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class _MiniBalance extends StatelessWidget {
  const _MiniBalance({required this.title, required this.value, this.warn = false});

  final String title;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: warn ? AppColors.tertiary : AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.hint, this.prefix, this.suffix});

  final String label;
  final String hint;
  final String? prefix;
  final IconData? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            prefixText: prefix,
            suffixIcon: suffix == null ? null : Icon(suffix, size: 18),
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
