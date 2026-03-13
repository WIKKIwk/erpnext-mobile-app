import '../../../core/api/mobile_api.dart';
import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaStatusBreakdownScreen extends StatefulWidget {
  const WerkaStatusBreakdownScreen({
    super.key,
    required this.kind,
  });

  final WerkaStatusKind kind;

  @override
  State<WerkaStatusBreakdownScreen> createState() =>
      _WerkaStatusBreakdownScreenState();
}

class _WerkaStatusBreakdownScreenState
    extends State<WerkaStatusBreakdownScreen> {
  late Future<List<WerkaStatusBreakdownEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.werkaStatusBreakdown(widget.kind);
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.werkaStatusBreakdown(widget.kind);
    setState(() {
      _future = future;
    });
    await future;
  }

  String get _title {
    switch (widget.kind) {
      case WerkaStatusKind.pending:
        return 'Jarayonda';
      case WerkaStatusKind.confirmed:
        return 'Tasdiqlangan';
      case WerkaStatusKind.returned:
        return 'Qaytarilgan';
    }
  }

  String _metricLabel(WerkaStatusBreakdownEntry entry) {
    switch (widget.kind) {
      case WerkaStatusKind.pending:
        return '${entry.totalSentQty.toStringAsFixed(0)} ${entry.uom} jarayonda';
      case WerkaStatusKind.confirmed:
        return '${entry.totalAcceptedQty.toStringAsFixed(0)} ${entry.uom} tasdiqlangan';
      case WerkaStatusKind.returned:
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
      bottom: const WerkaDock(activeTab: null),
      child: FutureBuilder<List<WerkaStatusBreakdownEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Status ro‘yxati yuklanmadi: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <WerkaStatusBreakdownEntry>[];
          if (items.isEmpty) {
            return const Center(
              child: SoftCard(
                child: Text('Bu statusda hozircha yozuv yo‘q.'),
              ),
            );
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
                    AppRoutes.werkaStatusDetail,
                    arguments: WerkaStatusDetailArgs(
                      kind: widget.kind,
                      supplierRef: item.supplierRef,
                      supplierName: item.supplierName,
                    ),
                  ),
                  child: SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.supplierName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _metricLabel(item),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${item.receiptCount} ta receipt',
                          style: Theme.of(context).textTheme.bodySmall,
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

class WerkaStatusDetailArgs {
  const WerkaStatusDetailArgs({
    required this.kind,
    required this.supplierRef,
    required this.supplierName,
  });

  final WerkaStatusKind kind;
  final String supplierRef;
  final String supplierName;
}
