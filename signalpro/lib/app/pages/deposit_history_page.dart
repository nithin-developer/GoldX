import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/pages/deposit_detail_page.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class DepositHistoryPage extends StatefulWidget {
  const DepositHistoryPage({super.key});

  @override
  State<DepositHistoryPage> createState() => _DepositHistoryPageState();
}

class _DepositHistoryPageState extends State<DepositHistoryPage> {
  WalletApi? _walletApi;
  Future<List<DepositHistoryRecord>>? _future;
  String _statusFilter = 'all';

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletApi ??= WalletApi(dio: AuthScope.of(context).apiClient.dio);
    _future ??= _loadHistory();
  }

  Future<List<DepositHistoryRecord>> _loadHistory() {
    return _walletApi!.getDepositHistory(
      limit: 100,
      status: _statusFilter == 'all' ? null : _statusFilter,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadHistory();
    });

    final pending = _future;
    if (pending != null) {
      await pending;
    }
  }

  void _applyStatusFilter(String value) {
    if (value == _statusFilter) {
      return;
    }

    setState(() {
      _statusFilter = value;
      _future = _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<DepositHistoryRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Unable to load deposit history.';
            return _HistoryErrorState(message: message, onRetry: _refresh);
          }

          final items = snapshot.data ?? const <DepositHistoryRecord>[];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DepositHistorySummary(
                  entries: items,
                  currencyFormatter: _currencyFormatter,
                ),
                const SizedBox(height: 14),
                _StatusFilterRow(
                  selected: _statusFilter,
                  onSelected: _applyStatusFilter,
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  const EmptyStateIllustration(
                    title: 'No Deposit Records',
                    subtitle:
                        'Your deposit requests and approvals will appear here.',
                    icon: Icons.account_balance_wallet_outlined,
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DepositHistoryCard(
                        item: item,
                        amountText: _currencyFormatter.format(item.amount),
                        createdText: _dateFormatter.format(item.createdAt),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DepositDetailPage(
                                depositId: item.id,
                                initialRecord: item,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DepositHistorySummary extends StatelessWidget {
  const _DepositHistorySummary({
    required this.entries,
    required this.currencyFormatter,
  });

  final List<DepositHistoryRecord> entries;
  final NumberFormat currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final totalAmount = entries.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final pendingCount = entries
        .where((item) => item.status == 'pending')
        .length;
    final approvedCount = entries
        .where((item) => item.status == 'approved')
        .length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEPOSIT ANALYTICS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormatter.format(totalAmount),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total requested volume for this filter',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: 'Pending',
                  value: pendingCount.toString(),
                  color: const Color(0xFFB45309),
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: 'Approved',
                  value: approvedCount.toString(),
                  color: AppColors.success,
                  icon: Icons.verified_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = <MapEntry<String, String>>[
      MapEntry('all', 'All'),
      MapEntry('pending', 'Pending'),
      MapEntry('approved', 'Approved'),
      MapEntry('rejected', 'Rejected'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters
          .map(
            (entry) => _StatusFilterChip(
              label: entry.value,
              isSelected: selected == entry.key,
              onTap: () => onSelected(entry.key),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DepositHistoryCard extends StatelessWidget {
  const _DepositHistoryCard({
    required this.item,
    required this.amountText,
    required this.createdText,
    required this.onTap,
  });

  final DepositHistoryRecord item;
  final String amountText;
  final String createdText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusVisual(item.status);

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(status.icon, color: status.foreground, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Deposit Request',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(visual: status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            createdText,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.transactionRef?.isNotEmpty == true
                ? 'Ref: ${item.transactionRef}'
                : 'Ref: Not provided',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${item.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.visual});

  final _StatusVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        visual.label,
        style: TextStyle(
          color: visual.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 34,
              ),
              const SizedBox(height: 10),
              const Text(
                'Unable to load deposits',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              PrimaryButton(text: 'Retry', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}

_StatusVisual _statusVisual(String status) {
  switch (status) {
    case 'approved':
      return const _StatusVisual(
        label: 'Approved',
        icon: Icons.verified_rounded,
        background: Color(0x1F22C55E),
        foreground: AppColors.success,
      );
    case 'rejected':
      return const _StatusVisual(
        label: 'Rejected',
        icon: Icons.cancel_rounded,
        background: Color(0x1FEF4444),
        foreground: AppColors.danger,
      );
    case 'pending':
      return const _StatusVisual(
        label: 'Pending',
        icon: Icons.schedule_rounded,
        background: Color(0x1FB45309),
        foreground: Color(0xFFB45309),
      );
    default:
      return const _StatusVisual(
        label: 'Unknown',
        icon: Icons.help_outline_rounded,
        background: Color(0x1F4A5568),
        foreground: AppColors.textSecondary,
      );
  }
}
