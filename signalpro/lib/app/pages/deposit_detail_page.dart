import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class DepositDetailPage extends StatefulWidget {
  const DepositDetailPage({
    required this.depositId,
    this.initialRecord,
    super.key,
  });

  final String depositId;
  final DepositHistoryRecord? initialRecord;

  @override
  State<DepositDetailPage> createState() => _DepositDetailPageState();
}

class _DepositDetailPageState extends State<DepositDetailPage> {
  WalletApi? _walletApi;
  Future<DepositHistoryRecord>? _future;

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _walletApi ??= WalletApi(dio: AuthScope.of(context).apiClient.dio);
    _future ??= _walletApi!.getDepositDetails(widget.depositId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _walletApi!.getDepositDetails(widget.depositId);
    });

    final pending = _future;
    if (pending != null) {
      await pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Deposit Details')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<DepositHistoryRecord>(
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
                : l10n.tr('Unable to load deposit details.');
            return _DetailErrorState(message: message, onRetry: _refresh);
          }

          final record = snapshot.data ?? widget.initialRecord;
          if (record == null) {
            return Center(child: Text(l10n.tr('No details found.')));
          }

          final status = _statusVisual(record.status, l10n);
          final hasProofUrl = record.paymentProofUrl?.isNotEmpty == true;
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
                    child: Text(
                      l10n.tr(
                        'Showing the latest cached details. Pull to refresh again.',
                      ),
                      style: const TextStyle(
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
                          Expanded(
                            child: Text(
                              l10n.tr('Deposit Transaction'),
                              style: const TextStyle(
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
                        l10n.tr(
                          'Submitted {date}',
                          params: <String, String>{
                            'date': _dateFormatter.format(record.createdAt),
                          },
                        ),
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
                      Text(
                        l10n.tr('DETAILS'),
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(label: l10n.tr('Deposit ID'), value: record.id),
                      _DetailRow(
                        label: l10n.tr('Requested At'),
                        value: _dateFormatter.format(record.createdAt),
                      ),
                      _DetailRow(
                        label: l10n.tr('Last Updated'),
                        value: hasReviewDate
                            ? _dateFormatter.format(record.updatedAt!.toLocal())
                            : l10n.tr('Pending review'),
                      ),
                      _DetailRow(
                        label: l10n.tr('Transaction ID'),
                        value: record.transactionRef?.isNotEmpty == true
                            ? record.transactionRef!
                            : l10n.tr('Not provided'),
                      ),
                      _DetailRow(
                        label: l10n.tr('Type'),
                        value: record.transactionType.toUpperCase(),
                      ),
                      _DetailRow(
                        label: l10n.tr('Self Reward'),
                        value: _currencyFormatter.format(record.selfRewardAmount),
                      ),
                      _DetailRow(
                        label: l10n.tr('Referrer Reward'),
                        value: _currencyFormatter.format(record.referrerRewardAmount),
                      ),
                      _DetailRow(
                        label: l10n.tr('Admin Note'),
                        value: record.adminNote?.isNotEmpty == true
                            ? record.adminNote!
                            : l10n.tr('No admin note yet'),
                      ),
                    ],
                  ),
                ),
                if (hasProofUrl) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tr('PAYMENT PROOF'),
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: Image.network(
                              record.paymentProofUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) {
                                  return child;
                                }

                                final expected = progress.expectedTotalBytes;
                                final loaded = progress.cumulativeBytesLoaded;
                                final value = expected == null || expected == 0
                                    ? null
                                    : loaded / expected;

                                return Container(
                                  color: AppColors.surfaceSoft,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                    value: value,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.surfaceSoft,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.broken_image_outlined,
                                        color: AppColors.textMuted,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.tr('Unable to load proof image'),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          _statusDescription(record.status, l10n),
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
    final l10n = context.l10n;

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
              Text(
                l10n.tr('Unable to load details'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              PrimaryButton(text: l10n.tr('Retry'), onPressed: onRetry),
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

_StatusVisual _statusVisual(String status, AppLocalizations l10n) {
  switch (status) {
    case 'approved':
      return _StatusVisual(
        label: l10n.tr('Approved'),
        icon: Icons.verified_rounded,
        background: Color(0x1F22C55E),
        foreground: AppColors.success,
      );
    case 'rejected':
      return _StatusVisual(
        label: l10n.tr('Rejected'),
        icon: Icons.cancel_rounded,
        background: Color(0x1FEF4444),
        foreground: AppColors.danger,
      );
    case 'pending':
      return _StatusVisual(
        label: l10n.tr('Pending'),
        icon: Icons.schedule_rounded,
        background: Color(0x1FB45309),
        foreground: Color(0xFFB45309),
      );
    default:
      return _StatusVisual(
        label: l10n.tr('Unknown'),
        icon: Icons.help_outline_rounded,
        background: Color(0x1F4A5568),
        foreground: AppColors.textSecondary,
      );
  }
}

String _statusDescription(String status, AppLocalizations l10n) {
  switch (status) {
    case 'approved':
      return l10n.tr(
        'This deposit has been approved and should be reflected in your wallet balance.',
      );
    case 'rejected':
      return l10n.tr(
        'This deposit was rejected by admin. Check the admin note for context and resubmit if needed.',
      );
    case 'pending':
      return l10n.tr(
        'Your deposit request is under review. Approval usually depends on payment proof validation.',
      );
    default:
      return l10n.tr('Status is currently unavailable for this record.');
  }
}

bool _hasMeaningfulUpdate(DateTime createdAt, DateTime? updatedAt) {
  if (updatedAt == null) {
    return false;
  }

  final diff = updatedAt.difference(createdAt).inSeconds.abs();
  return diff >= 1;
}
