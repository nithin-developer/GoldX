import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class DepositPage extends StatelessWidget {
  const DepositPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SignalPro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _panel(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT BALANCE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.2)),
                SizedBox(height: 8),
                Text('\$12,450.80', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Deposit Amount', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              prefixText: '\$ ',
              hintText: '0.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: _AmountChip(value: '+\$100')),
              SizedBox(width: 8),
              Expanded(child: _AmountChip(value: '+\$500')),
              SizedBox(width: 8),
              Expanded(child: _AmountChip(value: '+\$1,000')),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _method(label: 'Crypto', active: true, icon: Icons.currency_bitcoin_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _method(label: 'Bank Transfer', active: false, icon: Icons.account_balance_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Deposit USDT (ERC20)', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.qr_code_2_rounded, size: 72, color: AppColors.background),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('WALLET ADDRESS', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Expanded(child: Text('0x71C7656EC7ab88b098defB751B7401B5f6d8976F', overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 8),
                      Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryBright),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(text: 'Confirm Deposit', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _method({required String label, required bool active, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: active ? AppColors.surfaceSoft : AppColors.surface,
        border: Border.all(color: active ? AppColors.primary : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: active ? AppColors.primaryBright : AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(value, style: const TextStyle(color: AppColors.primaryBright, fontWeight: FontWeight.w600))),
    );
  }
}
