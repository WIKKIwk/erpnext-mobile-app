import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../state/admin_store.dart';
import 'widgets/admin_dock.dart';
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
      title: context.l10n.adminRoleName,
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      child: AnimatedBuilder(
        animation: AdminStore.instance,
        builder: (context, _) {
          final store = AdminStore.instance;
          if (store.loadingSummary && !store.loadedSummary) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.summaryError != null && !store.loadedSummary) {
            return AppRetryState(onRetry: _reload);
          }

          final summaryValue = store.summary;
          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: EdgeInsets.only(bottom: bottomPadding),
              children: [
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: _AdminModulesSection(
                    onTapSettings: () =>
                        _openAndReload(AppRoutes.adminSettings),
                    onTapSuppliers: () =>
                        _openAndReload(AppRoutes.adminSuppliers),
                    onTapWerka: () => _openAndReload(AppRoutes.adminWerka),
                  ),
                ),
                if (summaryValue.blockedSuppliers > 0) ...[
                  const SizedBox(height: 12),
                  SmoothAppear(
                    delay: const Duration(milliseconds: 60),
                    child: _AdminBlockedSuppliersCard(
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

class _AdminModulesSection extends StatelessWidget {
  const _AdminModulesSection({
    required this.onTapSettings,
    required this.onTapSuppliers,
    required this.onTapWerka,
  });

  final VoidCallback onTapSettings;
  final VoidCallback onTapSuppliers;
  final VoidCallback onTapWerka;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _AdminModuleRow(
            title: context.l10n.adminErpSettingsTitle,
            subtitle: context.l10n.erpConnectionSubtitle,
            onTap: onTapSettings,
          ),
          const _AdminSectionDivider(),
          _AdminModuleRow(
            title: 'Suppliers',
            subtitle: 'List, mahsulot biriktirish va block nazorati',
            onTap: onTapSuppliers,
          ),
          const _AdminSectionDivider(),
          _AdminModuleRow(
            title: context.l10n.adminCreateWerkaTitle,
            subtitle: context.l10n.adminCreateWerkaSubtitle,
            onTap: onTapWerka,
          ),
        ],
      ),
    );
  }
}

class _AdminModuleRow extends StatelessWidget {
  const _AdminModuleRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSectionDivider extends StatelessWidget {
  const _AdminSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 18,
      endIndent: 18,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
    );
  }
}

class _AdminBlockedSuppliersCard extends StatelessWidget {
  const _AdminBlockedSuppliersCard({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.block_rounded,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bloklangan supplierlar: $count ta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: scheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
