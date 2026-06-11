import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import '../../../core/widgets/scroll/top_refresh_scroll_physics.dart';
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
  bool _openingRoute = false;

  @override
  void initState() {
    super.initState();
    if (_canLoadSummary) {
      AdminStore.instance.bootstrapSummary();
    }
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
    if (_canLoadSummary) {
      await AdminStore.instance.refreshSummary();
    }
  }

  bool get _canLoadSummary {
    return AppSession.instance.can('party.supplier.read');
  }

  void _openDrawerRoute(String routeName) {
    if (_openingRoute) {
      return;
    }
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) {
      return;
    }
    _openingRoute = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  Future<void> _openAndReload(String routeName) async {
    if (_openingRoute) {
      return;
    }
    _openingRoute = true;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushNamed(routeName);
      if (!mounted) {
        return;
      }
      await _reload();
    } finally {
      _openingRoute = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      drawer: AdminNavigationDrawer(
        selectedIndex: 0,
        onNavigate: _openDrawerRoute,
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
          final canLoadSummary = _canLoadSummary;
          if (canLoadSummary && store.loadingSummary && !store.loadedSummary) {
            return const Center(child: AppLoadingIndicator());
          }
          if (canLoadSummary &&
              store.summaryError != null &&
              !store.loadedSummary) {
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
                if (canLoadSummary) ...[
                  SmoothAppear(
                    delay: const Duration(milliseconds: 20),
                    child: _AdminSummaryList(
                      summary: summaryValue,
                      onTapTotal: () =>
                          _openAndReload(AppRoutes.adminSuppliers),
                      onTapActive: () =>
                          _openAndReload(AppRoutes.adminSuppliers),
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
                ] else
                  SmoothAppear(
                    delay: const Duration(milliseconds: 20),
                    child: _AdminActionList(
                      onOpenRoute: _openAndReload,
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

class _AdminActionList extends StatelessWidget {
  const _AdminActionList({
    required this.onOpenRoute,
  });

  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final actions = _adminHomeActions(context);
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (var i = 0; i < actions.length; i++)
          _AdminActionCard(
            slot: _slotFor(i, actions.length),
            action: actions[i],
            onTap: () => onOpenRoute(actions[i].routeName),
          ),
      ],
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.slot,
    required this.action,
    required this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final _AdminHomeAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: slot == M3SegmentVerticalSlot.middle
          ? M3SegmentedListGeometry.cornerMiddle
          : M3SegmentedListGeometry.cornerLarge,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(action.icon, size: 23, color: scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                action.title,
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
    );
  }
}

class _AdminHomeAction {
  const _AdminHomeAction({
    required this.title,
    required this.icon,
    required this.routeName,
  });

  final String title;
  final IconData icon;
  final String routeName;
}

List<_AdminHomeAction> _adminHomeActions(BuildContext context) {
  final l10n = context.l10n;
  final candidates = [
    _AdminHomeAction(
      title: l10n.adminCreateItemTitle,
      icon: Icons.inventory_2_outlined,
      routeName: AppRoutes.adminItemCreate,
    ),
    _AdminHomeAction(
      title: l10n.adminProductsTitle,
      icon: Icons.grid_view_rounded,
      routeName: AppRoutes.adminItemBulkMove,
    ),
    _AdminHomeAction(
      title: l10n.adminCreateItemGroupTitle,
      icon: Icons.account_tree_outlined,
      routeName: AppRoutes.adminItemGroupCreate,
    ),
    _AdminHomeAction(
      title: l10n.adminCreateUserTitle,
      icon: Icons.group_add_outlined,
      routeName: AppRoutes.adminUserCreate,
    ),
    _AdminHomeAction(
      title: l10n.adminUsersTitle,
      icon: Icons.groups_outlined,
      routeName: AppRoutes.adminSuppliers,
    ),
    _AdminHomeAction(
      title: l10n.adminRolesTitle,
      icon: Icons.admin_panel_settings_outlined,
      routeName: AppRoutes.adminRoles,
    ),
    const _AdminHomeAction(
      title: 'Zakazlar',
      icon: Icons.list_alt_rounded,
      routeName: AppRoutes.adminCalculateOrders,
    ),
    const _AdminHomeAction(
      title: 'Production map test',
      icon: Icons.schema_rounded,
      routeName: AppRoutes.adminProductionMapTest,
    ),
    const _AdminHomeAction(
      title: 'Aparat guruhlari',
      icon: Icons.precision_manufacturing_rounded,
      routeName: AppRoutes.adminApparatusGroups,
    ),
    const _AdminHomeAction(
      title: 'reja menu',
      icon: Icons.account_tree_outlined,
      routeName: AppRoutes.adminProductionMapOrders,
    ),
    const _AdminHomeAction(
      title: 'GScale',
      icon: Icons.scale_outlined,
      routeName: AppRoutes.gscaleMode,
    ),
    _AdminHomeAction(
      title: l10n.adminErpSettingsTitle,
      icon: Icons.settings_outlined,
      routeName: AppRoutes.adminSettings,
    ),
    _AdminHomeAction(
      title: l10n.adminActivityTitle,
      icon: Icons.history_outlined,
      routeName: AppRoutes.adminActivity,
    ),
  ];
  return candidates
      .where((action) => AppRouter.canOpenRoute(action.routeName))
      .toList(growable: false);
}

M3SegmentVerticalSlot _slotFor(int index, int length) {
  if (length <= 1) {
    return M3SegmentVerticalSlot.top;
  }
  if (index == 0) {
    return M3SegmentVerticalSlot.top;
  }
  if (index == length - 1) {
    return M3SegmentVerticalSlot.bottom;
  }
  return M3SegmentVerticalSlot.middle;
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.top,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Jami users',
          value: summary.totalSuppliers.toString(),
          onTap: onTapTotal,
          elevation: 2,
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.middle,
          cornerRadius: M3SegmentedListGeometry.cornerMiddle,
          title: 'Faol users',
          value: summary.activeSuppliers.toString(),
          onTap: onTapActive,
          elevation: 2,
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.bottom,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Bloklangan users',
          value: summary.blockedSuppliers.toString(),
          onTap: onTapBlocked,
          elevation: 2,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      'Bloklangan users: $count ta',
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
