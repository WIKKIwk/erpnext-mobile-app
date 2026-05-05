import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../../core/widgets/scroll/top_refresh_scroll_physics.dart';
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
          if (store.loadingDetail(widget.args.kind, widget.args.supplierRef) &&
              store
                  .detailItems(widget.args.kind, widget.args.supplierRef)
                  .isEmpty) {
            return const Center(child: AppLoadingIndicator());
          }
          final error =
              store.detailError(widget.args.kind, widget.args.supplierRef);
          if (error != null &&
              store
                  .detailItems(widget.args.kind, widget.args.supplierRef)
                  .isEmpty) {
            return AppRetryState(
              onRetry: _reload,
            );
          }

          final items =
              store.detailItems(widget.args.kind, widget.args.supplierRef);
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
                        context.l10n.noRecordsYet,
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
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 4, 0, bottomListPadding),
              children: [
                M3SegmentSpacedColumn(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    for (int index = 0; index < n; index++)
                      _WerkaStatusDetailSegmentTile(
                        record: items[index],
                        index: index,
                        itemCount: n,
                        onTap: () => _openRecord(items[index]),
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

/// Home «Jarayondagi mahsulotlar» qatori / breakdown SDK bilan bir xil segment.
class _WerkaStatusDetailSegmentTile extends StatelessWidget {
  const _WerkaStatusDetailSegmentTile({
    required this.record,
    required this.index,
    required this.itemCount,
    required this.onTap,
  });

  final DispatchRecord record;
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
    final title =
        record.itemName.trim().isEmpty ? record.itemCode : record.itemName;

    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: r,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (record.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      record.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ] else if (record.acceptedQty > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.acceptedQtyLabel(
                        record.acceptedQty,
                        record.uom,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
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
    );
  }
}
