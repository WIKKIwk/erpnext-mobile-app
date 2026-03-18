import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'supplier_submitted_category_detail_screen.dart';
import 'supplier_status_detail_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierStatusBreakdownScreen extends StatefulWidget {
  const SupplierStatusBreakdownScreen({
    super.key,
    required this.kind,
  });

  final SupplierStatusKind kind;

  @override
  State<SupplierStatusBreakdownScreen> createState() =>
      _SupplierStatusBreakdownScreenState();
}

class _SupplierStatusBreakdownScreenState
    extends State<SupplierStatusBreakdownScreen> {
  bool _isApprovedUnannounced(DispatchRecord item) {
    final note = item.note.trim().toLowerCase();
    return item.eventType == 'werka_unannounced_approved' ||
        note.startsWith('aytilmagan mol tasdiqlandi') ||
        note.startsWith('unannounced item approved');
  }

  @override
  void initState() {
    super.initState();
    SupplierStore.instance.bootstrapBreakdown(widget.kind);
    if (widget.kind == SupplierStatusKind.submitted ||
        widget.kind == SupplierStatusKind.pending) {
      SupplierStore.instance.bootstrapHistory();
    }
  }

  Future<void> _reload() async {
    if (widget.kind == SupplierStatusKind.submitted ||
        widget.kind == SupplierStatusKind.pending) {
      await SupplierStore.instance.refreshHistory();
      return;
    }
    await SupplierStore.instance.refreshBreakdown(widget.kind);
  }

  String get _title {
    final l10n = AppLocalizations.of(context);
    switch (widget.kind) {
      case SupplierStatusKind.pending:
        return l10n.pendingStatus;
      case SupplierStatusKind.submitted:
        return l10n.submittedStatus;
      case SupplierStatusKind.returned:
        return l10n.returnedStatus;
    }
  }

  String _metricLabel(SupplierStatusBreakdownEntry entry) {
    final l10n = AppLocalizations.of(context);
    switch (widget.kind) {
      case SupplierStatusKind.pending:
        return l10n.sentQtyStatus(
          entry.totalSentQty,
          entry.uom,
          l10n.pendingStatus.toLowerCase(),
        );
      case SupplierStatusKind.submitted:
        return l10n.sentQtyStatus(
          entry.totalAcceptedQty,
          entry.uom,
          l10n.submittedStatus.toLowerCase(),
        );
      case SupplierStatusKind.returned:
        return l10n.sentQtyStatus(
          entry.totalReturnedQty,
          entry.uom,
          l10n.returnedStatus.toLowerCase(),
        );
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
          if (widget.kind == SupplierStatusKind.pending ||
              widget.kind == SupplierStatusKind.submitted) {
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
            final pending = store.historyItems.where(
              (item) =>
                  item.status == DispatchStatus.pending ||
                  item.status == DispatchStatus.draft,
            );
            final pendingDispatches = pending
                .where((item) => item.eventType != 'werka_unannounced_pending')
                .length;
            final pendingUnannounced = pending
                .where((item) => item.eventType == 'werka_unannounced_pending')
                .length;
            final accepted = store.historyItems.where(
              (item) => item.status == DispatchStatus.accepted,
            );
            final acceptedByWerka =
                accepted.where((item) => !_isApprovedUnannounced(item)).length;
            final approvedUnannounced =
                accepted.where(_isApprovedUnannounced).length;
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        if (widget.kind == SupplierStatusKind.pending) ...[
                          _SupplierAcceptedCategoryRow(
                            title: context.l10n.supplierPendingDispatchesTitle,
                            count: pendingDispatches,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.supplierSubmittedCategoryDetail,
                              arguments: const SupplierSubmittedCategoryArgs(
                                category:
                                    SupplierSubmittedCategory.pendingDispatches,
                              ),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          _SupplierAcceptedCategoryRow(
                            title: context.l10n.supplierPendingUnannouncedTitle,
                            count: pendingUnannounced,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.supplierSubmittedCategoryDetail,
                              arguments: const SupplierSubmittedCategoryArgs(
                                category: SupplierSubmittedCategory
                                    .pendingUnannounced,
                              ),
                            ),
                          ),
                        ] else ...[
                          _SupplierAcceptedCategoryRow(
                            title: context.l10n.supplierAcceptedByWerkaTitle,
                            count: acceptedByWerka,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.supplierSubmittedCategoryDetail,
                              arguments: const SupplierSubmittedCategoryArgs(
                                category:
                                    SupplierSubmittedCategory.acceptedByWerka,
                              ),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1),
                          _SupplierAcceptedCategoryRow(
                            title:
                                context.l10n.supplierAcceptedUnannouncedTitle,
                            count: approvedUnannounced,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.supplierSubmittedCategoryDetail,
                              arguments: const SupplierSubmittedCategoryArgs(
                                category: SupplierSubmittedCategory
                                    .approvedUnannounced,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          if (store.loadingBreakdown(widget.kind) &&
              store.breakdownItems(widget.kind).isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = store.breakdownError(widget.kind);
          if (error != null && store.breakdownItems(widget.kind).isEmpty) {
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
          final items = store.breakdownItems(widget.kind);
          if (items.isEmpty) {
            return Center(child: Text(context.l10n.noStatusRecords));
          }
          return RefreshIndicator(
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
                          final item = items[index];
                          return InkWell(
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.supplierStatusDetail,
                              arguments: SupplierStatusDetailArgs(
                                kind: widget.kind,
                                itemCode: item.itemCode,
                                itemName: item.itemName,
                              ),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _metricLabel(item),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)
                                          .receiptCountLabel(item.receiptCount),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
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

class _SupplierAcceptedCategoryRow extends StatelessWidget {
  const _SupplierAcceptedCategoryRow({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 58),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
