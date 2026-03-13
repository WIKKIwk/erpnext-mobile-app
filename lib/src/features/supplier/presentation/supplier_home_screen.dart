import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({super.key});

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen>
    with WidgetsBindingObserver {
  static const String _cacheKey = 'cache_supplier_home_summary';
  late Future<SupplierHomeSummary> _summaryFuture;
  SupplierHomeSummary? _cachedSummary;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _summaryFuture = MobileApi.instance.supplierSummary();
    _loadCache();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  Future<void> _loadCache() async {
    final raw = await JsonCacheStore.instance.readMap(_cacheKey);
    if (raw == null || !mounted) {
      return;
    }
    setState(() {
      _cachedSummary = SupplierHomeSummary.fromJson(raw);
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
    final future = MobileApi.instance.supplierSummary();
    setState(() {
      _summaryFuture = future;
    });
    final summary = await future;
    await JsonCacheStore.instance.writeMap(_cacheKey, summary.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Supplier',
      subtitle: '',
      bottom: const SupplierDock(activeTab: SupplierDockTab.home),
      child: FutureBuilder<SupplierHomeSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data ?? _cachedSummary;
          if (snapshot.connectionState != ConnectionState.done &&
              summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && summary == null) {
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
                        Text('Home yuklanmadi',
                            style: Theme.of(context).textTheme.titleMedium),
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
          final current = summary!;

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _SupplierSummaryCard(summary: current),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupplierSummaryCard extends StatelessWidget {
  const _SupplierSummaryCard({
    required this.summary,
  });

  final SupplierHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return SmoothAppear(
      child: SoftCard(
        padding: EdgeInsets.zero,
        borderWidth: 1.35,
        borderRadius: 20,
        child: Column(
          children: [
            _SupplierSummaryRow(
              label: 'Jarayonda',
              value: summary.pendingCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.pending,
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _SupplierSummaryRow(
              label: 'Submit',
              value: summary.submittedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.submitted,
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _SupplierSummaryRow(
              label: 'Qaytarilgan',
              value: summary.returnedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.returned,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierSummaryRow extends StatelessWidget {
  const _SupplierSummaryRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: 24,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 34,
                    color: AppTheme.isDark(context)
                        ? Colors.white
                        : const Color(0xFF1F1A17),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
