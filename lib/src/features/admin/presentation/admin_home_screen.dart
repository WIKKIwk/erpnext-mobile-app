import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/m3_segmented_list.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/admin_store.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_navigation_drawer.dart';
import 'widgets/admin_summary_card.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    AdminStore.instance.bootstrapSummary();
    AdminStore.instance.bootstrapHomeActions();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'admin') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  Future<void> _reload() async {
    await Future.wait([
      AdminStore.instance.refreshSummary(),
      AdminStore.instance.refreshHomeActions(),
    ]);
  }

  Future<void> _openAndReload(String routeName) async {
    await Navigator.of(context).pushNamed(routeName);
    if (!mounted) {
      return;
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.menu_rounded,
        onTap: () => showAdminNavigationDrawer(context),
      ),
      title: context.l10n.adminRoleName,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      bottomDockFadeStrength: null,
      contentPadding: EdgeInsets.zero,
      child: AnimatedBuilder(
        animation: AdminStore.instance,
        builder: (context, _) {
          final store = AdminStore.instance;
          if (store.loadingSummary && !store.loadedSummary) {
            return const Center(child: AppLoadingIndicator());
          }
          if (store.summaryError != null && !store.loadedSummary) {
            return AppRetryState(onRetry: _reload);
          }

          final summaryValue = store.summary;
          return AppRefreshIndicator(
            onRefresh: _reload,
            allowRefreshOnShortContent: true,
            child: ListView(
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding),
              children: [
                const SizedBox(height: 4),
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: _AdminSummaryList(
                    summary: summaryValue,
                    onTapTotal: () => _openAndReload(AppRoutes.adminSuppliers),
                    onTapActive: () => _openAndReload(AppRoutes.adminSuppliers),
                    onTapBlocked: () =>
                        _openAndReload(AppRoutes.adminInactiveSuppliers),
                  ),
                ),
                if (summaryValue.blockedSuppliers > 0) ...[
                  const SizedBox(height: 16),
                  SmoothAppear(
                    delay: const Duration(milliseconds: 80),
                    child: _AdminBlockedSuppliersSection(
                      count: summaryValue.blockedSuppliers,
                      onTap: () =>
                          _openAndReload(AppRoutes.adminInactiveSuppliers),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SmoothAppear(
                  delay: const Duration(milliseconds: 120),
                  child: _AdminQuickActionsSection(
                    actions: store.homeActions,
                    onTapAction: (routeName) => _openAndReload(routeName),
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

class _AdminSummaryList extends StatelessWidget {
  const _AdminSummaryList({
    required this.summary,
    required this.onTapTotal,
    required this.onTapActive,
    required this.onTapBlocked,
  });

  final AdminSupplierSummary summary;
  final VoidCallback onTapTotal;
  final VoidCallback onTapActive;
  final VoidCallback onTapBlocked;

  @override
  Widget build(BuildContext context) {
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.top,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Jami supplierlar',
          value: summary.totalSuppliers.toString(),
          onTap: onTapTotal,
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.middle,
          cornerRadius: M3SegmentedListGeometry.cornerMiddle,
          title: 'Faol supplierlar',
          value: summary.activeSuppliers.toString(),
          onTap: onTapActive,
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.bottom,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Bloklangan supplierlar',
          value: summary.blockedSuppliers.toString(),
          onTap: onTapBlocked,
        ),
      ],
    );
  }
}

class _AdminBlockedSuppliersSection extends StatelessWidget {
  const _AdminBlockedSuppliersSection({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          M3SegmentFilledSurface(
            slot: M3SegmentVerticalSlot.top,
            cornerRadius: M3SegmentedListGeometry.cornerLarge,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Blok nazorati',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Icon(
                    Icons.block_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: M3SegmentedListGeometry.gap),
          M3SegmentFilledSurface(
            slot: M3SegmentVerticalSlot.bottom,
            cornerRadius: M3SegmentedListGeometry.cornerLarge,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bloklangan supplierlar: $count ta',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminQuickActionsSection extends StatelessWidget {
  const _AdminQuickActionsSection({
    required this.actions,
    required this.onTapAction,
  });

  final List<AdminHomeAction> actions;
  final ValueChanged<String> onTapAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visibleActions = actions.isEmpty
        ? const <AdminHomeAction>[
            AdminHomeAction(
              id: 'erp_settings',
              title: 'ERP settings',
              subtitle: 'Core integration and stock defaults',
              routeName: AppRoutes.adminSettings,
              highlighted: true,
            ),
            AdminHomeAction(
              id: 'suppliers',
              title: 'Suppliers',
              subtitle: 'List, mahsulot biriktirish va block nazorati',
              routeName: AppRoutes.adminSuppliers,
              highlighted: false,
            ),
            AdminHomeAction(
              id: 'werka',
              title: 'Add Werka',
              subtitle: 'Configure warehouse worker phone and name',
              routeName: AppRoutes.adminWerka,
              highlighted: false,
            ),
          ]
        : actions;

    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
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
                'Tez kirish',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: M3SegmentSpacedColumn(
                children: [
                  for (int index = 0; index < visibleActions.length; index++)
                    AdminSummaryCard(
                      slot: _slotForIndex(index, visibleActions.length),
                      cornerRadius: M3SegmentedListGeometry.cornerLarge,
                      title: visibleActions[index].title,
                      subtitle: visibleActions[index].subtitle,
                      value: '',
                      leading: _QuickActionLeadingIcon(
                        routeName: visibleActions[index].routeName,
                        highlighted: visibleActions[index].highlighted,
                      ),
                      onTap: () => onTapAction(visibleActions[index].routeName),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  M3SegmentVerticalSlot _slotForIndex(int index, int count) {
    if (count <= 1) {
      return M3SegmentVerticalSlot.top;
    }
    if (index == 0) {
      return M3SegmentVerticalSlot.top;
    }
    if (index == count - 1) {
      return M3SegmentVerticalSlot.bottom;
    }
    return M3SegmentVerticalSlot.middle;
  }
}

class _QuickActionLeadingIcon extends StatelessWidget {
  const _QuickActionLeadingIcon({
    required this.routeName,
    required this.highlighted,
  });

  final String routeName;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg =
        highlighted ? scheme.primaryContainer : scheme.secondaryContainer;
    final Color fg =
        highlighted ? scheme.onPrimaryContainer : scheme.onSecondaryContainer;
    final IconData icon = switch (routeName) {
      AppRoutes.adminSettings => Icons.settings_rounded,
      AppRoutes.adminSuppliers => Icons.groups_rounded,
      AppRoutes.adminWerka => Icons.storefront_rounded,
      _ => Icons.arrow_forward_rounded,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: 22),
    );
  }
}
