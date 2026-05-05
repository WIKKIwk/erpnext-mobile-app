import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/feedback/logout_prompt.dart';
import 'package:flutter/material.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final int selectedIndex;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurfaceVariant = scheme.onSurfaceVariant;
    return SizedBox(
      width: 272,
      child: Stack(
        children: [
          NavigationDrawer(
            backgroundColor: scheme.surfaceContainerLow,
            indicatorColor: scheme.secondaryContainer,
            surfaceTintColor: Colors.transparent,
            selectedIndex: selectedIndex,
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            onDestinationSelected: (index) async {
              if (index == selectedIndex) {
                Navigator.of(context).pop();
                return;
              }
              final route = switch (index) {
                0 => AppRoutes.adminHome,
                1 => AppRoutes.adminSuppliers,
                2 => AppRoutes.adminActivity,
                _ => AppRoutes.profile,
              };
              Navigator.of(context).pop();
              await Future<void>.delayed(const Duration(milliseconds: 220));
              if (!context.mounted) {
                return;
              }
              onNavigate(route);
            },
            header: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bo‘limlar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            children: const [
              NavigationDrawerDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: Text('Uy'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: Text('Yetkazuvchilar'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: Text('Harakatlar'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: Text('Profil'),
              ),
              SizedBox(height: 80),
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
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
