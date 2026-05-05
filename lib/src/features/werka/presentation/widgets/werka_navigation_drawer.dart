import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/feedback/logout_prompt.dart';
import 'package:flutter/material.dart';

class WerkaNavigationDrawer extends StatelessWidget {
  const WerkaNavigationDrawer({
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
                0 => AppRoutes.werkaHome,
                1 => AppRoutes.werkaNotifications,
                2 => AppRoutes.werkaArchive,
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
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: Text('Bildirish'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.archive_outlined),
                selectedIcon: Icon(Icons.archive_rounded),
                label: Text('Data'),
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
