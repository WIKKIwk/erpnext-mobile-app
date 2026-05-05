import 'dart:math' as math;

import '../../../app/app_router.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/store/notification_hidden_store.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/notifications/store/notification_unread_store.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/feedback/m3_confirm_dialog.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../../core/widgets/scroll/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_notification_store.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/foundation.dart';
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
  List<DispatchRecord>? _cachedItems;
  Set<String> _highlightedUnreadIds = <String>{};
  int _refreshVersion = 0;
  double _cardStretch = 0.0;
  double _cardPull = 0.0;
  final ValueNotifier<double> _bottomDockFadeStrength = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WerkaNotificationStore.instance.bootstrap();
    NotificationHiddenStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    NotificationUnreadStore.instance.load().then((_) {
      if (!mounted) {
        return;
      }
      _syncHighlightedUnreadIds();
    });
    _loadCache();
    WerkaNotificationStore.instance.addListener(_handleStoreChanged);
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
    _syncHighlightedUnreadIds();
  }

  Future<void> _clearAll() async {
    final current = WerkaNotificationStore.instance.items;
    if (!mounted) {
      return;
    }
    final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
      AppSession.instance.profile,
    );
    final visibleItems =
        current.where((item) => !hidden.contains(item.id)).toList();
    if (visibleItems.isEmpty) {
      _showTopInfoBanner(context.l10n.noNotifications);
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

  void _showTopInfoBanner(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        content: Text(message),
        contentTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
        forceActionsBelow: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: const [SizedBox.shrink()],
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      messenger.hideCurrentMaterialBanner();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WerkaNotificationStore.instance.removeListener(_handleStoreChanged);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    _bottomDockFadeStrength.dispose();
    super.dispose();
  }

  void _syncBottomDockFade(ScrollMetrics metrics) {
    final next = dockFadeStrengthFromScrollMetrics(metrics);
    if ((next - _bottomDockFadeStrength.value).abs() > 0.008) {
      _bottomDockFadeStrength.value = next;
    }
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

  Future<void> _openDetail(DispatchRecord record) async {
    await NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: [record.id],
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedUnreadIds.remove(record.id);
    });
    if (record.recordType == 'delivery_note' ||
        record.eventType.startsWith('customer_delivery_')) {
      await Navigator.of(context).pushNamed(
        AppRoutes.werkaCustomerDeliveryDetail,
        arguments: record,
      );
      return;
    }
    await Navigator.of(context).pushNamed(
      AppRoutes.notificationDetail,
      arguments: record.id,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _syncFromStore() async {
    final items = WerkaNotificationStore.instance.items;
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
    _applyHighlightedUnreadIds(
      items.map((item) => item.id).where((id) => unread.contains(id)).toSet(),
    );
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

  void _syncHighlightedUnreadIds() {
    final items = WerkaNotificationStore.instance.loaded
        ? WerkaNotificationStore.instance.items
        : (_cachedItems ?? const <DispatchRecord>[]);
    final unread = NotificationUnreadStore.instance.unreadIdsForProfile(
      AppSession.instance.profile,
    );
    _applyHighlightedUnreadIds(
      items.map((item) => item.id).where((id) => unread.contains(id)).toSet(),
    );
  }

  void _applyHighlightedUnreadIds(Set<String> next) {
    if (!mounted || setEquals(_highlightedUnreadIds, next)) {
      return;
    }
    setState(() {
      _highlightedUnreadIds = next;
    });
  }

  Future<void> _reload() async {
    await WerkaNotificationStore.instance.refresh();
    await _syncFromStore();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _syncBottomDockFade(notification.metrics);

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
    final scheme = Theme.of(context).colorScheme;
    useNativeNavigationTitle(context, context.l10n.notificationsTitle);
    return AnimatedBuilder(
      animation: WerkaNotificationStore.instance,
      builder: (context, _) {
        final store = WerkaNotificationStore.instance;
        final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
          AppSession.instance.profile,
        );
        final items = ((store.loaded
                ? store.items
                : (_cachedItems ?? <DispatchRecord>[])))
            .where((item) => !hidden.contains(item.id))
            .toList();
        final appBarBottomLoading =
            store.loading && !store.loaded && items.isEmpty;

        return AppShell(
          title: context.l10n.notificationsTitle,
          subtitle: '',
          nativeTopBar: true,
          nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
          contentPadding: EdgeInsets.zero,
          appBarBottomLoading: appBarBottomLoading,
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: IconButton(
                tooltip: context.l10n.clearTitle,
                onPressed: _clearAll,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                icon: Icon(
                  Icons.clear_all_rounded,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
          bottom: const WerkaDock(activeTab: WerkaDockTab.notifications),
          bottomDockFadeStrength: _bottomDockFadeStrength,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (ScrollMetricsNotification n) {
              _syncBottomDockFade(n.metrics);
              return false;
            },
            child: Builder(
              builder: (context) {
                final orderedItems = [
                  ...items
                      .where((item) => _highlightedUnreadIds.contains(item.id)),
                  ...items.where(
                      (item) => !_highlightedUnreadIds.contains(item.id)),
                ];
                if (store.loading && !store.loaded && items.isEmpty) {
                  return const SizedBox.expand();
                }
                if (store.error != null && !store.loaded && items.isEmpty) {
                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    allowRefreshOnShortContent: true,
                    child: ListView(
                      physics: const TopRefreshScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
                      children: [
                        AppRetryState(onRetry: _reload),
                      ],
                    ),
                  );
                }

                if (items.isEmpty) {
                  final theme = Theme.of(context);
                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    allowRefreshOnShortContent: true,
                    child: ListView(
                      physics: const TopRefreshScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: M3SegmentFilledSurface(
                              slot: M3SegmentVerticalSlot.top,
                              cornerRadius: M3SegmentedListGeometry.cornerLarge,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Text(
                                  context.l10n.noNotifications,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
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
                      physics: const TopRefreshScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
                      children: [
                        TweenAnimationBuilder<double>(
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
                            onTapRecord: (id) {
                              final record = orderedItems.firstWhere(
                                (item) => item.id == id,
                              );
                              _openDetail(record);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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
    final n = items.length;
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        for (int index = 0; index < n; index++)
          _WerkaNotificationSegmentTile(
            record: items[index],
            highlighted: highlightedUnreadIds.contains(items[index].id),
            index: index,
            itemCount: n,
            onTap: () => onTapRecord(items[index].id),
          ),
      ],
    );
  }
}

class _WerkaNotificationSegmentTile extends StatelessWidget {
  const _WerkaNotificationSegmentTile({
    required this.record,
    required this.highlighted,
    required this.index,
    required this.itemCount,
    required this.onTap,
  });

  final DispatchRecord record;
  final bool highlighted;
  final int index;
  final int itemCount;
  final VoidCallback onTap;

  String _secondary(DispatchRecord record) {
    if (record.highlight.trim().isNotEmpty) {
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slot = M3SegmentedListGeometry.standaloneListSlotForIndex(
      index,
      itemCount,
    );
    final r = M3SegmentedListGeometry.cornerRadiusForSlot(slot);

    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: r,
      onTap: onTap,
      backgroundColor: highlighted ? scheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _notificationTitle(context, record),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                _NotificationStatusBadge(status: record.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _secondary(record),
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _metricLine(record),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  record.createdLabel,
                  style: theme.textTheme.bodySmall,
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
