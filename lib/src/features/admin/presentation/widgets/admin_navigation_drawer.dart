import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/feedback/logout_prompt.dart';
import 'package:flutter/material.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    this.selectedRouteName,
  });

  final int selectedIndex;
  final ValueChanged<String> onNavigate;
  final String? selectedRouteName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    final l10n = context.l10n;
    final destinations = _visibleAdminDrawerDestinations(context);
    final selectedRoute =
        selectedRouteName ?? _routeForLegacyIndex(selectedIndex);
    final effectiveSelectedIndex = destinations.indexWhere(
      (destination) => destination.routeName == selectedRoute,
    );
    return SizedBox(
      width: 272,
      child: Stack(
        children: [
          NavigationDrawer(
            backgroundColor: scheme.surfaceContainerLow,
            indicatorColor: scheme.secondaryContainer,
            surfaceTintColor: Colors.transparent,
            selectedIndex:
                effectiveSelectedIndex >= 0 ? effectiveSelectedIndex : null,
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            onDestinationSelected: (index) async {
              if (index < 0 || index >= destinations.length) {
                Navigator.of(context).pop();
                return;
              }
              final destination = destinations[index];
              if (index == effectiveSelectedIndex) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop();
              await Future<void>.delayed(const Duration(milliseconds: 220));
              if (!context.mounted) {
                return;
              }
              if (destination.push) {
                Navigator.of(context).pushNamed(destination.routeName);
                return;
              }
              onNavigate(destination.routeName);
            },
            header: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.adminDrawerSections,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            children: [
              for (final destination in destinations)
                NavigationDrawerDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 168),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                Navigator.of(context).pop();
                await Future<void>.delayed(const Duration(milliseconds: 120));
                if (!context.mounted) {
                  return;
                }
                await showLogoutPrompt(context);
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(context.l10n.logoutTitle),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _routeForLegacyIndex(int index) {
  return switch (index) {
    0 => AppRoutes.adminHome,
    1 => AppRoutes.adminSuppliers,
    2 => AppRoutes.adminActivity,
    3 => AppRoutes.adminRoles,
    4 => AppRoutes.profile,
    _ => AppRoutes.gscaleMode,
  };
}

class _AdminDrawerDestination {
  const _AdminDrawerDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.routeName,
    this.push = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String routeName;
  final bool push;
}

List<_AdminDrawerDestination> _visibleAdminDrawerDestinations(
  BuildContext context,
) {
  final l10n = context.l10n;
  final candidates = [
    _AdminDrawerDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: l10n.adminHomeNavTitle,
      routeName: AppRoutes.adminHome,
    ),
    _AdminDrawerDestination(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      label: l10n.adminUsersTitle,
      routeName: AppRoutes.adminSuppliers,
    ),
    _AdminDrawerDestination(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      label: l10n.adminActivityTitle,
      routeName: AppRoutes.adminActivity,
    ),
    const _AdminDrawerDestination(
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt_rounded,
      label: 'Tezkor zakazlar',
      routeName: AppRoutes.adminCalculateOrders,
    ),
    _AdminDrawerDestination(
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings_rounded,
      label: l10n.adminRolesTitle,
      routeName: AppRoutes.adminRoles,
    ),
    const _AdminDrawerDestination(
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree_rounded,
      label: 'reja menu',
      routeName: AppRoutes.adminProductionMapOrders,
    ),
    const _AdminDrawerDestination(
      icon: Icons.precision_manufacturing_outlined,
      selectedIcon: Icons.precision_manufacturing_rounded,
      label: 'Aparat guruhlari',
      routeName: AppRoutes.adminApparatusGroups,
    ),
    _AdminDrawerDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: l10n.profileTitle,
      routeName: AppRoutes.profile,
      push: true,
    ),
    const _AdminDrawerDestination(
      icon: Icons.swap_horiz_rounded,
      selectedIcon: Icons.swap_horiz_rounded,
      label: 'GScale Mode',
      routeName: AppRoutes.gscaleMode,
      push: true,
    ),
    const _AdminDrawerDestination(
      icon: Icons.content_cut_rounded,
      selectedIcon: Icons.content_cut_rounded,
      label: 'Rezka',
      routeName: AppRoutes.rezkaSplit,
      push: true,
    ),
  ];
  return candidates
      .where((destination) => AppRouter.canOpenRoute(destination.routeName))
      .toList(growable: false);
}
