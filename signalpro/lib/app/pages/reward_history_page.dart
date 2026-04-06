import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/services/wallet_api.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class RewardHistoryPage extends StatefulWidget {
  const RewardHistoryPage({super.key});

  @override
  State<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends State<RewardHistoryPage> {
  static const Set<String> _supportedTypes = <String>{
    'team_profit',
    'deposit_reward',
    'referral_reward',
    'referral_bonus',
  };

  WalletApi? _walletApi;
  Future<List<WalletTransactionRecord>>? _future;

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

  Future<List<WalletTransactionRecord>> _loadHistory() async {
    final allTransactions = await _walletApi!.getTransactions(limit: 200);
    final filtered =
        allTransactions
            .where((item) => _supportedTypes.contains(item.type))
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('Rewards & Team Profit History')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<WalletTransactionRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : l10n.tr('Unable to load rewards history.');
            return _HistoryErrorState(message: message, onRetry: _refresh);
          }

          final items = snapshot.data ?? const <WalletTransactionRecord>[];
          final totalAmount = items.fold<double>(
            0,
            (sum, item) => sum + item.amount,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('REWARDS ANALYTICS'),
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currencyFormatter.format(totalAmount),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.tr('Total rewards and team profit credits'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  EmptyStateIllustration(
                    title: l10n.tr('No Rewards Records'),
                    subtitle: l10n.tr(
                      'Reward and team profit transactions will appear here.',
                    ),
                    icon: Icons.card_giftcard_rounded,
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RewardHistoryCard(
                        item: item,
                        amountText: _currencyFormatter.format(item.amount),
                        createdText: _dateFormatter.format(item.createdAt),
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

class _RewardHistoryCard extends StatelessWidget {
  const _RewardHistoryCard({
    required this.item,
    required this.amountText,
    required this.createdText,
  });

  final WalletTransactionRecord item;
  final String amountText;
  final String createdText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel = item.status.trim().isEmpty
        ? l10n.tr('Completed')
        : item.status.toUpperCase();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _typeLabel(item.type, l10n),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusBadge(label: statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr(
              'Type: {value}',
              params: <String, String>{'value': item.type.toUpperCase()},
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tr(
              'Date & Time: {value}',
              params: <String, String>{'value': createdText},
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if ((item.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.description!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
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
              const SizedBox(height: 10),
              Text(
                l10n.tr('Unable to load rewards history'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              PrimaryButton(text: l10n.tr('Retry'), onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

String _typeLabel(String type, AppLocalizations l10n) {
  switch (type.toLowerCase()) {
    case 'team_profit':
      return l10n.tr('Team Profit Credit');
    case 'deposit_reward':
      return l10n.tr('Deposit Reward Credit');
    case 'referral_reward':
    case 'referral_bonus':
      return l10n.tr('Referral Reward Credit');
    default:
      return l10n.tr('Reward Credit');
  }
}
