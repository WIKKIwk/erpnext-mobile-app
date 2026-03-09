import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierNotificationsScreen extends StatelessWidget {
  const SupplierNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notifications',
      subtitle: 'Werka mahsulotni oldimi yoki yo‘qmi, shu yerda ko‘rasiz.',
      bottom: const SupplierDock(activeTab: SupplierDockTab.notifications),
      child: FutureBuilder<List<DispatchRecord>>(
        future: MobileApi.instance.supplierHistory(),
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

          return ListView.separated(
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
                          color: Color(0xFF111111),
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
                            const SizedBox(height: 10),
                            StatusPill(status: record.status),
                          ],
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

String notificationTitle(DispatchRecord record) {
  switch (record.status) {
    case DispatchStatus.accepted:
      return '${record.itemCode} qabul qilindi';
    case DispatchStatus.partial:
      return '${record.itemCode} qisman qabul qilindi';
    case DispatchStatus.rejected:
      return '${record.itemCode} rad etildi';
    case DispatchStatus.cancelled:
      return '${record.itemCode} bekor qilindi';
    case DispatchStatus.draft:
      return '${record.itemCode} draft holatda';
    case DispatchStatus.pending:
      return '${record.itemCode} hali kutilmoqda';
  }
}

String notificationBody(DispatchRecord record) {
  switch (record.status) {
    case DispatchStatus.accepted:
      return 'Werka ${record.acceptedQty.toStringAsFixed(0)} ${record.uom} qabul qildi.';
    case DispatchStatus.partial:
      return 'Werka ${record.acceptedQty.toStringAsFixed(0)} ${record.uom} qabul qildi, qolgan qismi hali yopilmagan.';
    case DispatchStatus.rejected:
      return 'Jo‘natish rad etildi. Tafsilotni tekshiring.';
    case DispatchStatus.cancelled:
      return 'Jo‘natish bekor qilindi.';
    case DispatchStatus.draft:
      return 'Hujjat hali draft bosqichida turibdi.';
    case DispatchStatus.pending:
      return 'Werka hali qabul qilishni yakunlamagan.';
  }
}

IconData notificationIcon(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.accepted:
      return Icons.check_circle_rounded;
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
