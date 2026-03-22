import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'supplier_qty_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({super.key});

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupplierStore.instance.bootstrapHistory();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'supplier') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    _settleTopEdge();
    await SupplierStore.instance.refreshHistory();
    _settleTopEdge();
  }

  void _settleTopEdge() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.minScrollExtent;
      if ((position.pixels - target).abs() <= 0.5) {
        return;
      }
      _scrollController.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: context.l10n.supplierRoleName,
      subtitle: '',
      actions: [
        AnimatedBuilder(
          animation: NotificationUnreadStore.instance,
          builder: (context, _) {
            final showBadge =
                NotificationUnreadStore.instance.hasUnreadForProfile(
              AppSession.instance.profile,
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.supplierNotifications,
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (showBadge)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      height: 9,
                      width: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
      bottom: const SupplierDock(activeTab: SupplierDockTab.home),
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      child: AnimatedBuilder(
        animation: SupplierStore.instance,
        builder: (context, _) {
          final store = SupplierStore.instance;
          if (store.loadingHistory && !store.loadedHistory) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.historyError != null && !store.loadedHistory) {
            final scheme = Theme.of(context).colorScheme;
            return AppRefreshIndicator(
              onRefresh: _reload,
              allowRefreshOnShortContent: true,
              child: ListView(
                controller: _scrollController,
                physics: const TopRefreshScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 120),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.supplierHomeLoadFailed,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            '${store.historyError}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _reload,
                              child: Text(context.l10n.retry),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final current = store.summary;
          final previewItems = store.historyItems
              .where(
                (item) =>
                    item.status == DispatchStatus.pending ||
                    item.status == DispatchStatus.draft,
              )
              .take(3)
              .toList();

          return AppRefreshIndicator(
            onRefresh: _reload,
            allowRefreshOnShortContent: true,
            child: ListView(
              controller: _scrollController,
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SupplierSummaryCard(summary: current),
                ),
                if (previewItems.isNotEmpty) const SizedBox(height: 16),
                if (previewItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _SupplierPendingSection(items: previewItems),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupplierSummaryCard extends StatelessWidget {
  const _SupplierSummaryCard({
    required this.summary,
  });

  final SupplierHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SmoothAppear(
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppTheme.cardBorder(context).withValues(alpha: 0.75),
          ),
        ),
        child: Column(
          children: [
            _SupplierSummaryRow(
              label: context.l10n.pendingStatus,
              value: summary.pendingCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.pending,
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _SupplierSummaryRow(
              label: context.l10n.submittedStatus,
              value: summary.submittedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.submitted,
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _SupplierSummaryRow(
              label: context.l10n.returnedStatus,
              value: summary.returnedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.returned,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierSummaryRow extends StatelessWidget {
  const _SupplierSummaryRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressableScale(
      borderRadius: 28,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
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
                value,
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

class _SupplierPendingSection extends StatelessWidget {
  const _SupplierPendingSection({
    required this.items,
  });

  final List<DispatchRecord> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SmoothAppear(
      delay: const Duration(milliseconds: 90),
      offset: const Offset(0, 18),
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppTheme.cardBorder(context).withValues(alpha: 0.75),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Text(
                context.l10n.inProgressItemsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1, thickness: 1),
            for (int index = 0; index < items.length; index++)
              _SupplierPendingRow(
                record: items[index],
                hasBottomBorder: index != items.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _SupplierPendingRow extends StatelessWidget {
  const _SupplierPendingRow({
    required this.record,
    required this.hasBottomBorder,
  });

  final DispatchRecord record;
  final bool hasBottomBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = SupplierItem(
      code: record.itemCode,
      name: record.itemName,
      uom: record.uom,
      warehouse: '',
    );
    return PressableScale(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.supplierQty,
        arguments: SupplierQtyArgs(
          item: item,
          initialQty: record.sentQty,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            border: hasBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: AppTheme.cardBorder(context),
                      width: 1,
                    ),
                  )
                : null,
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
                      record.itemName,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.itemCode,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.createdLabel,
                    style: theme.textTheme.bodySmall,
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
