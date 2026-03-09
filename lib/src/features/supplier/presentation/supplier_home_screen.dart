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
                final pendingCount = history
                    .where((item) => item.status == DispatchStatus.pending)
                    .length;
                final acceptedCount = history
                    .where((item) => item.status == DispatchStatus.accepted)
                    .length;
                final totalQty = history.fold<double>(
                  0,
                  (sum, item) => sum + item.sentQty,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmoothAppear(
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: MetricBadge(
                                    label: 'Pending',
                                    value: pendingCount.toString(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: MetricBadge(
                                    label: 'Qabul qilingan',
                                    value: acceptedCount.toString(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: MetricBadge(
                                    label: 'Jami',
                                    value: totalQty.toStringAsFixed(0),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Jarayonlar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Color(0xFF1F1F1F),
                        ),
                        itemBuilder: (context, index) {
                          final DispatchRecord record = history[index];
                          return SmoothAppear(
                            delay: Duration(milliseconds: 60 + (index * 70)),
                            offset: const Offset(0, 18),
                            child: PressableScale(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.itemName.isEmpty
                                                ? record.itemCode
                                                : record.itemName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            record.createdLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    StatusPill(status: record.status),
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
