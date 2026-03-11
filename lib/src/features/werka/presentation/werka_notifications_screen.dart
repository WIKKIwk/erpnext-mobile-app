import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaNotificationsScreen extends StatefulWidget {
  const WerkaNotificationsScreen({super.key});

  @override
  State<WerkaNotificationsScreen> createState() =>
      _WerkaNotificationsScreenState();
}

class _WerkaNotificationsScreenState extends State<WerkaNotificationsScreen>
    with WidgetsBindingObserver {
  late Future<List<DispatchRecord>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _itemsFuture = MobileApi.instance.werkaHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.werkaHistory();
    setState(() {
      _itemsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Bildirishnomalar',
      subtitle: '',
      bottom: const WerkaDock(activeTab: WerkaDockTab.notifications),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator.adaptive(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bildirishnomalar yuklanmadi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _reload,
                            child: const Text('Qayta urinish'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                return SoftCard(
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
                          _notificationIcon(record.status),
                          color: _notificationColor(record.status),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _notificationTitle(record),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _notificationBody(record),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
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

String _notificationTitle(DispatchRecord record) {
  switch (record.status) {
    case DispatchStatus.pending:
      return record.supplierName;
    case DispatchStatus.accepted:
    case DispatchStatus.partial:
    case DispatchStatus.rejected:
    case DispatchStatus.cancelled:
    case DispatchStatus.draft:
      return record.itemCode;
  }
}

String _notificationBody(DispatchRecord record) {
  final suffix = record.note.trim().isEmpty ? '' : '\n${record.note}';
  switch (record.status) {
    case DispatchStatus.pending:
      return '${record.itemCode} • ${record.sentQty.toStringAsFixed(0)} ${record.uom} qabul kutmoqda.$suffix';
    case DispatchStatus.accepted:
      return '${record.acceptedQty.toStringAsFixed(0)} ${record.uom} qabul qilindi.$suffix';
    case DispatchStatus.partial:
      return 'Qisman qabul qilindi: ${record.acceptedQty.toStringAsFixed(0)} ${record.uom}.$suffix';
    case DispatchStatus.rejected:
      return 'Qabul rad etildi.$suffix';
    case DispatchStatus.cancelled:
      return 'Jarayon bekor qilindi.$suffix';
    case DispatchStatus.draft:
      return 'Draft holatida.$suffix';
  }
}

IconData _notificationIcon(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.pending:
      return Icons.notifications_active_rounded;
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
  }
}

Color _notificationColor(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.pending:
      return const Color(0xFFFFD54F);
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
  }
}
