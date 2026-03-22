import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
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
  final ScrollController _scrollController = ScrollController();
  late Future<_AdminSuppliersData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _settleTopEdge();
    final future = _loadUsers();
    setState(() {
      _future = future;
    });
    await future;
    _settleTopEdge();
  }

  void _settleTopEdge() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.minScrollExtent;
      if ((position.pixels - target).abs() <= 0.5) {
        return;
      }
      _scrollController.jumpTo(target);
    });
  }

  Future<_AdminSuppliersData> _loadUsers() async {
    final results = await Future.wait<dynamic>([
      MobileApi.instance.adminSupplierSummary(),
      MobileApi.instance.adminSuppliers(),
      MobileApi.instance.adminCustomers(),
      MobileApi.instance.adminSettings(),
    ]);
    final AdminSupplierSummary summary = results[0] as AdminSupplierSummary;
    final List<AdminSupplier> suppliers = results[1] as List<AdminSupplier>;
    final List<CustomerDirectoryEntry> customers =
        results[2] as List<CustomerDirectoryEntry>;
    final AdminSettings settings = results[3] as AdminSettings;

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
      ...customers.map(
        (item) => AdminUserListEntry(
          id: item.ref,
          name: item.name,
          phone: item.phone,
          kind: AdminUserKind.customer,
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
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: FutureBuilder<_AdminSuppliersData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Users yuklanmadi: ${snapshot.error}'),
                ),
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
          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              controller: _scrollController,
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
                      await Navigator.of(context).pushNamed(AppRoutes.adminWerka);
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
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
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
      indent: 18,
      endIndent: 18,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
    );
  }
}
