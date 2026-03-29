import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/models/app_notification.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  AppDataApi? _api;
  Future<List<AppNotification>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _api ??= AppDataApi(dio: AuthScope.of(context).apiClient.dio);
    _future ??= _loadAndMarkRead();
  }

  Future<List<AppNotification>> _loadAndMarkRead({bool forceRefresh = false}) async {
    final notifications = await _api!.getNotifications(forceRefresh: forceRefresh);
    final hasUnread = notifications.any((item) => item.isUnread);

    if (!hasUnread) {
      return notifications;
    }

    try {
      await _api!.markNotificationsRead(markAll: true);
      return notifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
    } on ApiException {
      // Keep showing fetched notifications even if mark-read request fails.
      return notifications;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadAndMarkRead(forceRefresh: true);
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
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Unable to load notifications right now.';
            return _ErrorState(message: message, onRetry: _refresh);
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: const [
                  EmptyStateIllustration(
                    title: 'No Notifications Yet',
                    subtitle: 'Admin updates and alerts will appear here.',
                    icon: Icons.notifications_off_outlined,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.primaryBright,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Notification Center',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'All unseen messages are automatically marked as read.',
                                style: TextStyle(
                                  fontSize: 12,
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

                final item = notifications[index - 1];
                return _NotificationCard(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM yyyy • hh:mm a').format(item.createdAt.toLocal());

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _typeColor(item.type).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _typeIcon(item.type),
              size: 18,
              color: _typeColor(item.type),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypePill(type: item.type),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 8),
                Text(
                  dateText,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'signal':
        return Icons.show_chart_rounded;
      case 'referral':
        return Icons.people_alt_outlined;
      case 'support':
        return Icons.support_agent_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'signal':
        return AppColors.primaryBright;
      case 'referral':
        return AppColors.success;
      case 'support':
        return AppColors.tertiary;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        color: AppColors.surfaceSoft,
      ),
      child: Text(
        _label(type),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _label(String value) {
    switch (value) {
      case 'signal':
        return 'SIGNAL';
      case 'referral':
        return 'REFERRAL';
      case 'support':
        return 'SUPPORT';
      default:
        return 'SYSTEM';
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 34),
              const SizedBox(height: 8),
              const Text('Unable to load notifications', style: TextStyle(fontWeight: FontWeight.w700)),
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
