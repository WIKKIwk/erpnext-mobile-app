import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/m3_segmented_list.dart';
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
        _AdminSummarySegmentCard(
          slot: M3SegmentVerticalSlot.top,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          label: 'Jami supplierlar',
          value: summary.totalSuppliers.toString(),
        ),
        _AdminSummarySegmentCard(
          slot: M3SegmentVerticalSlot.middle,
          cornerRadius: M3SegmentedListGeometry.cornerMiddle,
          label: 'Faol supplierlar',
          value: summary.activeSuppliers.toString(),
        ),
        _AdminSummarySegmentCard(
          slot: M3SegmentVerticalSlot.bottom,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          label: 'Bloklangan supplierlar',
          value: summary.blockedSuppliers.toString(),
          onTap: onTapBlocked,
        ),
      ],
    );
  }
}

class _AdminSummarySegmentCard extends StatelessWidget {
  const _AdminSummarySegmentCard({
    required this.slot,
    required this.cornerRadius,
    required this.label,
    required this.value,
    this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final double cornerRadius;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final BorderRadius radius =
        M3SegmentedListGeometry.borderRadius(slot, cornerRadius);
    final Color bg = switch (theme.brightness) {
      Brightness.dark => scheme.surfaceContainerLow,
      Brightness.light => scheme.surfaceContainerHighest,
    };
    final Color foreground = scheme.onSurface;
    final Color accent = scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supplierlar bo‘limi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  value,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
