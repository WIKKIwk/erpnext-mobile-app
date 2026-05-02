import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/m3_confirm_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminSupplierItemsViewScreen extends StatefulWidget {
  const AdminSupplierItemsViewScreen({
    super.key,
    required this.supplierRef,
  });

  final String supplierRef;

  @override
  State<AdminSupplierItemsViewScreen> createState() =>
      _AdminSupplierItemsViewScreenState();
}

class _AdminSupplierItemsViewScreenState
    extends State<AdminSupplierItemsViewScreen> {
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
      final assigned = await MobileApi.instance
          .adminAssignedSupplierItems(widget.supplierRef);
      if (!mounted) {
        return;
      }
      setState(() {
        supplierName = detail.name;
        items = assigned;
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _removeItem(SupplierItem item) async {
    final confirm = await showM3ConfirmDialog(
      context: context,
      title: 'Mahsulotni uzish',
      message: '${item.name} mahsulotini supplierdan uzaymi?',
      cancelLabel: 'Yo‘q',
      confirmLabel: 'Ha',
    );
    if (confirm != true) {
      return;
    }

    setState(() => mutating = true);
    try {
      await MobileApi.instance.adminRemoveSupplierItem(
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
      title: 'Biriktirilgan mahsulotlar',
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
                actionIcon: Icons.remove_rounded,
                emptyText: 'Hozircha mahsulot biriktirilmagan.',
                onActionTap: mutating ? null : _removeItem,
              ),
      ),
    );
  }
}

class ItemsTable extends StatelessWidget {
  const ItemsTable({
    super.key,
    required this.items,
    required this.actionIcon,
    required this.emptyText,
    required this.onActionTap,
  });

  final List<SupplierItem> items;
  final IconData actionIcon;
  final String emptyText;
  final ValueChanged<SupplierItem>? onActionTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: SoftCard(
          child: Text(
            emptyText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const ItemsTableHeader(),
            ...items.map(
              (item) => AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item.name)),
                          Expanded(flex: 2, child: Text(item.code)),
                          SizedBox(
                            width: 44,
                            child: IconButton(
                              onPressed: onActionTap == null
                                  ? null
                                  : () => onActionTap!(item),
                              icon: Icon(actionIcon),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemsTableHeader extends StatelessWidget {
  const ItemsTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child:
                Text('Mahsulot', style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: Text('Kod', style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}
