import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierNotificationsScreen extends StatefulWidget {
  const SupplierNotificationsScreen({super.key});

  @override
  State<SupplierNotificationsScreen> createState() =>
      _SupplierNotificationsScreenState();
}

class _SupplierNotificationsScreenState
    extends State<SupplierNotificationsScreen> {
  late Future<List<DispatchRecord>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = MobileApi.instance.supplierHistory();
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.supplierHistory();
    setState(() {
      _itemsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notifications',
      subtitle: 'Werka mahsulotni oldimi yoki yo‘qmi, shu yerda ko‘rasiz.',
      bottom: const SupplierDock(activeTab: SupplierDockTab.notifications),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('Notifications yuklanmadi: ${snapshot.error}'),
              ),
            );
          }

          final items = snapshot.data ?? <DispatchRecord>[];
          if (items.isEmpty) {
            return const Center(
              child: SoftCard(
                child: Text('Hali bildirishnomalar yo‘q.'),
              ),
            );
          }

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = items[index];
                return SmoothAppear(
                  delay: Duration(milliseconds: 40 + (index * 45)),
                  child: SoftCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notificationIcon(record.status),
                            color: notificationColor(record.status),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notificationTitle(record),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notificationBody(record),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
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

String notificationTitle(DispatchRecord record) {
  switch (record.status) {
    case DispatchStatus.accepted:
      return record.itemCode;
    case DispatchStatus.partial:
      return record.itemCode;
    case DispatchStatus.rejected:
      return record.itemCode;
    case DispatchStatus.cancelled:
      return record.itemCode;
    case DispatchStatus.draft:
      return record.itemCode;
    case DispatchStatus.pending:
      return record.itemCode;
  }
}

String notificationBody(DispatchRecord record) {
  switch (record.status) {
    case DispatchStatus.accepted:
      return 'Werka ${record.acceptedQty.toStringAsFixed(0)} ${record.uom} oldi.';
    case DispatchStatus.partial:
      return 'Qisman olindi: ${record.acceptedQty.toStringAsFixed(0)} ${record.uom}.';
    case DispatchStatus.rejected:
      return 'Rad etildi.';
    case DispatchStatus.cancelled:
      return 'Bekor qilindi.';
    case DispatchStatus.draft:
      return 'Draft holatda.';
    case DispatchStatus.pending:
      return 'Hali kutilmoqda.';
  }
}

IconData notificationIcon(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.accepted:
      return Icons.check_rounded;
    case DispatchStatus.partial:
      return Icons.timelapse_rounded;
    case DispatchStatus.rejected:
      return Icons.cancel_rounded;
    case DispatchStatus.cancelled:
      return Icons.block_rounded;
    case DispatchStatus.draft:
      return Icons.edit_note_rounded;
    case DispatchStatus.pending:
      return Icons.notifications_active_rounded;
  }
}

Color notificationColor(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.accepted:
      return const Color(0xFF5BB450);
    case DispatchStatus.partial:
      return const Color(0xFF2A6FDB);
    case DispatchStatus.rejected:
      return const Color(0xFFC53B30);
    case DispatchStatus.cancelled:
      return const Color(0xFF9CA3AF);
    case DispatchStatus.draft:
      return const Color(0xFFA78BFA);
    case DispatchStatus.pending:
      return const Color(0xFFFFD54F);
  }
}
