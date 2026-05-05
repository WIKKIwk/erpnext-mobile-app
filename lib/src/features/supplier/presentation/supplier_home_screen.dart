import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/store/notification_unread_store.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/session/session.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import '../../../core/widgets/scroll/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({super.key});

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen>
    with WidgetsBindingObserver {
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupplierStore.instance.bootstrapSummary();
    SupplierStore.instance.bootstrapHistory();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RefreshHub.instance.removeListener(_handlePushRefresh);
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
    await SupplierStore.instance.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: context.l10n.supplierRoleName,
      subtitle: '',
      preferNativeTitle: true,
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
            return const Center(child: AppLoadingIndicator());
          }
          if (store.historyError != null && !store.loadedHistory) {
            return AppRefreshIndicator(
              onRefresh: _reload,
              allowRefreshOnShortContent: true,
              child: ListView(
                physics: const TopRefreshScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  AppRetryState(onRetry: _reload),
                ],
              ),
            );
          }
          final current = store.summary;
          final pendingItems = store.historyItems
              .where(
                (item) =>
                    item.status == DispatchStatus.pending ||
                    item.status == DispatchStatus.draft,
              )
              .toList();

          return AppRefreshIndicator(
            onRefresh: _reload,
            allowRefreshOnShortContent: true,
            child: ListView(
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SupplierSummaryCard(summary: current),
                ),
                if (pendingItems.isNotEmpty) const SizedBox(height: 16),
                if (pendingItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _SupplierPendingSection(items: pendingItems),
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
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            _SupplierSummaryRow(
              label: context.l10n.pendingStatus,
              value: summary.pendingCount.toString(),
              highlighted: true,
              isFirst: true,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.pending,
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 18,
              endIndent: 18,
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            _SupplierSummaryRow(
              label: context.l10n.submittedStatus,
              value: summary.submittedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.submitted,
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 18,
              endIndent: 18,
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            _SupplierSummaryRow(
              label: context.l10n.returnedStatus,
              value: summary.returnedCount.toString(),
              isLast: true,
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
    this.highlighted = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlighted;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 28 : 0),
      topRight: Radius.circular(isFirst ? 28 : 0),
      bottomLeft: Radius.circular(isLast ? 28 : 0),
      bottomRight: Radius.circular(isLast ? 28 : 0),
    );
    return PressableScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.smooth,
            color: highlighted ? scheme.surfaceContainer : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (highlighted) ...[
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(label, style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.smooth,
                      switchOutCurve: AppMotion.smooth,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        value,
                        key: ValueKey<String>(value),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return SmoothAppear(
      delay: const Duration(milliseconds: 90),
      offset: const Offset(0, 18),
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.l10n.inProgressItemsTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 14),
              Card.filled(
                margin: EdgeInsets.zero,
                color:
                    isDark ? const Color(0xFF2A2931) : scheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    for (int index = 0; index < items.length; index++) ...[
                      _SupplierPendingRow(
                        record: items[index],
                        isFirst: index == 0,
                        isLast: index == items.length - 1,
                      ),
                      if (index != items.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                    ],
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

class _SupplierPendingRow extends StatelessWidget {
  const _SupplierPendingRow({
    required this.record,
    required this.isFirst,
    required this.isLast,
  });

  final DispatchRecord record;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressableScale(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.notificationDetail,
        arguments: record.id,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isFirst ? 24 : 0),
              topRight: Radius.circular(isFirst ? 24 : 0),
              bottomLeft: Radius.circular(isLast ? 24 : 0),
              bottomRight: Radius.circular(isLast ? 24 : 0),
            ),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.notificationDetail,
              arguments: record.id,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          record.itemCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
