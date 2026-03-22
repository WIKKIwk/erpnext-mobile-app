import 'dart:math' as math;

import '../../../app/app_router.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/notification_hidden_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/m3_confirm_dialog.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaNotificationsScreen extends StatefulWidget {
  const WerkaNotificationsScreen({super.key});

  @override
  State<WerkaNotificationsScreen> createState() =>
      _WerkaNotificationsScreenState();
}

class _WerkaNotificationsScreenState extends State<WerkaNotificationsScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'cache_werka_notifications';
  final ScrollController _scrollController = ScrollController();
  List<DispatchRecord>? _cachedItems;
  Set<String> _highlightedUnreadIds = <String>{};
  int _refreshVersion = 0;
  double _cardStretch = 0.0;
  double _cardPull = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WerkaStore.instance.bootstrapHistory();
    NotificationHiddenStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    _loadCache();
    WerkaStore.instance.addListener(_handleStoreChanged);
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  Future<void> _loadCache() async {
    final raw = await JsonCacheStore.instance.readList(_cacheKey);
    if (raw == null || !mounted) {
      return;
    }
    setState(() {
      _cachedItems = raw.map((item) => DispatchRecord.fromJson(item)).toList();
    });
  }

  Future<void> _clearAll() async {
    final current = WerkaStore.instance.historyItems;
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
      AppSession.instance.profile,
    );
    final visibleItems =
        current.where((item) => !hidden.contains(item.id)).toList();
    if (visibleItems.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.noNotifications)),
      );
      return;
    }

    final confirmed = await showM3ConfirmDialog(
      context: context,
      title: context.l10n.clearTitle,
      message: context.l10n.clearAllNotificationsPrompt,
      cancelLabel: context.l10n.no,
      confirmLabel: context.l10n.yes,
    );
    if (confirmed != true) {
      return;
    }
    await NotificationHiddenStore.instance.hideAll(
      profile: AppSession.instance.profile,
      ids: visibleItems.map((item) => item.id),
    );
    await NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: visibleItems.map((item) => item.id),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedUnreadIds.clear();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WerkaStore.instance.removeListener(_handleStoreChanged);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'werka') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  Future<void> _openDetail(String receiptId) async {
    await NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: [receiptId],
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedUnreadIds.remove(receiptId);
    });
    await Navigator.of(context).pushNamed(
      AppRoutes.notificationDetail,
      arguments: receiptId,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _syncFromStore() async {
    final items = WerkaStore.instance.historyItems;
    final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
      AppSession.instance.profile,
    );
    if (hidden.isNotEmpty) {
      await NotificationUnreadStore.instance.markSeen(
        profile: AppSession.instance.profile,
        ids: hidden,
      );
    }
    await NotificationUnreadStore.instance.retainForProfile(
      profile: AppSession.instance.profile,
      ids: items.map((item) => item.id),
    );
    final unread = NotificationUnreadStore.instance.unreadIdsForProfile(
      AppSession.instance.profile,
    );
    final highlighted =
        items.map((item) => item.id).where((id) => unread.contains(id)).toSet();
    if (mounted) {
      setState(() {
        _highlightedUnreadIds = highlighted;
      });
    }
    await JsonCacheStore.instance.writeList(
      _cacheKey,
      items.map((item) => item.toJson()).toList(),
    );
    _cachedItems = items;
  }

  void _handleStoreChanged() {
    if (!mounted) {
      return;
    }
    _syncFromStore();
  }

  Future<void> _reload() async {
    _settleTopEdge();
    await WerkaStore.instance.refreshHistory();
    await _syncFromStore();
    _settleTopEdge();
  }

  void _settleTopEdge() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.minScrollExtent;
      if ((position.pixels - target).abs() <= 0.5) {
        return;
      }
      _scrollController.jumpTo(target);
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      final isAtBottom = notification.metrics.extentAfter <= 0.0;
      if (isAtBottom &&
          notification.dragDetails != null &&
          notification.overscroll > 0) {
        _cardPull = (_cardPull + notification.overscroll).clamp(0.0, 280.0);
        final easedPull = 1.0 - math.exp(-_cardPull / 110.0);
        final nextStretch = (easedPull * 0.075).clamp(0.0, 0.075).toDouble();
        if (nextStretch != _cardStretch) {
          setState(() => _cardStretch = nextStretch);
        }
        return false;
      }
    }

    if (notification is ScrollEndNotification) {
      if (_cardStretch != 0.0 || _cardPull != 0.0) {
        setState(() {
          _cardStretch = 0.0;
          _cardPull = 0.0;
        });
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: context.l10n.notificationsTitle,
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      actions: [
        IconButton.filledTonal(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear_all_rounded),
        ),
      ],
      bottom: const WerkaDock(activeTab: WerkaDockTab.notifications),
      child: AnimatedBuilder(
        animation: WerkaStore.instance,
        builder: (context, _) {
          final store = WerkaStore.instance;
          final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
            AppSession.instance.profile,
          );
          final items =
              ((store.loadedHistory ? store.historyItems : (_cachedItems ?? <DispatchRecord>[])))
              .where((item) => !hidden.contains(item.id))
              .toList();
          final orderedItems = [
            ...items.where((item) => _highlightedUnreadIds.contains(item.id)),
            ...items.where((item) => !_highlightedUnreadIds.contains(item.id)),
          ];
          if (store.loadingHistory && !store.loadedHistory && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.historyError != null && !store.loadedHistory && items.isEmpty) {
            return AppRefreshIndicator(
              onRefresh: _reload,
              allowRefreshOnShortContent: true,
              child: ListView(
                controller: _scrollController,
                physics: const TopRefreshScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                children: [
                  const SizedBox(height: 120),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.notificationsLoadFailed,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n
                                .notificationsLoadFailedWith(store.historyError!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _reload,
                              child: Text(context.l10n.retry),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (items.isEmpty) {
            return AppRefreshIndicator(
              onRefresh: _reload,
              allowRefreshOnShortContent: true,
              child: ListView(
                controller: _scrollController,
                physics: const TopRefreshScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 116),
                children: [
                  const SizedBox(height: 120),
                  Align(
                    alignment: const Alignment(0, -0.22),
                    child: Text(
                      context.l10n.noNotifications,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }

          return AppRefreshIndicator(
            onRefresh: _reload,
            allowRefreshOnShortContent: true,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: ListView(
                controller: _scrollController,
                physics: const TopRefreshScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 1.0,
                        end: 1.0 + _cardStretch,
                      ),
                      duration: const Duration(milliseconds: 110),
                      curve: Curves.easeOutCubic,
                      builder: (context, scaleY, child) {
                        return Transform.scale(
                          scaleY: scaleY,
                          alignment: Alignment.bottomCenter,
                          child: child,
                        );
                      },
                      child: _WerkaNotificationsSection(
                        items: orderedItems,
                        highlightedUnreadIds: _highlightedUnreadIds,
                        onTapRecord: _openDetail,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WerkaNotificationsSection extends StatelessWidget {
  const _WerkaNotificationsSection({
    required this.items,
    required this.highlightedUnreadIds,
    required this.onTapRecord,
  });

  final List<DispatchRecord> items;
  final Set<String> highlightedUnreadIds;
  final ValueChanged<String> onTapRecord;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _WerkaNotificationRow(
              record: items[index],
              highlighted: highlightedUnreadIds.contains(items[index].id),
              isFirst: index == 0,
              isLast: index == items.length - 1,
              onTap: () => onTapRecord(items[index].id),
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 18,
                endIndent: 18,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

class _WerkaNotificationRow extends StatelessWidget {
  const _WerkaNotificationRow({
    required this.record,
    required this.highlighted,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final DispatchRecord record;
  final bool highlighted;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  String _secondary(DispatchRecord record) {
    if (record.eventType == 'supplier_ack') {
      return record.highlight;
    }
    return record.itemName;
  }

  String _metricLine(DispatchRecord record) {
    final sent =
        '${record.sentQty.toStringAsFixed(0)} ${record.uom} jo‘natildi';
    if (record.acceptedQty > 0) {
      return '$sent • ${record.acceptedQty.toStringAsFixed(0)} ${record.uom} qabul';
    }
    return sent;
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: 0,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: highlighted
              ? Theme.of(context).colorScheme.secondaryContainer
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _notificationTitle(context, record),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                _NotificationStatusBadge(status: record.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _secondary(record),
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _metricLine(record),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  record.createdLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _notificationTitle(BuildContext context, DispatchRecord record) {
  if (record.eventType == 'supplier_ack') {
    return context.l10n.supplierAckTitle;
  }
  switch (record.status) {
    case DispatchStatus.pending:
      return record.supplierName;
    case DispatchStatus.accepted:
    case DispatchStatus.partial:
    case DispatchStatus.rejected:
    case DispatchStatus.cancelled:
    case DispatchStatus.draft:
      return record.itemCode;
  }
}

class _NotificationStatusBadge extends StatelessWidget {
  const _NotificationStatusBadge({
    required this.status,
  });

  final DispatchStatus status;

  IconData get icon {
    switch (status) {
      case DispatchStatus.draft:
        return Icons.schedule_rounded;
      case DispatchStatus.pending:
        return Icons.schedule_outlined;
      case DispatchStatus.accepted:
        return Icons.done_all_rounded;
      case DispatchStatus.partial:
        return Icons.check_rounded;
      case DispatchStatus.rejected:
        return Icons.close_rounded;
      case DispatchStatus.cancelled:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
