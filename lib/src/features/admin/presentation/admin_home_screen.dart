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
    await AdminStore.instance.refreshSummary();
  }

  void _openDrawerRoute(String routeName) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
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
