import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'widgets/customer_dock.dart';
import 'package:flutter/material.dart';

class CustomerStatusDetailScreen extends StatefulWidget {
  const CustomerStatusDetailScreen({
    super.key,
    required this.kind,
  });

  final CustomerStatusKind kind;

  @override
  State<CustomerStatusDetailScreen> createState() =>
      _CustomerStatusDetailScreenState();
}

class _CustomerStatusDetailScreenState
    extends State<CustomerStatusDetailScreen> {
  late Future<List<DispatchRecord>> _future;
  bool _didMutate = false;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.customerStatusDetails(widget.kind);
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.customerStatusDetails(widget.kind);
    setState(() => _future = future);
    await future;
  }

  Future<void> _openDetail(String deliveryNoteID) async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.customerDetail,
      arguments: deliveryNoteID,
    );
    if (changed == true) {
      _didMutate = true;
      await _reload();
    }
  }

  String get _title {
    switch (widget.kind) {
      case CustomerStatusKind.pending:
        return 'Kutilmoqda';
      case CustomerStatusKind.confirmed:
        return 'Tasdiqlangan';
      case CustomerStatusKind.rejected:
        return 'Rad etilgan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_didMutate);
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.shellStart(context),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Row(
                  children: [
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(_didMutate),
                        icon: const Icon(Icons.arrow_back_rounded, size: 28),
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _title,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
                child: FutureBuilder<List<DispatchRecord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text('${snapshot.error}'),
                          ),
                        ),
                      );
                    }
                    final items = snapshot.data ?? const <DispatchRecord>[];
                    if (items.isEmpty) {
                      return Center(
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'Hozircha yozuv yo‘q.',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator.adaptive(
                      onRefresh: _reload,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 110),
                        children: [
                          Card.filled(
                            margin: EdgeInsets.zero,
                            color: scheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              children: [
                                for (int index = 0;
                                    index < items.length;
                                    index++) ...[
                                  _CustomerStatusRecordRow(
                                    record: items[index],
                                    onTap: () => _openDetail(items[index].id),
                                  ),
                                  if (index != items.length - 1)
                                    const Divider(height: 1, thickness: 1),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 24, 0),
            child: CustomerDock(activeTab: null),
          ),
        ),
      ),
    );
  }
}

class _CustomerStatusRecordRow extends StatelessWidget {
  const _CustomerStatusRecordRow({
    required this.record,
    required this.onTap,
  });

  final DispatchRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    record.itemName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  record.createdLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
              style: theme.textTheme.headlineMedium,
            ),
            if (record.note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.note,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
