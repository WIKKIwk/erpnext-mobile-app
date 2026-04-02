import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/native_back_button.dart';
import '../../shared/models/app_models.dart';
import '../state/customer_store.dart';
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
  @override
  void initState() {
    super.initState();
    CustomerStore.instance.bootstrap();
  }

  Future<void> _reload() async {
    await CustomerStore.instance.refresh();
  }

  Future<void> _openDetail(String deliveryNoteID) async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.customerDetail,
      arguments: deliveryNoteID,
    );
    if (changed == true) {
      await _reload();
    }
  }

  String get _title {
    final l10n = context.l10n;
    switch (widget.kind) {
      case CustomerStatusKind.pending:
        return l10n.pendingLabel;
      case CustomerStatusKind.confirmed:
        return l10n.confirmedStatus;
      case CustomerStatusKind.rejected:
        return l10n.rejectedLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showFlutterBackButton = !useNativeBackButton(context);
    return Scaffold(
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
                  if (showFlutterBackButton) ...[
                    NativeBackButtonSlot(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14),
                  ],
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
                child: AnimatedBuilder(
                  animation: CustomerStore.instance,
                  builder: (context, _) {
                    final store = CustomerStore.instance;
                    if (store.loading && !store.loaded) {
                      return const Center(
                        child: AppLoadingIndicator(),
                      );
                    }
                    if (store.error != null && !store.loaded) {
                      return AppRetryState(onRetry: _reload);
                    }
                    final items = store.itemsForKind(widget.kind);
                    if (items.isEmpty) {
                      return Center(
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              context.l10n.noRecordsYet,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      );
                    }
                    return AppRefreshIndicator(
                      onRefresh: _reload,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 110),
                        children: [
                          Card.filled(
                            margin: EdgeInsets.zero,
                            color: scheme.surfaceContainerLow,
                            clipBehavior: Clip.antiAlias,
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
                                    isFirst: index == 0,
                                    isLast: index == items.length - 1,
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
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: CustomerDock(activeTab: null),
        ),
      ),
    );
  }
}

class _CustomerStatusRecordRow extends StatelessWidget {
  const _CustomerStatusRecordRow({
    required this.record,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final DispatchRecord record;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = isFirst || isLast ? 28.0 : 0.0;
    return PressableScale(
      borderRadius: borderRadius,
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
