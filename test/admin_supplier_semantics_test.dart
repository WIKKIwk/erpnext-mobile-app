import 'package:erpnext_stock_mobile/src/features/admin/presentation/widgets/admin_dock.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/widgets/admin_supplier_list_module.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:erpnext_stock_mobile/src/core/widgets/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin supplier list builds with semantics enabled',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AdminSupplierListModule(
            items: const [
              AdminUserListEntry(
                id: '1',
                name: 'Werka',
                phone: '',
                kind: AdminUserKind.werka,
              ),
              AdminUserListEntry(
                id: '2',
                name: 'Supplier one',
                phone: '',
                kind: AdminUserKind.supplier,
              ),
              AdminUserListEntry(
                id: '3',
                name: 'Customer one',
                phone: '',
                kind: AdminUserKind.customer,
              ),
            ],
            onTapUser: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin supplier shell builds with dock semantics enabled',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AppShell(
          title: 'Suppliers',
          subtitle: '',
          bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AdminSupplierListModule(
                items: const [
                  AdminUserListEntry(
                    id: '1',
                    name: 'Werka',
                    phone: '',
                    kind: AdminUserKind.werka,
                  ),
                  AdminUserListEntry(
                    id: '2',
                    name: 'Supplier one',
                    phone: '',
                    kind: AdminUserKind.supplier,
                  ),
                  AdminUserListEntry(
                    id: '3',
                    name: 'Customer one',
                    phone: '',
                    kind: AdminUserKind.customer,
                  ),
                ],
                onTapUser: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}
