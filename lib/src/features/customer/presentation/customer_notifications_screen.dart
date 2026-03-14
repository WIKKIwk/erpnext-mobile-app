import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/notification_hidden_store.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/customer_dock.dart';
import 'package:flutter/material.dart';

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
      if (mounted) {
        setState(() {});
      }
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
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          backgroundColor: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tozalash', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 10),
                Text(
                  'Hamma bildirishnomalarni tozalaysizmi?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Yo‘q'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Ha'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
          icon: Icons.cleaning_services_outlined,
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

          if (snapshot.connectionState != ConnectionState.done &&
              items.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError && items.isEmpty) {
            return Center(
              child: _NotificationPanel(
                child: Text('${snapshot.error}'),
              ),
            );
          }
          if (items.isEmpty) {
            return const Center(
              child: _NotificationPanel(
                child: Text('Hozircha yozuv yo‘q.'),
              ),
            );
          }

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: _NotificationSection(
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

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isDark ? const Color(0xFF25242B) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.items,
    required this.highlightedUnreadIds,
    required this.onTapRecord,
  });

  final List<DispatchRecord> items;
  final Set<String> highlightedUnreadIds;
  final ValueChanged<String> onTapRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return _NotificationPanel(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Jo‘natmalar oqimi',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 14),
          Card.filled(
            margin: EdgeInsets.zero,
            color: isDark ? const Color(0xFF2A2931) : scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  _CustomerFeedRow(
                    record: items[index],
                    isFirst: index == 0,
                    isLast: index == items.length - 1,
                    highlighted: highlightedUnreadIds.contains(items[index].id),
                    onTap: () => onTapRecord(items[index].id),
                  ),
                  if (index != items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                ],
              ],
            ),
          ),
        ],
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
        return Icons.done_rounded;
      case DispatchStatus.rejected:
        return Icons.close_rounded;
      default:
        return Icons.schedule_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 24 : 0),
      topRight: Radius.circular(isFirst ? 24 : 0),
      bottomLeft: Radius.circular(isLast ? 24 : 0),
      bottomRight: Radius.circular(isLast ? 24 : 0),
    );

    return Material(
      color: highlighted ? scheme.surfaceContainerHigh : Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: highlighted
                      ? scheme.secondaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon,
                  size: 20,
                  color: highlighted
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.itemName,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.itemCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.note.trim().isNotEmpty
                          ? record.note
                          : '${record.sentQty.toStringAsFixed(0)} ${record.uom} jo‘natildi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.createdLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
