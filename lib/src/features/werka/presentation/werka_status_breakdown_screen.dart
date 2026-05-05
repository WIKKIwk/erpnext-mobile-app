import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
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
  @override
  void initState() {
    super.initState();
    WerkaStore.instance.bootstrapBreakdown(widget.kind);
  }

  Future<void> _reload() async {
    await WerkaStore.instance.refreshBreakdown(widget.kind);
  }

  String get _title {
    final l10n = context.l10n;
    switch (widget.kind) {
      case WerkaStatusKind.pending:
        return l10n.pendingStatus;
      case WerkaStatusKind.confirmed:
        return l10n.confirmedStatus;
      case WerkaStatusKind.returned:
        return l10n.returnedStatus;
    }
  }

  String _metricLabel(WerkaStatusBreakdownEntry entry) {
    final l10n = context.l10n;
    switch (widget.kind) {
      case WerkaStatusKind.pending:
        return l10n.sentQtyStatus(
          entry.totalSentQty,
          entry.uom,
          l10n.pendingStatus.toLowerCase(),
        );
      case WerkaStatusKind.confirmed:
        return l10n.sentQtyStatus(
          entry.totalAcceptedQty,
          entry.uom,
          l10n.confirmedStatus.toLowerCase(),
        );
      case WerkaStatusKind.returned:
        return l10n.sentQtyStatus(
          entry.totalReturnedQty,
          entry.uom,
          l10n.returnedStatus.toLowerCase(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    useNativeNavigationTitle(context, _title);
    final bottomListPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: _title,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const WerkaDock(activeTab: null),
      contentPadding: EdgeInsets.zero,
      child: AnimatedBuilder(
        animation: WerkaStore.instance,
        builder: (context, _) {
          final store = WerkaStore.instance;
          if (store.loadingBreakdown(widget.kind) &&
              store.breakdownItems(widget.kind).isEmpty) {
            return const Center(child: AppLoadingIndicator());
          }
          final error = store.breakdownError(widget.kind);
          if (error != null && store.breakdownItems(widget.kind).isEmpty) {
            return AppRetryState(
              onRetry: _reload,
            );
          }

          final items = store.breakdownItems(widget.kind);
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: M3SegmentFilledSurface(
                    slot: M3SegmentVerticalSlot.top,
                    cornerRadius: M3SegmentedListGeometry.cornerLarge,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(
                        context.l10n.noStatusRecords,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final n = items.length;
          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 4, 0, bottomListPadding),
              children: [
                M3SegmentSpacedColumn(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    for (int index = 0; index < n; index++)
                      _WerkaBreakdownSegmentTile(
                        entry: items[index],
                        metricLabel: _metricLabel(items[index]),
                        index: index,
                        itemCount: n,
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.werkaStatusDetail,
                            arguments: WerkaStatusDetailArgs(
                              kind: widget.kind,
                              supplierRef: items[index].supplierRef,
                              supplierName: items[index].supplierName,
                            ),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          await _reload();
                        },
                      ),
                  ],
                ),
              ],
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

/// Home «Jarayondagi mahsulotlar» qatori bilan bir xil [M3SegmentFilledSurface] geometriya/fon.
class _WerkaBreakdownSegmentTile extends StatelessWidget {
  const _WerkaBreakdownSegmentTile({
    required this.entry,
    required this.metricLabel,
    required this.index,
    required this.itemCount,
    required this.onTap,
  });

  final WerkaStatusBreakdownEntry entry;
  final String metricLabel;
  final int index;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slot = M3SegmentedListGeometry.standaloneListSlotForIndex(
      index,
      itemCount,
    );
    final r = M3SegmentedListGeometry.cornerRadiusForSlot(slot);

    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: r,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.supplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalizations.of(context)
                          .recordCountLabel(entry.receiptCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      metricLabel,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
