import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/m3_segmented_list.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_supplier_list_module.dart';
import 'widgets/admin_summary_card.dart';
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
    final page = await MobileApi.instance.adminSuppliersPage();

    final items = <AdminUserListEntry>[
      if (page.settings.werkaName.trim().isNotEmpty ||
          page.settings.werkaPhone.trim().isNotEmpty)
        AdminUserListEntry(
          id: 'werka',
          name: page.settings.werkaName.trim().isEmpty
              ? 'Werka'
              : page.settings.werkaName.trim(),
          phone: page.settings.werkaPhone.trim(),
          kind: AdminUserKind.werka,
        ),
      ...page.suppliers.map(
        (item) => AdminUserListEntry(
          id: item.ref,
          name: item.name,
          phone: item.phone,
          kind: AdminUserKind.supplier,
          blocked: item.blocked,
        ),
      ),
      ...page.customers.map(
        (item) => AdminUserListEntry(
          id: item.ref,
          name: item.name,
          phone: item.phone,
          kind: AdminUserKind.customer,
        ),
      ),
    ];
    return _AdminSuppliersData(summary: page.summary, items: items);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Suppliers',
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: FutureBuilder<_AdminSuppliersData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return AppRetryState(onRetry: _reload);
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
          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 116),
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
                      await Navigator.of(context)
                          .pushNamed(AppRoutes.adminWerka);
                    } else if (item.kind == AdminUserKind.customer) {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.adminCustomerDetail,
                        arguments: item.id,
                      );
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
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.top,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Jami supplierlar',
          value: summary.totalSuppliers.toString(),
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.middle,
          cornerRadius: M3SegmentedListGeometry.cornerMiddle,
          title: 'Faol supplierlar',
          value: summary.activeSuppliers.toString(),
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.bottom,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Bloklangan supplierlar',
          value: summary.blockedSuppliers.toString(),
          onTap: onTapBlocked,
        ),
      ],
    );
  }
}
