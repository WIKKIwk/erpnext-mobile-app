import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
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
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _itemsFuture = MobileApi.instance.supplierHistory();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.supplierHistory();
    setState(() {
      _itemsFuture = future;
    });
    final items = await future;
    await JsonCacheStore.instance.writeList(
      _cacheKey,
      items.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notifications',
      subtitle: '',
      bottom: const SupplierDock(activeTab: SupplierDockTab.notifications),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          final items = snapshot.data ?? _cachedItems ?? <DispatchRecord>[];
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
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.notificationDetail,
                    arguments: record.id,
                  ),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notificationTitle(record),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _NotificationStatusBadge(
                              status: record.status,
                              note: record.note,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${record.itemCode} • ${record.itemName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jo‘natildi: ${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (record.acceptedQty > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Qabul qilindi: ${record.acceptedQty.toStringAsFixed(0)} ${record.uom}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (record.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            record.note,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (record.highlight.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            record.highlight,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          record.createdLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
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
