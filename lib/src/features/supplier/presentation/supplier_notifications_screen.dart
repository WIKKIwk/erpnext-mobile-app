import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/notification_hidden_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
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
  static const String _cacheKey = 'cache_supplier_notifications';
  late Future<List<DispatchRecord>> _itemsFuture;
  List<DispatchRecord>? _cachedItems;
  Set<String> _highlightedUnreadIds = <String>{};
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _itemsFuture = _loadAndTrack();
    NotificationHiddenStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    _loadCache();
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
    final current = _cachedItems ?? await _itemsFuture;
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
      _cachedItems = const [];
      _highlightedUnreadIds.clear();
      _itemsFuture = Future.value(const <DispatchRecord>[]);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RefreshHub.instance.removeListener(_handlePushRefresh);
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
    await Navigator.of(context).pushNamed(
      AppRoutes.notificationDetail,
      arguments: receiptId,
    );
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
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<List<DispatchRecord>> _loadAndTrack() async {
    final items = await MobileApi.instance.supplierHistory();
    final unread = NotificationUnreadStore.instance.unreadIdsForProfile(
      AppSession.instance.profile,
    );
    final highlighted = items
        .map((item) => item.id)
        .where((id) => unread.contains(id))
        .toSet();
    if (mounted) {
      setState(() {
        _highlightedUnreadIds = highlighted;
      });
    }
    await JsonCacheStore.instance.writeList(
      _cacheKey,
      items.map((item) => item.toJson()).toList(),
    );
    return items;
  }

  Future<void> _reload() async {
    final future = _loadAndTrack();
    setState(() {
      _itemsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notifications',
      subtitle: '',
      actions: [
        AppShellIconAction(
          icon: Icons.cleaning_services_rounded,
          onTap: _clearAll,
        ),
      ],
      bottom: const SupplierDock(activeTab: SupplierDockTab.notifications),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
            AppSession.instance.profile,
          );
          final items = (snapshot.data ?? _cachedItems ?? <DispatchRecord>[])
              .where((item) => !hidden.contains(item.id))
              .toList();
          final orderedItems = [
            ...items.where((item) => _highlightedUnreadIds.contains(item.id)),
            ...items.where((item) => !_highlightedUnreadIds.contains(item.id)),
          ];
          if (snapshot.connectionState != ConnectionState.done &&
              items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && items.isEmpty) {
            return RefreshIndicator.adaptive(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 120),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications yuklanmadi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _reload,
                            child: const Text('Qayta urinish'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (items.isEmpty) {
            return const Center(
              child: SoftCard(
                child: Text('Hali bildirishnomalar yo‘q.'),
              ),
            );
          }

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                SoftCard(
                  padding: EdgeInsets.zero,
                  borderWidth: 1.45,
                  borderRadius: 20,
                  child: Column(
                    children: [
                      for (int index = 0;
                          index < orderedItems.length;
                          index++) ...[
                        _SupplierNotificationRow(
                          record: orderedItems[index],
                          highlighted: _highlightedUnreadIds
                              .contains(orderedItems[index].id),
                          isFirst: index == 0,
                          isLast: index == orderedItems.length - 1,
                          onTap: () => _openDetail(orderedItems[index].id),
                        ),
                        if (index != orderedItems.length - 1)
                          const Divider(height: 1, thickness: 1),
                      ],
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

class _SupplierNotificationRow extends StatelessWidget {
  const _SupplierNotificationRow({
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
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFF212121) : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 20 : 0),
            topRight: Radius.circular(isFirst ? 20 : 0),
            bottomLeft: Radius.circular(isLast ? 20 : 0),
            bottomRight: Radius.circular(isLast ? 20 : 0),
          ),
        ),
        padding: const EdgeInsets.all(18),
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
                          color: highlighted ? Colors.white : null,
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
                    color: highlighted ? Colors.white70 : null,
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
                          color: highlighted ? Colors.white70 : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  record.createdLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: highlighted ? Colors.white70 : null,
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
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor),
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
