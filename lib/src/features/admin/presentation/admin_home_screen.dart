import '../../../core/api/mobile_api.dart';
import '../../../app/app_router.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_module_card.dart';
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
                _AdminSummarySection(
                  summary: summaryValue,
                  onTapActive: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminSuppliers),
                  onTapTotal: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminSuppliers),
                  onTapBlocked: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminInactiveSuppliers),
                ),
                const SizedBox(height: 12),
                AdminModuleCard(
                  title: 'Settings',
                  subtitle: 'ERP va default sozlamalar',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminSettings),
                ),
                const SizedBox(height: 12),
                AdminModuleCard(
                  title: 'Suppliers',
                  subtitle: 'List, mahsulot biriktirish va block nazorati',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminSuppliers),
                ),
                const SizedBox(height: 12),
                AdminModuleCard(
                  title: 'Werka',
                  subtitle: 'Omborchi phone va name',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminWerka),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminSummarySection extends StatelessWidget {
  const _AdminSummarySection({
    required this.summary,
    required this.onTapActive,
    required this.onTapTotal,
    required this.onTapBlocked,
  });

  final AdminSupplierSummary summary;
  final VoidCallback onTapActive;
  final VoidCallback onTapTotal;
  final VoidCallback onTapBlocked;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _AdminSummaryRow(
            label: 'Aktiv supplierlar',
            value: '${summary.activeSuppliers}',
            onTap: onTapActive,
          ),
          const _AdminSummaryDivider(),
          _AdminSummaryRow(
            label: 'Jami supplierlar',
            value: '${summary.totalSuppliers}',
            onTap: onTapTotal,
          ),
          const _AdminSummaryDivider(),
          _AdminSummaryRow(
            label: 'Bloklangan supplierlar',
            value: '${summary.blockedSuppliers}',
            onTap: onTapBlocked,
          ),
        ],
      ),
    );
  }
}

class _AdminSummaryRow extends StatelessWidget {
  const _AdminSummaryRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSummaryDivider extends StatelessWidget {
  const _AdminSummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}
