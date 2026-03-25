import 'package:flutter/material.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/section_header.dart';

class ReferralsPage extends StatelessWidget {
  const ReferralsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Invite & Earn', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
        SizedBox(height: 6),
        Text('Affiliate Portal', style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Progress to Gold Partner')),
                  Chip(label: Text('LEVEL 2 VIP')),
                ],
              ),
              SizedBox(height: 8),
              Text('7 / 10 Referrals', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.7,
                minHeight: 8,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(height: 8),
              Text('Next reward: 5% bonus commission', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(title: 'Total Referrals', value: '124')),
            SizedBox(width: 10),
            Expanded(child: _StatCard(title: 'Earned', value: '\$2,410')),
          ],
        ),
        SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite Code', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 8),
              Text('SIGNAL-X922', style: TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Text('Invite Link', style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 6),
              Text('signalpro.app/join/ref/x922'),
            ],
          ),
        ),
        SizedBox(height: 16),
        SectionHeader(title: 'Recent Activity', actionText: 'View All'),
        SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              _ReferralRow(name: 'Alex Thompson', amount: '+\$12.50'),
              SizedBox(height: 10),
              _ReferralRow(name: 'Sarah Miller', amount: '+\$12.50'),
              SizedBox(height: 10),
              _ReferralRow(name: 'Marcus Chen', amount: '\$0.00'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReferralRow extends StatelessWidget {
  const _ReferralRow({required this.name, required this.amount});

  final String name;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.surfaceSoft,
          child: Icon(Icons.person, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text(
          amount,
          style: TextStyle(
            color: amount.startsWith('+') ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
