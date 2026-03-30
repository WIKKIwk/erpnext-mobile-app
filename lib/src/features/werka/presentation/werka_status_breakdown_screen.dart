import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/app_shell.dart';
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
                padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                child: AnimatedBuilder(
                  animation: WerkaStore.instance,
                  builder: (context, _) {
                    final store = WerkaStore.instance;
                    if (store.loadingBreakdown(widget.kind) &&
                        store.breakdownItems(widget.kind).isEmpty) {
                      return const Center(child: AppLoadingIndicator());
                    }
                    final error = store.breakdownError(widget.kind);
                    if (error != null &&
                        store.breakdownItems(widget.kind).isEmpty) {
                      return AppRetryState(
                        onRetry: _reload,
                      );
                    }

                    final items = store.breakdownItems(widget.kind);
                    if (items.isEmpty) {
                      return Center(
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerLow,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              context.l10n.noStatusRecords,
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
                                  _WerkaBreakdownRow(
                                    entry: items[index],
                                    metricLabel: _metricLabel(items[index]),
                                    isLast: index == items.length - 1,
                                    onTap: () async {
                                      await Navigator.of(context).pushNamed(
                                        AppRoutes.werkaStatusDetail,
                                        arguments: WerkaStatusDetailArgs(
                                          kind: widget.kind,
                                          supplierRef: items[index].supplierRef,
                                          supplierName:
                                              items[index].supplierName,
                                        ),
                                      );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      await _reload();
                                    },
                                  ),
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

class _WerkaBreakdownRow extends StatelessWidget {
  const _WerkaBreakdownRow({
    required this.entry,
    required this.metricLabel,
    required this.isLast,
    required this.onTap,
  });

  final WerkaStatusBreakdownEntry entry;
  final String metricLabel;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(28);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: AppTheme.cardBorder(context),
                        width: 1,
                      ),
                    ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.supplierName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        metricLabel,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)
                            .recordCountLabel(entry.receiptCount),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
