import '../../../core/api/mobile_api.dart';
import '../../../app/app_router.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'supplier_qty_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierRecentScreen extends StatefulWidget {
  const SupplierRecentScreen({super.key});

  @override
  State<SupplierRecentScreen> createState() => _SupplierRecentScreenState();
}

class _SupplierRecentScreenState extends State<SupplierRecentScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'cache_supplier_recent';
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
      title: 'Recent',
      subtitle: '',
      bottom: const SupplierDock(activeTab: SupplierDockTab.recent),
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
                          'Recent yuklanmadi',
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
                child: Text('Hali jo‘natishlar yo‘q.'),
              ),
            );
          }

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Color(0xFF1D1D1D),
              ),
              itemBuilder: (context, index) {
                final record = items[index];
                final item = SupplierItem(
                  code: record.itemCode,
                  name: record.itemName,
                  uom: record.uom,
                  warehouse: '',
                );
                return PressableScale(
                  borderRadius: 18,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.supplierQty,
                    arguments: SupplierQtyArgs(
                      item: item,
                      initialQty: record.sentQty,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF111111),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.itemCode,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              if (record.amount > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${record.amount.toStringAsFixed(0)} ${record.currency.isEmpty ? "" : record.currency}'.trim(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
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
