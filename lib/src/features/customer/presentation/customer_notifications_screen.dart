import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/notification_hidden_store.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/customer_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  static const String _cacheKey = 'cache_customer_notifications';
  late Future<List<DispatchRecord>> _future;
  List<DispatchRecord>? _cachedItems;
  Set<String> _highlightedUnreadIds = <String>{};
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadAndTrack();
    NotificationHiddenStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    _loadCache();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
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

  Future<void> _reload() async {
    final future = _loadAndTrack();
    setState(() => _future = future);
    await future;
  }

  Future<void> _openDetail(String deliveryNoteID) async {
    await NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: [deliveryNoteID],
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedUnreadIds.remove(deliveryNoteID);
    });
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.customerDetail,
      arguments: deliveryNoteID,
    );
    if (changed == true) {
      await _reload();
    }
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
    final current = _cachedItems ?? await _future;
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
      _future = Future.value(const <DispatchRecord>[]);
    });
  }

  Future<List<DispatchRecord>> _loadAndTrack() async {
    final items = await MobileApi.instance.customerHistory();
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

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'customer') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
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
      bottom: const CustomerDock(activeTab: CustomerDockTab.notifications),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _future,
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
          if (snapshot.connectionState != ConnectionState.done) {
            if (items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
          }
          if (snapshot.hasError && items.isEmpty) {
            return Center(child: SoftCard(child: Text('${snapshot.error}')));
          }
          if (items.isEmpty) {
            return const Center(
              child: SoftCard(
                child: Text('Hozircha yozuv yo‘q.'),
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
                      const _CustomerFeedSectionHeader(
                        label: 'Jo‘natmalar oqimi',
                      ),
                      for (int index = 0;
                          index < orderedItems.length;
                          index++) ...[
                        _CustomerFeedRow(
                          record: orderedItems[index],
                          isFirst: index == 0,
                          isLast: index == orderedItems.length - 1,
                          highlighted: _highlightedUnreadIds.contains(
                            orderedItems[index].id,
                          ),
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

class _CustomerFeedRow extends StatelessWidget {
  const _CustomerFeedRow({
    required this.record,
    required this.isFirst,
    required this.isLast,
    required this.highlighted,
    required this.onTap,
  });

  final DispatchRecord record;
  final bool isFirst;
  final bool isLast;
  final bool highlighted;
  final VoidCallback onTap;

  IconData get _icon {
    switch (record.status) {
      case DispatchStatus.accepted:
        return Icons.done_all_rounded;
      case DispatchStatus.rejected:
        return Icons.close_rounded;
      default:
        return Icons.schedule_outlined;
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    record.itemName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: highlighted ? Colors.white : null,
                        ),
                  ),
                ),
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Icon(
                    _icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              record.itemCode,
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
                    record.note.trim().isNotEmpty
                        ? record.note
                        : '${record.sentQty.toStringAsFixed(0)} ${record.uom} jo‘natildi',
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

class _CustomerFeedSectionHeader extends StatelessWidget {
  const _CustomerFeedSectionHeader({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
