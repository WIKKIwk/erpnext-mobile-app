import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierRecentScreen extends StatelessWidget {
  const SupplierRecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Recent',
      subtitle: 'Supplier qilgan avvalgi harakatlar.',
      bottom: const SupplierDock(activeTab: SupplierDockTab.recent),
      child: FutureBuilder<List<DispatchRecord>>(
        future: MobileApi.instance.supplierHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('Recent yuklanmadi: ${snapshot.error}'),
              ),
            );
          }

          final items = snapshot.data ?? <DispatchRecord>[];
          if (items.isEmpty) {
            return const Center(
              child: SoftCard(
                child: Text('Hali jo‘natishlar yo‘q.'),
              ),
            );
          }

          return ListView.separated(
            itemCount: items.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SoftCard(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Mahsulot')),
                      Expanded(flex: 2, child: Text('Miqdor')),
                      Expanded(flex: 2, child: Text('Holat')),
                    ],
                  ),
                );
              }

              final record = items[index - 1];
              return SmoothAppear(
                delay: Duration(milliseconds: 40 + (index * 40)),
                child: SoftCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.itemCode,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(record.itemName,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            '${record.sentQty.toStringAsFixed(0)} ${record.uom}'),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusPill(status: record.status),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
