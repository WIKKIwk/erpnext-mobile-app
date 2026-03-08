import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatelessWidget {
  const SupplierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Supplier',
      subtitle: 'Jo‘natish va statuslarni shu yerdan boshqarasiz.',
      bottom: const SupplierDock(activeTab: SupplierDockTab.home),
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<DispatchRecord>>(
              future: MobileApi.instance.supplierHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: SoftCard(
                      child: Text(
                          'Supplier history yuklanmadi: ${snapshot.error}'),
                    ),
                  );
                }

                final history = snapshot.data ?? <DispatchRecord>[];

                return Column(
                  children: [
                    SmoothAppear(
                      child: Row(
                        children: [
                          Expanded(
                            child: MetricBadge(
                              label: 'Pending',
                              value: history
                                  .where((item) =>
                                      item.status == DispatchStatus.pending)
                                  .length
                                  .toString(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricBadge(
                              label: 'Qabul qilingan',
                              value: history
                                  .where((item) =>
                                      item.status == DispatchStatus.accepted)
                                  .length
                                  .toString(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final DispatchRecord record = history[index];
                          return SmoothAppear(
                            delay: Duration(milliseconds: 60 + (index * 70)),
                            offset: const Offset(0, 18),
                            child: PressableScale(
                              child: SoftCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            record.itemCode,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                        ),
                                        StatusPill(status: record.status),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(record.itemName),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(fontSize: 28),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(record.createdLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
