import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_supplier_list_module.dart';
import 'package:flutter/material.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  late Future<_AdminSuppliersData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadUsers();
  }

  Future<void> _reload() async {
    final future = _loadUsers();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<_AdminSuppliersData> _loadUsers() async {
    final results = await Future.wait<dynamic>([
      MobileApi.instance.adminSupplierSummary(),
      MobileApi.instance.adminSuppliers(),
      MobileApi.instance.adminSettings(),
    ]);
    final AdminSupplierSummary summary = results[0] as AdminSupplierSummary;
    final List<AdminSupplier> suppliers = results[1] as List<AdminSupplier>;
    final AdminSettings settings = results[2] as AdminSettings;

    final items = <AdminUserListEntry>[
      if (settings.werkaName.trim().isNotEmpty ||
          settings.werkaPhone.trim().isNotEmpty)
        AdminUserListEntry(
          id: 'werka',
          name: settings.werkaName.trim().isEmpty
              ? 'Werka'
              : settings.werkaName.trim(),
          phone: settings.werkaPhone.trim(),
          kind: AdminUserKind.werka,
        ),
      ...suppliers.map(
        (item) => AdminUserListEntry(
          id: item.ref,
          name: item.name,
          phone: item.phone,
          kind: AdminUserKind.supplier,
          blocked: item.blocked,
        ),
      ),
    ];
    return _AdminSuppliersData(summary: summary, items: items);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Suppliers',
      subtitle: '',
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: FutureBuilder<_AdminSuppliersData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('Users yuklanmadi: ${snapshot.error}'),
              ),
            );
          }
          final data = snapshot.data ??
              const _AdminSuppliersData(
                summary: AdminSupplierSummary(
                  totalSuppliers: 0,
                  activeSuppliers: 0,
                  blockedSuppliers: 0,
                ),
                items: <AdminUserListEntry>[],
              );
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _AdminSuppliersSummarySection(
                  summary: data.summary,
                  onTapBlocked: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminInactiveSuppliers),
                ),
                const SizedBox(height: 12),
                AdminSupplierListModule(
                  items: data.items,
                  onTapUser: (item) async {
                    if (item.kind == AdminUserKind.werka) {
                      await Navigator.of(context).pushNamed(AppRoutes.adminWerka);
                    } else {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.adminSupplierDetail,
                        arguments: item.id,
                      );
                    }
                    await _reload();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminSuppliersData {
  const _AdminSuppliersData({
    required this.summary,
    required this.items,
  });

  final AdminSupplierSummary summary;
  final List<AdminUserListEntry> items;
}

class _AdminSuppliersSummarySection extends StatelessWidget {
  const _AdminSuppliersSummarySection({
    required this.summary,
    required this.onTapBlocked,
  });

  final AdminSupplierSummary summary;
  final VoidCallback onTapBlocked;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _AdminSuppliersSummaryRow(
            label: 'Aktiv supplierlar',
            value: '${summary.activeSuppliers}',
          ),
          const _AdminSuppliersSectionDivider(),
          _AdminSuppliersSummaryRow(
            label: 'Jami supplierlar',
            value: '${summary.totalSuppliers}',
          ),
          const _AdminSuppliersSectionDivider(),
          _AdminSuppliersSummaryRow(
            label: 'Bloklangan supplierlar',
            value: '${summary.blockedSuppliers}',
            onTap: onTapBlocked,
          ),
        ],
      ),
    );
  }
}

class _AdminSuppliersSummaryRow extends StatelessWidget {
  const _AdminSuppliersSummaryRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
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
    );
    if (onTap == null) {
      return row;
    }
    return PressableScale(
      borderRadius: 24,
      onTap: onTap,
      child: row,
    );
  }
}

class _AdminSuppliersSectionDivider extends StatelessWidget {
  const _AdminSuppliersSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
    );
  }
}
