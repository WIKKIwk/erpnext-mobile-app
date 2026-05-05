import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierStatusDetailArgs {
  const SupplierStatusDetailArgs({
    required this.kind,
    required this.itemCode,
    required this.itemName,
  });

  final SupplierStatusKind kind;
  final String itemCode;
  final String itemName;
}

class SupplierStatusDetailScreen extends StatefulWidget {
  const SupplierStatusDetailScreen({
    super.key,
    required this.args,
  });

  final SupplierStatusDetailArgs args;

  @override
  State<SupplierStatusDetailScreen> createState() =>
      _SupplierStatusDetailScreenState();
}

class _SupplierStatusDetailScreenState
    extends State<SupplierStatusDetailScreen> {
  @override
  void initState() {
    super.initState();
    SupplierStore.instance
        .bootstrapDetail(widget.args.kind, widget.args.itemCode);
  }

  Future<void> _reload() async {
    await SupplierStore.instance
        .refreshDetail(widget.args.kind, widget.args.itemCode);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: widget.args.itemName,
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const SupplierDock(activeTab: null),
      child: AnimatedBuilder(
        animation: SupplierStore.instance,
        builder: (context, _) {
          final store = SupplierStore.instance;
          if (store.loadingDetail(widget.args.kind, widget.args.itemCode) &&
              store
                  .detailItems(widget.args.kind, widget.args.itemCode)
                  .isEmpty) {
            return const Center(child: AppLoadingIndicator());
          }
          final error =
              store.detailError(widget.args.kind, widget.args.itemCode);
          if (error != null &&
              store
                  .detailItems(widget.args.kind, widget.args.itemCode)
                  .isEmpty) {
            return Center(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text('$error'),
                ),
              ),
            );
          }
          final items =
              store.detailItems(widget.args.kind, widget.args.itemCode);
          if (items.isEmpty) {
            return Center(child: Text(context.l10n.noSupplierReceiptsYet));
          }
          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Card.filled(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      for (int index = 0; index < items.length; index++) ...[
                        Builder(builder: (context) {
                          final record = items[index];
                          return InkWell(
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.notificationDetail,
                              arguments: record.id,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        record.createdLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  if (record.acceptedQty > 0) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      context.l10n.acceptedQtyLabel(
                                        record.acceptedQty,
                                        record.uom,
                                      ),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  if (record.note.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      record.note,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                        if (index != items.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 18,
                            endIndent: 18,
                            color: Theme.of(context)
                                .dividerColor
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
    );
  }
}
