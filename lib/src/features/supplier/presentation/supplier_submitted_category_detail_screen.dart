import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

enum SupplierSubmittedCategory {
  pendingDispatches,
  pendingUnannounced,
  acceptedByWerka,
  approvedUnannounced,
}

class SupplierSubmittedCategoryArgs {
  const SupplierSubmittedCategoryArgs({
    required this.category,
  });

  final SupplierSubmittedCategory category;
}

class SupplierSubmittedCategoryDetailScreen extends StatefulWidget {
  const SupplierSubmittedCategoryDetailScreen({
    super.key,
    required this.args,
  });

  final SupplierSubmittedCategoryArgs args;

  @override
  State<SupplierSubmittedCategoryDetailScreen> createState() =>
      _SupplierSubmittedCategoryDetailScreenState();
}

class _SupplierSubmittedCategoryDetailScreenState
    extends State<SupplierSubmittedCategoryDetailScreen> {
  bool _isApprovedUnannounced(DispatchRecord item) {
    final note = item.note.trim().toLowerCase();
    return item.eventType == 'werka_unannounced_approved' ||
        note.startsWith('aytilmagan mol tasdiqlandi') ||
        note.startsWith('unannounced item approved');
  }

  @override
  void initState() {
    super.initState();
    SupplierStore.instance.bootstrapHistory();
  }

  Future<void> _reload() async {
    await SupplierStore.instance.refreshHistory();
  }

  String get _title {
    switch (widget.args.category) {
      case SupplierSubmittedCategory.pendingDispatches:
        return context.l10n.supplierPendingDispatchesTitle;
      case SupplierSubmittedCategory.pendingUnannounced:
        return context.l10n.supplierPendingUnannouncedTitle;
      case SupplierSubmittedCategory.acceptedByWerka:
        return context.l10n.supplierAcceptedByWerkaTitle;
      case SupplierSubmittedCategory.approvedUnannounced:
        return context.l10n.supplierAcceptedUnannouncedTitle;
    }
  }

  List<DispatchRecord> _items() {
    switch (widget.args.category) {
      case SupplierSubmittedCategory.pendingDispatches:
        return SupplierStore.instance.historyItems
            .where(
              (item) =>
                  (item.status == DispatchStatus.pending ||
                      item.status == DispatchStatus.draft) &&
                  item.eventType != 'werka_unannounced_pending',
            )
            .toList();
      case SupplierSubmittedCategory.pendingUnannounced:
        return SupplierStore.instance.historyItems
            .where(
              (item) =>
                  (item.status == DispatchStatus.pending ||
                      item.status == DispatchStatus.draft) &&
                  item.eventType == 'werka_unannounced_pending',
            )
            .toList();
      case SupplierSubmittedCategory.acceptedByWerka:
        final all = SupplierStore.instance.historyItems.where(
          (item) => item.status == DispatchStatus.accepted,
        );
        return all.where((item) => !_isApprovedUnannounced(item)).toList();
      case SupplierSubmittedCategory.approvedUnannounced:
        final all = SupplierStore.instance.historyItems.where(
          (item) => item.status == DispatchStatus.accepted,
        );
        return all.where(_isApprovedUnannounced).toList();
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
      bottom: const SupplierDock(activeTab: null),
      child: AnimatedBuilder(
        animation: SupplierStore.instance,
        builder: (context, _) {
          final store = SupplierStore.instance;
          final items = _items();
          if (store.loadingHistory && !store.loadedHistory) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.historyError != null && !store.loadedHistory) {
            return Center(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text('${store.historyError}'),
                ),
              ),
            );
          }
          if (items.isEmpty) {
            return Center(child: Text(context.l10n.noRecordsYet));
          }
          return RefreshIndicator.adaptive(
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
                            child: SizedBox(
                              width: double.infinity,
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
                                    if (record.note.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        record.note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
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
