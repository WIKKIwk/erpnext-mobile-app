import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'supplier_status_detail_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierStatusBreakdownScreen extends StatefulWidget {
  const SupplierStatusBreakdownScreen({
    super.key,
    required this.kind,
  });

  final SupplierStatusKind kind;

  @override
  State<SupplierStatusBreakdownScreen> createState() =>
      _SupplierStatusBreakdownScreenState();
}

class _SupplierStatusBreakdownScreenState
    extends State<SupplierStatusBreakdownScreen> {
  late Future<List<SupplierStatusBreakdownEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.supplierStatusBreakdown(widget.kind);
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.supplierStatusBreakdown(widget.kind);
    setState(() => _future = future);
    await future;
  }

  String get _title {
    switch (widget.kind) {
      case SupplierStatusKind.pending:
        return 'Jarayonda';
      case SupplierStatusKind.submitted:
        return 'Submit';
      case SupplierStatusKind.returned:
        return 'Qaytarilgan';
    }
  }

  String _metricLabel(SupplierStatusBreakdownEntry entry) {
    switch (widget.kind) {
      case SupplierStatusKind.pending:
        return '${entry.totalSentQty.toStringAsFixed(0)} ${entry.uom} jarayonda';
      case SupplierStatusKind.submitted:
        return '${entry.totalAcceptedQty.toStringAsFixed(0)} ${entry.uom} submit';
      case SupplierStatusKind.returned:
        return '${entry.totalReturnedQty.toStringAsFixed(0)} ${entry.uom} qaytarilgan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _title,
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const SupplierDock(activeTab: null),
      child: FutureBuilder<List<SupplierStatusBreakdownEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: SoftCard(child: Text('${snapshot.error}')));
          }
          final items = snapshot.data ?? const <SupplierStatusBreakdownEntry>[];
          if (items.isEmpty) {
            return const Center(child: SoftCard(child: Text('Hozircha yozuv yo‘q.')));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return PressableScale(
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.supplierStatusDetail,
                    arguments: SupplierStatusDetailArgs(
                      kind: widget.kind,
                      itemCode: item.itemCode,
                      itemName: item.itemName,
                    ),
                  ),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.itemName, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        Text(_metricLabel(item), style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('${item.receiptCount} ta receipt', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
