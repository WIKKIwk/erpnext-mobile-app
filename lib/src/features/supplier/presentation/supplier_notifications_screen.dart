import 'dart:math' as math;

import '../../../app/app_router.dart';
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
import '../state/supplier_store.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierNotificationsScreen extends StatefulWidget {
  const SupplierNotificationsScreen({super.key});

  @override
  State<SupplierNotificationsScreen> createState() =>
      _SupplierNotificationsScreenState();
}

class _SupplierNotificationsScreenState
    extends State<SupplierNotificationsScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Set<String> _highlightedUnreadIds = <String>{};
  int _refreshVersion = 0;
  double _cardStretch = 0.0;
  double _cardPull = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupplierStore.instance.bootstrapHistory();
    NotificationHiddenStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    SupplierStore.instance.addListener(_handleStoreChanged);
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  Future<void> _clearAll() async {
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
    final current = SupplierStore.instance.historyItems;
    await NotificationHiddenStore.instance.hideAll(
      profile: AppSession.instance.profile,
      ids: current.map((item) => item.id),
    );
    await NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: current.map((item) => item.id),
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
    SupplierStore.instance.removeListener(_handleStoreChanged);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'supplier') {
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
    final items = SupplierStore.instance.historyItems;
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
  }

  void _handleStoreChanged() {
    if (!mounted) {
      return;
    }
    _syncFromStore();
  }

  Future<void> _reload() async {
    _settleTopEdge();
    await SupplierStore.instance.refreshHistory();
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
      bottom: const SupplierDock(activeTab: SupplierDockTab.notifications),
      child: AnimatedBuilder(
        animation: SupplierStore.instance,
        builder: (context, _) {
          final store = SupplierStore.instance;
          final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
            AppSession.instance.profile,
          );
          final items = store.historyItems
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
                            '${store.historyError}',
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
                  Center(
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
                    child: Card.filled(
                      margin: EdgeInsets.zero,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          for (int index = 0;
                              index < orderedItems.length;
                              index++) ...[
                            _SupplierNotificationRow(
                              record: orderedItems[index],
                              highlighted: _highlightedUnreadIds
                                  .contains(orderedItems[index].id),
                              onTap: () => _openDetail(orderedItems[index].id),
                            ),
                            if (index != orderedItems.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                indent: 18,
                                endIndent: 18,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.55),
                              ),
                          ],
                        ],
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

class _SupplierNotificationRow extends StatelessWidget {
  const _SupplierNotificationRow({
    required this.record,
    required this.highlighted,
    required this.onTap,
  });

  final DispatchRecord record;
  final bool highlighted;
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
                    notificationTitle(record),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: highlighted
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer
                              : null,
                        ),
                  ),
                ),
                _NotificationStatusBadge(
                  status: record.status,
                  note: record.note,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _secondary(record),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: highlighted
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : null,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _metricLine(record),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: highlighted
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer
                              : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  record.createdLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: highlighted
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : null,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String notificationTitle(DispatchRecord record) {
  switch (record.status) {
    case DispatchStatus.accepted:
      return record.itemCode;
    case DispatchStatus.partial:
      return record.itemCode;
    case DispatchStatus.rejected:
      return record.itemCode;
    case DispatchStatus.cancelled:
      return record.itemCode;
    case DispatchStatus.draft:
      return record.itemCode;
    case DispatchStatus.pending:
      return record.itemCode;
  }
}

class _NotificationStatusBadge extends StatelessWidget {
  const _NotificationStatusBadge({
    required this.status,
    required this.note,
  });

  final DispatchStatus status;
  final String note;

  IconData get icon {
    if (note.contains('Supplier tasdiqladi:') ||
        note.contains('Tasdiqlayman, shu holat')) {
      return Icons.done_all_rounded;
    }
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

IconData notificationIcon(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.accepted:
      return Icons.check_rounded;
    case DispatchStatus.partial:
      return Icons.timelapse_rounded;
    case DispatchStatus.rejected:
      return Icons.cancel_rounded;
    case DispatchStatus.cancelled:
      return Icons.block_rounded;
    case DispatchStatus.draft:
      return Icons.edit_note_rounded;
    case DispatchStatus.pending:
      return Icons.notifications_active_rounded;
  }
}

Color notificationColor(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.accepted:
      return const Color(0xFF5BB450);
    case DispatchStatus.partial:
      return const Color(0xFF2A6FDB);
    case DispatchStatus.rejected:
      return const Color(0xFFC53B30);
    case DispatchStatus.cancelled:
      return const Color(0xFF9CA3AF);
    case DispatchStatus.draft:
      return const Color(0xFFA78BFA);
    case DispatchStatus.pending:
      return const Color(0xFFFFD54F);
  }
}
