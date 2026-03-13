import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const String _cacheKey = 'cache_admin_summary';
  late Future<AdminSupplierSummary> _summaryFuture;
  AdminSupplierSummary? _cachedSummary;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _summaryFuture = MobileApi.instance.adminSupplierSummary();
    _loadCache();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  Future<void> _loadCache() async {
    final raw = await JsonCacheStore.instance.readMap(_cacheKey);
    if (raw == null || !mounted) {
      return;
    }
    setState(() {
      _cachedSummary = AdminSupplierSummary.fromJson(raw);
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
    final future = MobileApi.instance.adminSupplierSummary();
    setState(() {
      _summaryFuture = future;
    });
    final summary = await future;
    await JsonCacheStore.instance.writeMap(_cacheKey, summary.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Admin',
      subtitle: '',
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      child: FutureBuilder<AdminSupplierSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data ?? _cachedSummary;
          if (snapshot.connectionState != ConnectionState.done &&
              summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && summary == null) {
            return Center(
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Admin summary yuklanmadi: ${snapshot.error}'),
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

          final summaryValue = summary!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _AdminModulesSection(
                  onTapSettings: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminSettings),
                  onTapSuppliers: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminSuppliers),
                  onTapWerka: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminWerka),
                ),
                if (summaryValue.blockedSuppliers > 0) ...[
                  const SizedBox(height: 12),
                  PressableScale(
                    borderRadius: 24,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.adminInactiveSuppliers),
                    child: SoftCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.block_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Bloklangan supplierlar: ${summaryValue.blockedSuppliers} ta',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminModulesSection extends StatelessWidget {
  const _AdminModulesSection({
    required this.onTapSettings,
    required this.onTapSuppliers,
    required this.onTapWerka,
  });

  final VoidCallback onTapSettings;
  final VoidCallback onTapSuppliers;
  final VoidCallback onTapWerka;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _AdminModuleRow(
            title: 'Settings',
            subtitle: 'ERP va default sozlamalar',
            onTap: onTapSettings,
          ),
          const _AdminSectionDivider(),
          _AdminModuleRow(
            title: 'Suppliers',
            subtitle: 'List, mahsulot biriktirish va block nazorati',
            onTap: onTapSuppliers,
          ),
          const _AdminSectionDivider(),
          _AdminModuleRow(
            title: 'Werka',
            subtitle: 'Omborchi phone va name',
            onTap: onTapWerka,
          ),
        ],
      ),
    );
  }
}

class _AdminModuleRow extends StatelessWidget {
  const _AdminModuleRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: 24,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class _AdminSectionDivider extends StatelessWidget {
  const _AdminSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}
