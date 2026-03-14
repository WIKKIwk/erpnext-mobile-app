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
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WerkaNotificationsScreen extends StatefulWidget {
  const WerkaNotificationsScreen({super.key});

  @override
  State<WerkaNotificationsScreen> createState() =>
      _WerkaNotificationsScreenState();
}

class _WerkaNotificationsScreenState extends State<WerkaNotificationsScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'cache_werka_notifications';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tozalash'),
        content: const Text('Hamma bildirishnomalarni tozalaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Yo‘q'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ha'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
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

  Future<List<DispatchRecord>> _loadAndTrack() async {
    final items = await MobileApi.instance.werkaHistory();
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
      title: 'Bildirishnomalar',
      subtitle: '',
      actions: [
        AppShellIconAction(
          iconWidget: SvgPicture.asset(
            'assets/icons/brush-3-line.svg',
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          onTap: _clearAll,
        ),
      ],
      bottom: const WerkaDock(activeTab: WerkaDockTab.notifications),
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
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
                children: [
                  const SizedBox(height: 120),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bildirishnomalar yuklanmadi',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _WerkaNotificationsSection(
                    items: orderedItems,
                    highlightedUnreadIds: _highlightedUnreadIds,
                    onTapRecord: _openDetail,
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
    return SoftCard(
      padding: EdgeInsets.zero,
      borderWidth: 1.45,
      borderRadius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          color: const Color(0xFF000000),
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
                  const Divider(height: 1, thickness: 1),
              ],
            ],
          ),
        ),
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
          color: highlighted ? const Color(0xFF212121) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
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
                    _notificationTitle(record),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: highlighted ? Colors.white : null,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                _NotificationStatusBadge(status: record.status),
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

String _notificationTitle(DispatchRecord record) {
  if (record.eventType == 'supplier_ack') {
    return 'Supplier tasdiqladi';
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
