import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signalpro/app/localization/app_localizations.dart';
import 'package:signalpro/app/models/signal_feed_item.dart';
import 'package:signalpro/app/models/signal_history_item.dart';
import 'package:signalpro/app/services/api_exception.dart';
import 'package:signalpro/app/services/app_data_api.dart';
import 'package:signalpro/app/services/auth_scope.dart';
import 'package:signalpro/app/theme/app_colors.dart';
import 'package:signalpro/app/widgets/empty_state_illustration.dart';
import 'package:signalpro/app/widgets/glass_card.dart';
import 'package:signalpro/app/widgets/primary_button.dart';

enum _SignalTab { active, past }

class SignalsPage extends StatefulWidget {
  const SignalsPage({super.key});

  @override
  State<SignalsPage> createState() => _SignalsPageState();
}

class _SignalsPageState extends State<SignalsPage> {
  static const int _pageSize = 10;

  AppDataApi? _api;
  _SignalTab? _selectedTab;
  Timer? _expiryTicker;

  Future<List<SignalFeedItem>>? _activeSignalsFuture;
  Future<List<SignalHistoryItem>>? _historySignalsFuture;

  List<SignalFeedItem>? _cachedActiveSignals;
  List<SignalHistoryItem>? _cachedHistorySignals;

  int _activeSkip = 0;
  bool _activeHasMore = true;
  bool _isLoadingMoreActive = false;

  int _historySkip = 0;
  bool _historyHasMore = true;
  bool _isLoadingMoreHistory = false;

  _SignalTab get _currentTab => _selectedTab ?? _SignalTab.active;

  List<SignalFeedItem> get _activeCache =>
      _cachedActiveSignals ?? const <SignalFeedItem>[];

  List<SignalHistoryItem> get _historyCache =>
      _cachedHistorySignals ?? const <SignalHistoryItem>[];

  bool _isSignalActive(SignalFeedItem signal, {DateTime? at}) {
    final referenceTime = at ?? DateTime.now();
    return signal.status.toLowerCase() == 'active' &&
        !signal.hasExpired(at: referenceTime);
  }

  bool _isPastHistoryEntry(SignalHistoryItem entry, {DateTime? at}) {
    final referenceTime = at ?? DateTime.now();
    final hasEnded = !referenceTime.isBefore(entry.endsAt);
    return !entry.isActive || entry.isExpired || hasEnded;
  }

  @override
  void initState() {
    super.initState();
    _selectedTab ??= _SignalTab.active;
    _cachedActiveSignals ??= const <SignalFeedItem>[];
    _cachedHistorySignals ??= const <SignalHistoryItem>[];
    _expiryTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _expiryTicker?.cancel();
    super.dispose();
  }

  Future<void> _openActivationModal(SignalFeedItem signal) async {
    if (_api == null || signal.id.isEmpty) {
      return;
    }

    final l10n = context.l10n;
    if (signal.alreadyActivated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.tr('Already Activated'))));
      return;
    }

    final isVipUser = (AuthScope.of(context).currentUser?.vipLevel ?? 0) > 0;
    if (signal.vipOnly && !isVipUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tr('This signal is available for VIP users only')),
        ),
      );
      return;
    }

    final codeController = TextEditingController();
    String? inlineError;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                setDialogState(() {
                  inlineError = l10n.tr('Activation code is required');
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                inlineError = null;
              });

              try {
                await _api!.activateSignal(signalCode: code);
                if (!mounted) {
                  return;
                }

                _refreshAfterActivation();
                Navigator.of(this.context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.tr('Signal activated successfully.')),
                  ),
                );
              } on ApiException catch (error) {
                if (!mounted) {
                  return;
                }

                setDialogState(() {
                  isSubmitting = false;
                  inlineError = error.message;
                });

                final normalizedMessage = error.message.toLowerCase();
                final isWalletWarning =
                    normalizedMessage.contains('minimum') ||
                    normalizedMessage.contains('insufficient') ||
                    normalizedMessage.contains('wallet balance');

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(error.message),
                    backgroundColor: isWalletWarning
                        ? Colors.orange.shade800
                        : null,
                  ),
                );
              } catch (_) {
                if (!mounted) {
                  return;
                }

                final localizedFallback = l10n.tr(
                  'Unable to activate signal. Please try again.',
                );
                setDialogState(() {
                  isSubmitting = false;
                  inlineError = localizedFallback;
                });

                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text(localizedFallback)));
              }
            }

            return AlertDialog(
              title: Text(
                l10n.tr(
                  'Activate {asset}',
                  params: <String, String>{'asset': signal.asset},
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tr(
                      'Enter your activation code to continue with {asset}.',
                      params: <String, String>{'asset': signal.asset},
                    ),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    enabled: !isSubmitting,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: l10n.tr('Enter activation code'),
                      errorText: inlineError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(this.context).pop(),
                  child: Text(l10n.tr('Cancel')),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(
                    isSubmitting
                        ? l10n.tr('Validating...')
                        : l10n.tr('Activate Signal'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = _api ?? AppDataApi(dio: AuthScope.of(context).apiClient.dio);
    _api = api;

    _activeSignalsFuture ??= _loadActiveSignals(reset: true);
    _historySignalsFuture ??= _loadHistorySignals(reset: true);
  }

  Future<List<SignalFeedItem>> _loadActiveSignals({required bool reset}) async {
    final api = _api;
    if (api == null) {
      return _activeCache;
    }

    final requestSkip = reset ? 0 : _activeSkip;
    final fetched = await api.getSignals(
      forceRefresh: reset,
      skip: requestSkip,
      limit: _pageSize,
      includeAllStatuses: true,
    );
    final referenceTime = DateTime.now();

    final nextSignals = fetched
        .where((signal) => _isSignalActive(signal, at: referenceTime))
        .toList(growable: false);

    final merged = reset
        ? <SignalFeedItem>[]
        : List<SignalFeedItem>.from(_activeCache);
    final seenIds = merged
        .where((item) => item.id.isNotEmpty)
        .map((item) => item.id)
        .toSet();

    for (final signal in nextSignals) {
      if (signal.id.isEmpty || seenIds.add(signal.id)) {
        merged.add(signal);
      }
    }

    _cachedActiveSignals = merged;
    _activeSkip = requestSkip + fetched.length;
    _activeHasMore = fetched.length == _pageSize;
    return merged;
  }

  Future<List<SignalHistoryItem>> _loadHistorySignals({
    required bool reset,
  }) async {
    final api = _api;
    if (api == null) {
      return _historyCache;
    }

    final requestSkip = reset ? 0 : _historySkip;
    final fetched = await api.getSignalHistory(
      forceRefresh: reset,
      skip: requestSkip,
      limit: _pageSize,
    );
    final referenceTime = DateTime.now();

    final nextEntries = fetched
        .where((entry) => _isPastHistoryEntry(entry, at: referenceTime))
        .toList(growable: false);

    final merged = reset
        ? <SignalHistoryItem>[]
        : List<SignalHistoryItem>.from(_historyCache);
    final seenIds = merged.map((entry) => entry.id).toSet();

    for (final entry in nextEntries) {
      if (seenIds.add(entry.id)) {
        merged.add(entry);
      }
    }

    _cachedHistorySignals = merged;
    _historySkip = requestSkip + fetched.length;
    _historyHasMore = fetched.length == _pageSize;
    return merged;
  }

  Future<void> _loadMoreActiveSignals() async {
    if (_api == null || _isLoadingMoreActive || !_activeHasMore) {
      return;
    }

    setState(() {
      _isLoadingMoreActive = true;
      _activeSignalsFuture = _loadActiveSignals(reset: false);
    });

    await _awaitSafely(_activeSignalsFuture);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingMoreActive = false;
    });
  }

  Future<void> _loadMoreHistorySignals() async {
    if (_api == null || _isLoadingMoreHistory || !_historyHasMore) {
      return;
    }

    setState(() {
      _isLoadingMoreHistory = true;
      _historySignalsFuture = _loadHistorySignals(reset: false);
    });

    await _awaitSafely(_historySignalsFuture);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingMoreHistory = false;
    });
  }

  Future<void> _awaitSafely<T>(Future<T>? future) async {
    if (future == null) {
      return;
    }

    try {
      await future;
    } catch (_) {
      // Errors are represented in FutureBuilder states.
    }
  }

  Future<void> _refreshActiveSignals() async {
    if (_api == null) {
      return;
    }

    setState(() {
      _activeSkip = 0;
      _activeHasMore = true;
      _isLoadingMoreActive = false;
      _activeSignalsFuture = _loadActiveSignals(reset: true);
    });

    await _awaitSafely(_activeSignalsFuture);
  }

  Future<void> _refreshHistorySignals() async {
    if (_api == null) {
      return;
    }

    setState(() {
      _historySkip = 0;
      _historyHasMore = true;
      _isLoadingMoreHistory = false;
      _historySignalsFuture = _loadHistorySignals(reset: true);
    });

    await _awaitSafely(_historySignalsFuture);
  }

  void _refreshAfterActivation() {
    if (!mounted || _api == null) {
      return;
    }

    setState(() {
      _activeSkip = 0;
      _activeHasMore = true;
      _isLoadingMoreActive = false;
      _activeSignalsFuture = _loadActiveSignals(reset: true);

      _historySkip = 0;
      _historyHasMore = true;
      _isLoadingMoreHistory = false;
      _historySignalsFuture = _loadHistorySignals(reset: true);
    });
  }

  void _onTabChanged(_SignalTab tab) {
    if (_currentTab == tab) {
      return;
    }

    setState(() {
      _selectedTab = tab;
    });
  }

  Widget _buildActiveSignalsTab() {
    final l10n = context.l10n;

    return FutureBuilder<List<SignalFeedItem>>(
      future: _activeSignalsFuture,
      builder: (context, snapshot) {
        final activeCache = _activeCache;
        final canUseCache = activeCache.isNotEmpty;

        if (snapshot.connectionState == ConnectionState.waiting) {
          if (canUseCache) {
            return _ActiveSignalsList(
              signals: activeCache,
              onActivateSignal: _openActivationModal,
              onRefresh: _refreshActiveSignals,
              onLoadMore: _loadMoreActiveSignals,
              hasMore: _activeHasMore,
              isLoadingMore: _isLoadingMoreActive,
              showRefreshingBanner: !_isLoadingMoreActive,
            );
          }

          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : l10n.tr('Failed to load active signals.');

          if (canUseCache) {
            return _ActiveSignalsList(
              signals: activeCache,
              onActivateSignal: _openActivationModal,
              onRefresh: _refreshActiveSignals,
              onLoadMore: _loadMoreActiveSignals,
              hasMore: _activeHasMore,
              isLoadingMore: _isLoadingMoreActive,
              topMessage: l10n.tr(
                'Showing cached signals. {message}',
                params: <String, String>{'message': message},
              ),
            );
          }

          return _ErrorState(
            title: l10n.tr('Unable to load active signals'),
            message: message,
            onRetry: _refreshActiveSignals,
          );
        }

        final referenceTime = DateTime.now();
        final signals = (snapshot.data ?? const <SignalFeedItem>[])
            .where((signal) => _isSignalActive(signal, at: referenceTime))
            .toList(growable: false);
        _cachedActiveSignals = signals;

        if (signals.isEmpty) {
          return _EmptyTabState(
            onRefresh: _refreshActiveSignals,
            title: l10n.tr('No Active Signals'),
            subtitle: l10n.tr(
              'No live signals are available right now. Pull to refresh.',
            ),
            icon: Icons.bolt_outlined,
          );
        }

        return _ActiveSignalsList(
          signals: signals,
          onActivateSignal: _openActivationModal,
          onRefresh: _refreshActiveSignals,
          onLoadMore: _loadMoreActiveSignals,
          hasMore: _activeHasMore,
          isLoadingMore: _isLoadingMoreActive,
        );
      },
    );
  }

  Widget _buildPastSignalsTab() {
    final l10n = context.l10n;

    return FutureBuilder<List<SignalHistoryItem>>(
      future: _historySignalsFuture,
      builder: (context, snapshot) {
        final referenceTime = DateTime.now();
        final cachedPastEntries = _historyCache
            .where((entry) => _isPastHistoryEntry(entry, at: referenceTime))
            .toList(growable: false);
        final canUseCache = cachedPastEntries.isNotEmpty;

        if (snapshot.connectionState == ConnectionState.waiting) {
          if (canUseCache) {
            return _PastSignalsList(
              entries: cachedPastEntries,
              onRefresh: _refreshHistorySignals,
              onLoadMore: _loadMoreHistorySignals,
              hasMore: _historyHasMore,
              isLoadingMore: _isLoadingMoreHistory,
              showRefreshingBanner: !_isLoadingMoreHistory,
            );
          }

          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final message = snapshot.error is ApiException
              ? (snapshot.error as ApiException).message
              : l10n.tr('Failed to load past signals.');

          if (canUseCache) {
            return _PastSignalsList(
              entries: cachedPastEntries,
              onRefresh: _refreshHistorySignals,
              onLoadMore: _loadMoreHistorySignals,
              hasMore: _historyHasMore,
              isLoadingMore: _isLoadingMoreHistory,
              topMessage: l10n.tr(
                'Showing cached history. {message}',
                params: <String, String>{'message': message},
              ),
            );
          }

          return _ErrorState(
            title: l10n.tr('Unable to load past signals'),
            message: message,
            onRetry: _refreshHistorySignals,
          );
        }

        final entries = snapshot.data ?? const <SignalHistoryItem>[];
        _cachedHistorySignals = entries;
        final pastEntries = entries
            .where((entry) => _isPastHistoryEntry(entry, at: referenceTime))
            .toList(growable: false);

        if (pastEntries.isEmpty) {
          return _EmptyTabState(
            onRefresh: _refreshHistorySignals,
            title: l10n.tr('No Activated Signal History Yet'),
            subtitle: l10n.tr(
              'Activated signals will appear here once you participate.',
            ),
            icon: Icons.history_rounded,
          );
        }

        return _PastSignalsList(
          entries: pastEntries,
          onRefresh: _refreshHistorySignals,
          onLoadMore: _loadMoreHistorySignals,
          hasMore: _historyHasMore,
          isLoadingMore: _isLoadingMoreHistory,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedTab = _currentTab;
    final subtitle = selectedTab == _SignalTab.active
        ? l10n.tr('Showing Active Signals')
        : l10n.tr('Showing Past Signals History');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _SignalsHeaderSection(
            subtitle: subtitle,
            selectedTab: selectedTab,
            onTabChanged: _onTabChanged,
          ),
        ),
        Expanded(
          child: RepaintBoundary(
            child: KeyedSubtree(
              key: ValueKey<_SignalTab>(selectedTab),
              child: selectedTab == _SignalTab.active
                  ? _buildActiveSignalsTab()
                  : _buildPastSignalsTab(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalsHeaderSection extends StatelessWidget {
  const _SignalsHeaderSection({
    required this.subtitle,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final String subtitle;
  final _SignalTab selectedTab;
  final ValueChanged<_SignalTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tr('Trading Signals'),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 18,
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: currentChild == null
                      ? previousChildren
                      : <Widget>[...previousChildren, currentChild],
                );
              },
              transitionBuilder: (child, animation) {
                final isIncoming = child.key == ValueKey<String>(subtitle);
                final slideAnimation = Tween<Offset>(
                  begin: isIncoming ? const Offset(0, 1) : const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation);

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                subtitle,
                key: ValueKey<String>(subtitle),
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SignalsTabSwitcher(
          selectedTab: selectedTab,
          onTabChanged: onTabChanged,
        ),
      ],
    );
  }
}

class _SignalsTabSwitcher extends StatelessWidget {
  const _SignalsTabSwitcher({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final _SignalTab selectedTab;
  final ValueChanged<_SignalTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final indicatorWidth = constraints.maxWidth / 2;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                start: selectedTab == _SignalTab.active ? 0 : indicatorWidth,
                top: 0,
                bottom: 0,
                width: indicatorWidth,
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.primary.withValues(alpha: 0.24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.95),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SignalsTabButton(
                      icon: Icons.bolt_rounded,
                      label: l10n.tr('Active Signals'),
                      selected: selectedTab == _SignalTab.active,
                      onTap: () => onTabChanged(_SignalTab.active),
                    ),
                  ),
                  Expanded(
                    child: _SignalsTabButton(
                      icon: Icons.history_rounded,
                      label: l10n.tr('Past Signals'),
                      selected: selectedTab == _SignalTab.past,
                      onTap: () => onTabChanged(_SignalTab.past),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SignalsTabButton extends StatelessWidget {
  const _SignalsTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final targetColor = selected
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: targetColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: targetColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSignalsList extends StatelessWidget {
  const _ActiveSignalsList({
    required this.signals,
    required this.onActivateSignal,
    required this.onRefresh,
    required this.onLoadMore,
    required this.hasMore,
    this.topMessage,
    this.showRefreshingBanner = false,
    this.isLoadingMore = false,
  });

  final List<SignalFeedItem> signals;
  final ValueChanged<SignalFeedItem> onActivateSignal;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final String? topMessage;
  final bool showRefreshingBanner;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasBanner = topMessage != null || showRefreshingBanner;
    final itemCount =
        signals.length + (hasBanner ? 1 : 0) + (isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (!hasMore || isLoadingMore) {
            return false;
          }

          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            onLoadMore();
          }

          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: itemCount,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (hasBanner && index == 0) {
              return _InlineNotice(
                message: topMessage ?? l10n.tr('Refreshing active signals...'),
                isError: topMessage != null,
              );
            }

            final signalIndex = index - (hasBanner ? 1 : 0);
            if (signalIndex >= signals.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              );
            }

            return _SignalCard(
              item: signals[signalIndex],
              onActivate: onActivateSignal,
            );
          },
        ),
      ),
    );
  }
}

class _PastSignalsList extends StatelessWidget {
  const _PastSignalsList({
    required this.entries,
    required this.onRefresh,
    required this.onLoadMore,
    required this.hasMore,
    this.topMessage,
    this.showRefreshingBanner = false,
    this.isLoadingMore = false,
  });

  final List<SignalHistoryItem> entries;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final String? topMessage;
  final bool showRefreshingBanner;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasBanner = topMessage != null || showRefreshingBanner;
    final itemCount =
        entries.length + (hasBanner ? 1 : 0) + (isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (!hasMore || isLoadingMore) {
            return false;
          }

          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 200) {
            onLoadMore();
          }

          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: itemCount,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (hasBanner && index == 0) {
              return _InlineNotice(
                message: topMessage ?? l10n.tr('Refreshing signal history...'),
                isError: topMessage != null,
              );
            }

            final historyIndex = index - (hasBanner ? 1 : 0);
            if (historyIndex >= entries.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              );
            }

            return _SignalHistoryCard(item: entries[historyIndex]);
          },
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.danger.withValues(alpha: 0.14)
            : AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.danger : AppColors.primary,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.info_outline_rounded : Icons.sync_rounded,
            size: 16,
            color: isError ? AppColors.danger : AppColors.primaryBright,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.item, required this.onActivate});

  final SignalFeedItem item;
  final ValueChanged<SignalFeedItem> onActivate;

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy • hh:mm a');
  static final NumberFormat _percentFormat = NumberFormat('0.##');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLong = item.direction.toLowerCase() == 'long';
    final isExpired = item.hasExpired();
    final isLive = item.isLive;
    final isVipUser = (AuthScope.of(context).currentUser?.vipLevel ?? 0) > 0;
    final isVipLocked = item.vipOnly && !isVipUser;
    final canActivate =
        !isExpired &&
        isLive &&
        item.id.isNotEmpty &&
        !isVipLocked &&
        !item.alreadyActivated;
    final directionColor = isLong ? AppColors.success : AppColors.danger;
    final statusColor = isExpired
        ? AppColors.danger
        : isLive
        ? AppColors.success
        : AppColors.textSecondary;
    final createdText = _dateFormat.format(item.createdAt.toLocal());

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: directionColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  isLong
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: directionColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.asset,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.tr(
                      'Created {date}',
                      params: <String, String>{'date': createdText},
                    ),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(
              text: isExpired
                  ? l10n.tr('EXPIRED')
                  : isLive
                  ? l10n.tr('LIVE NOW')
                  : item.status.toUpperCase(),
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SignalDetailPill(
              icon: isLong
                  ? Icons.north_east_rounded
                  : Icons.south_east_rounded,
              label: l10n.tr('Direction'),
              value: item.direction.toUpperCase(),
              valueColor: directionColor,
            ),
            _SignalDetailPill(
              icon: Icons.percent_rounded,
              label: l10n.tr('Expected Profit'),
              value: '${_percentFormat.format(item.profitPercent)}%',
              valueColor: directionColor,
            ),
            _SignalDetailPill(
              icon: Icons.schedule_rounded,
              label: l10n.tr('Duration'),
              value: item.durationLabel,
              valueColor: AppColors.textPrimary,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canActivate ? () => onActivate(item) : null,
            icon: const Icon(Icons.flash_on_rounded, size: 20),
            label: Text(
              canActivate
                  ? l10n.tr('Activate Signal')
                  : item.alreadyActivated
                  ? l10n.tr('Already Activated')
                  : isVipLocked
                  ? l10n.tr('VIP Only')
                  : isExpired
                  ? l10n.tr('Expired')
                  : l10n.tr('Activation Unavailable'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              disabledBackgroundColor: AppColors.surfaceSoft.withValues(
                alpha: 0.9,
              ),
              disabledForegroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );

    return GlassCard(
      onTap: canActivate ? () => onActivate(item) : null,
      borderColor: directionColor.withValues(alpha: 0.32),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: isVipLocked
          ? Stack(
              children: [
                IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: Opacity(opacity: 0.35, child: cardContent),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.36),
                    ),
                  ),
                ),
                const Positioned.fill(child: Center(child: _VipOnlyOverlay())),
              ],
            )
          : cardContent,
    );
  }
}

class _VipOnlyOverlay extends StatelessWidget {
  const _VipOnlyOverlay();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            l10n.tr('VIP Only'),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalDetailPill extends StatelessWidget {
  const _SignalDetailPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalHistoryCard extends StatelessWidget {
  const _SignalHistoryCard({required this.item});

  final SignalHistoryItem item;

  static final DateFormat _timeFormat = DateFormat('dd MMM yyyy • hh:mm a');
  static final NumberFormat _moneyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  static final NumberFormat _percentFormat = NumberFormat('0.##');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLong = item.direction.toLowerCase() == 'long';
    final directionColor = isLong ? AppColors.success : AppColors.danger;
    final statusColor = _statusColor(item.status);
    final startedText = _timeFormat.format(item.startedAt.toLocal());
    final endedText = _timeFormat.format(item.displayTime.toLocal());
    final profitText = item.profitAmount > 0
        ? '+${_moneyFormat.format(item.profitAmount)}'
        : _moneyFormat.format(item.profitAmount);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      borderColor: statusColor.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Icon(
                  isLong
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 20,
                  color: directionColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.asset,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.direction.toUpperCase(),
                      style: TextStyle(
                        color: directionColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(text: item.status.toUpperCase(), color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _HistoryMetricTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.tr('Entry Balance'),
                      value: _moneyFormat.format(item.entryBalance),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _HistoryMetricTile(
                      icon: Icons.pie_chart_outline_rounded,
                      label: l10n.tr('Participation'),
                      value: _moneyFormat.format(item.participationAmount),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _HistoryMetricTile(
                      icon: Icons.percent_rounded,
                      label: l10n.tr('Profit Rate'),
                      value: '${_percentFormat.format(item.profitPercent)}%',
                      valueColor: directionColor,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _HistoryMetricTile(
                      icon: Icons.trending_up_rounded,
                      label: l10n.tr('Profit Earned'),
                      value: profitText,
                      valueColor: item.profitAmount > 0
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.75),
              ),
            ),
            child: Column(
              children: [
                _InfoRow(label: l10n.tr('Started'), value: startedText),
                const SizedBox(height: 6),
                _InfoRow(
                  label: item.isCompleted
                      ? l10n.tr('Completed')
                      : l10n.tr('Ended'),
                  value: endedText,
                ),
                const SizedBox(height: 6),
                _InfoRow(label: l10n.tr('Duration'), value: item.durationLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'active':
        return AppColors.primary;
      case 'expired':
      case 'failed':
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _HistoryMetricTile extends StatelessWidget {
  const _HistoryMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.9)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({
    required this.onRefresh,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final Future<void> Function() onRefresh;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          EmptyStateIllustration(title: title, subtitle: subtitle, icon: icon),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
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
