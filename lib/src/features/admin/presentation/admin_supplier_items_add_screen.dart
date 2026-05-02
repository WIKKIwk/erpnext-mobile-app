import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/m3_confirm_dialog.dart';
import '../../shared/models/app_models.dart';
import 'admin_supplier_items_view_screen.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminSupplierItemsAddScreen extends StatefulWidget {
  const AdminSupplierItemsAddScreen({
    super.key,
    required this.supplierRef,
  });

  final String supplierRef;

  @override
  State<AdminSupplierItemsAddScreen> createState() =>
      _AdminSupplierItemsAddScreenState();
}

class _AdminSupplierItemsAddScreenState
    extends State<AdminSupplierItemsAddScreen> {
  bool loading = true;
  bool mutating = false;
  String supplierName = '';
  List<SupplierItem> items = const <SupplierItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final detail =
          await MobileApi.instance.adminSupplierDetail(widget.supplierRef);
      final allItems = await MobileApi.instance.adminItems();
      final assignedCodes =
          detail.assignedItems.map((item) => item.code).toSet();
      if (!mounted) {
        return;
      }
      setState(() {
        supplierName = detail.name;
        items = allItems
            .where((item) => !assignedCodes.contains(item.code))
            .toList();
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _addItem(SupplierItem item) async {
    final confirm = await showM3ConfirmDialog(
      context: context,
      title: 'Mahsulotni biriktirish',
      message: '${item.name} mahsulotini supplierga biriktiraymi?',
      cancelLabel: 'Yo‘q',
      confirmLabel: 'Ha',
    );
    if (confirm != true) {
      return;
    }

    setState(() => mutating = true);
    try {
      await MobileApi.instance.adminAssignSupplierItem(
        ref: widget.supplierRef,
        itemCode: item.code,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        items = items.where((current) => current.code != item.code).toList();
      });
    } finally {
      if (mounted) {
        setState(() => mutating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Mahsulot qo‘shish',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: loading
            ? const Center(child: AppLoadingIndicator())
            : ItemsTable(
                items: items,
                actionIcon: Icons.add_rounded,
                emptyText: 'Biriktirilmagan mahsulot topilmadi.',
                onActionTap: mutating ? null : _addItem,
              ),
      ),
    );
  }
}
