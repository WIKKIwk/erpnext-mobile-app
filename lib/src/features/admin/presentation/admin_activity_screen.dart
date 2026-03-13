import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/notification_hidden_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  static const String _cacheKey = 'cache_admin_activity';
  late Future<List<DispatchRecord>> _future;
  List<DispatchRecord>? _cachedItems;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.adminActivity();
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
    final current = _cachedItems ?? await _future;
    await NotificationHiddenStore.instance.hideAll(
      profile: AppSession.instance.profile,
      ids: current.map((item) => item.id),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _cachedItems = const [];
      _future = Future.value(const <DispatchRecord>[]);
    });
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'admin') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.adminActivity();
    setState(() {
      _future = future;
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
      title: 'Harakatlar',
      subtitle: '',
      actions: [
        AppShellIconAction(
          icon: Icons.cleaning_services_rounded,
          onTap: _clearAll,
        ),
      ],
      bottom: const AdminDock(activeTab: AdminDockTab.activity),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _future,
        builder: (context, snapshot) {
          final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
            AppSession.instance.profile,
          );
          final items = (snapshot.data ?? _cachedItems ?? const <DispatchRecord>[])
              .where((item) => !hidden.contains(item.id))
              .toList();
          if (snapshot.connectionState != ConnectionState.done &&
              items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && items.isEmpty) {
            return Center(
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Harakatlar yuklanmadi: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (items.isEmpty) {
            return Center(
              child: SoftCard(
                child: Text(
                  'Hali harakat yo‘q.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _AdminActivitySection(items: items),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminActivitySection extends StatelessWidget {
  const _AdminActivitySection({
    required this.items,
  });

  final List<DispatchRecord> items;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      borderWidth: 1.45,
      borderRadius: 20,
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _AdminActivityRow(
              item: items[index],
              isFirst: index == 0,
              isLast: index == items.length - 1,
            ),
            if (index != items.length - 1)
              const Divider(height: 1, thickness: 1),
          ],
        ],
      ),
    );
  }
}

class _AdminActivityRow extends StatelessWidget {
  const _AdminActivityRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final DispatchRecord item;
  final bool isFirst;
  final bool isLast;

  String _metricLine() {
    final sent = '${item.sentQty.toStringAsFixed(0)} ${item.uom} jo‘natildi';
    if (item.acceptedQty > 0) {
      return '$sent • ${item.acceptedQty.toStringAsFixed(0)} ${item.uom} qabul';
    }
    return sent;
  }

  String _secondary() => '${item.supplierName} • ${item.itemName}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 20 : 0),
          topRight: Radius.circular(isFirst ? 20 : 0),
          bottomLeft: Radius.circular(isLast ? 20 : 0),
          bottomRight: Radius.circular(isLast ? 20 : 0),
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
                  item.supplierName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              _ActivityStatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _secondary(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _metricLine(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.createdLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityStatusBadge extends StatelessWidget {
  const _ActivityStatusBadge({
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
