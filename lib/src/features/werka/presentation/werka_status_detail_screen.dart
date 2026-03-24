import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
import 'werka_status_breakdown_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaStatusDetailScreen extends StatefulWidget {
  const WerkaStatusDetailScreen({
    super.key,
    required this.args,
  });

  final WerkaStatusDetailArgs args;

  @override
  State<WerkaStatusDetailScreen> createState() =>
      _WerkaStatusDetailScreenState();
}

class _WerkaStatusDetailScreenState extends State<WerkaStatusDetailScreen> {
  @override
  void initState() {
    super.initState();
    WerkaStore.instance
        .bootstrapDetail(widget.args.kind, widget.args.supplierRef);
  }

  Future<void> _reload() async {
    await WerkaStore.instance
        .refreshDetail(widget.args.kind, widget.args.supplierRef);
  }

  String get _title {
    final l10n = context.l10n;
    switch (widget.args.kind) {
      case WerkaStatusKind.pending:
        return l10n.statusWithName(
            widget.args.supplierName, l10n.pendingStatus);
      case WerkaStatusKind.confirmed:
        return l10n.statusWithName(
            widget.args.supplierName, l10n.confirmedStatus);
      case WerkaStatusKind.returned:
        return l10n.statusWithName(
            widget.args.supplierName, l10n.returnedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
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
                child: AnimatedBuilder(
                  animation: WerkaStore.instance,
                  builder: (context, _) {
                    final store = WerkaStore.instance;
                    if (store.loadingDetail(
                            widget.args.kind, widget.args.supplierRef) &&
                        store
                            .detailItems(
                                widget.args.kind, widget.args.supplierRef)
                            .isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final error = store.detailError(
                        widget.args.kind, widget.args.supplierRef);
                    if (error != null &&
                        store
                            .detailItems(
                                widget.args.kind, widget.args.supplierRef)
                            .isEmpty) {
                      return AppRetryState(
                        onRetry: _reload,
                      );
                    }

                    final items = store.detailItems(
                        widget.args.kind, widget.args.supplierRef);
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
                                  _WerkaStatusRecordRow(
                                    record: items[index],
                                    isFirst: index == 0,
                                    isLast: index == items.length - 1,
                                    onTap: () => _openRecord(items[index]),
                                  ),
                                  if (index != items.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: scheme.outlineVariant
                                          .withValues(alpha: 0.55),
                                    ),
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
          child: WerkaDock(activeTab: null),
        ),
      ),
    );
  }

  void _openRecord(DispatchRecord record) {
    if (record.isDeliveryNote) {
      Navigator.of(context).pushNamed(
        AppRoutes.werkaCustomerDeliveryDetail,
        arguments: record,
      );
      return;
    }
    if (widget.args.kind == WerkaStatusKind.pending) {
      Navigator.of(context)
          .pushNamed(
        AppRoutes.werkaDetail,
        arguments: record,
      )
          .then((_) {
        if (!mounted) {
          return;
        }
        _reload();
      });
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.notificationDetail,
      arguments: record.id,
    );
  }
}

class _WerkaStatusRecordRow extends StatelessWidget {
  const _WerkaStatusRecordRow({
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
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 28 : 0),
      topRight: Radius.circular(isFirst ? 28 : 0),
      bottomLeft: Radius.circular(isLast ? 28 : 0),
      bottomRight: Radius.circular(isLast ? 28 : 0),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.itemName.trim().isEmpty
                          ? record.itemCode
                          : record.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    if (record.note.trim().isNotEmpty)
                      Text(
                        record.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else if (record.acceptedQty > 0)
                      Text(
                        context.l10n.acceptedQtyLabel(
                          record.acceptedQty,
                          record.uom,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.createdLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
