import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierStatusDetailArgs {
  const SupplierStatusDetailArgs({
    required this.kind,
    required this.itemCode,
    required this.itemName,
  });

  final SupplierStatusKind kind;
  final String itemCode;
  final String itemName;
}

class SupplierStatusDetailScreen extends StatefulWidget {
  const SupplierStatusDetailScreen({
    super.key,
    required this.args,
  });

  final SupplierStatusDetailArgs args;

  @override
  State<SupplierStatusDetailScreen> createState() =>
      _SupplierStatusDetailScreenState();
}

class _SupplierStatusDetailScreenState extends State<SupplierStatusDetailScreen> {
  late Future<List<DispatchRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.supplierStatusDetails(
      kind: widget.args.kind,
      itemCode: widget.args.itemCode,
    );
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.supplierStatusDetails(
      kind: widget.args.kind,
      itemCode: widget.args.itemCode,
    );
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: widget.args.itemName,
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const SupplierDock(activeTab: null),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: SoftCard(child: Text('${snapshot.error}')));
          }
          final items = snapshot.data ?? const <DispatchRecord>[];
          if (items.isEmpty) {
            return const Center(child: SoftCard(child: Text('Hozircha receipt yo‘q.')));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = items[index];
                return PressableScale(
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.notificationDetail,
                    arguments: record.id,
                  ),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${record.sentQty.toStringAsFixed(0)} ${record.uom}', style: Theme.of(context).textTheme.headlineMedium),
                        if (record.acceptedQty > 0) ...[
                          const SizedBox(height: 6),
                          Text('Qabul: ${record.acceptedQty.toStringAsFixed(0)} ${record.uom}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (record.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(record.note, style: Theme.of(context).textTheme.bodySmall),
                        ],
                        const SizedBox(height: 8),
                        Text(record.createdLabel, style: Theme.of(context).textTheme.bodySmall),
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
