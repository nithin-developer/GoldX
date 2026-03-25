import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/section_header.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _chip('BTC', true),
            _chip('ETH', false),
            _chip('SOL', false),
            _chip('AVAX', false),
          ],
        ),
        const SizedBox(height: 12),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BTC / USDT', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 8),
              Text('\$68,432.12', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700)),
              Text('\$68,432.12 USD', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Candlestick Chart'),
        const SizedBox(height: 8),
        const GlassCard(
          child: SizedBox(height: 220, child: _CandleChart()),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Live Prices', actionText: 'View All'),
        const SizedBox(height: 8),
        const GlassCard(
          child: Column(
            children: [
              _PriceRow(asset: 'ETH', pair: 'ETHEREUM', price: '\$3,451.90', change: '-1.24%'),
              SizedBox(height: 10),
              _PriceRow(asset: 'SOL', pair: 'SOLANA', price: '\$145.22', change: '+6.32%'),
              SizedBox(height: 10),
              _PriceRow(asset: 'XRP', pair: 'RIPPLE', price: '\$0.68', change: '+0.92%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.28) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryBright : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CandleChart extends StatelessWidget {
  const _CandleChart();

  @override
  Widget build(BuildContext context) {
    const bars = [88.0, 62.0, 120.0, 96.0, 76.0, 132.0, 82.0, 116.0];
    const positive = [false, true, false, true, true, false, true, true];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(bars.length, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(width: 1.6, height: bars[index] + 18, color: AppColors.textMuted),
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: bars[index],
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: positive[index] ? const Color(0xFF4ADEB8) : const Color(0xFFF4A3A3),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.asset,
    required this.pair,
    required this.price,
    required this.change,
  });

  final String asset;
  final String pair;
  final String price;
  final String change;

  @override
  Widget build(BuildContext context) {
    final positive = change.startsWith('+');
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.currency_bitcoin_rounded, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(asset, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(pair, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 10),
        Text(
          change,
          style: TextStyle(
            color: positive ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
