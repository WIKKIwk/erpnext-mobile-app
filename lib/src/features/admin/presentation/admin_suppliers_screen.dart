import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
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
  late Future<List<AdminUserListEntry>> _future;

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

  Future<List<AdminUserListEntry>> _loadUsers() async {
    final results = await Future.wait<dynamic>([
      MobileApi.instance.adminSuppliers(),
      MobileApi.instance.adminSettings(),
    ]);
    final List<AdminSupplier> suppliers = results[0] as List<AdminSupplier>;
    final AdminSettings settings = results[1] as AdminSettings;

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
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Users',
      subtitle: 'Supplier va werka ro‘yxati.',
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: FutureBuilder<List<AdminUserListEntry>>(
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
          final items = snapshot.data ?? const <AdminUserListEntry>[];
          return RefreshIndicator(
            onRefresh: _reload,
            child: AdminSupplierListModule(
              items: items,
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
          );
        },
      ),
    );
  }
}
