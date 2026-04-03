import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class WithdrawalDetailPage extends StatefulWidget {
  const WithdrawalDetailPage({
    required this.withdrawalId,
    this.initialRecord,
    super.key,
  });

  final String withdrawalId;
  final WithdrawalHistoryRecord? initialRecord;

  @override
  State<WithdrawalDetailPage> createState() => _WithdrawalDetailPageState();
}

class _WithdrawalDetailPageState extends State<WithdrawalDetailPage> {
  WalletApi? _walletApi;
  Future<WithdrawalHistoryRecord>? _future;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletApi ??= WalletApi(dio: AuthScope.of(context).apiClient.dio);
    _future ??= _walletApi!.getWithdrawalDetails(widget.withdrawalId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _walletApi!.getWithdrawalDetails(widget.withdrawalId);
    });

    final pending = _future;
    if (pending != null) {
      await pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<WithdrawalHistoryRecord>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null &&
              widget.initialRecord == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && widget.initialRecord == null) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Unable to load withdrawal details.';
            return _DetailErrorState(message: message, onRetry: _refresh);
          }

          final record = snapshot.data ?? widget.initialRecord;
          if (record == null) {
            return const Center(child: Text('No details found.'));
          }

          final status = _statusVisual(record.status);
          final hasReviewDate = _hasMeaningfulUpdate(
            record.createdAt,
            record.updatedAt,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (snapshot.hasError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Showing the latest cached details. Pull to refresh again.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: status.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(status.icon, color: status.foreground),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Withdrawal Transaction',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _StatusBadge(visual: status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _currencyFormatter.format(record.amount),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Submitted ${_dateFormatter.format(record.createdAt)}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: 'Withdrawal ID', value: record.id),
                      _DetailRow(
                        label: 'Requested At',
                        value: _dateFormatter.format(record.createdAt),
                      ),
                      _DetailRow(
                        label: 'Last Updated',
                        value: hasReviewDate
                            ? _dateFormatter.format(record.updatedAt!.toLocal())
                            : 'Pending review',
                      ),
                      _DetailRow(
                        label: 'Destination',
                        value: record.walletAddress?.isNotEmpty == true
                            ? record.walletAddress!
                            : 'Not provided',
                      ),
                      _DetailRow(
                        label: 'Admin Note',
                        value: record.adminNote?.isNotEmpty == true
                            ? record.adminNote!
                            : 'No admin note yet',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: status.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          status.icon,
                          color: status.foreground,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusDescription(record.status),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.message, required this.onRetry});

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
              const SizedBox(height: 8),
              const Text(
                'Unable to load details',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
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

String _statusDescription(String status) {
  switch (status) {
    case 'approved':
      return 'This withdrawal has been approved and processed by admin.';
    case 'rejected':
      return 'This withdrawal was rejected. Review the admin note and verify destination details before retrying.';
    case 'pending':
      return 'Your withdrawal is pending admin review. Processing times can vary based on queue volume.';
    default:
      return 'Status is currently unavailable for this record.';
  }
}

bool _hasMeaningfulUpdate(DateTime createdAt, DateTime? updatedAt) {
  if (updatedAt == null) {
    return false;
  }

  final diff = updatedAt.difference(createdAt).inSeconds.abs();
  return diff >= 1;
}
