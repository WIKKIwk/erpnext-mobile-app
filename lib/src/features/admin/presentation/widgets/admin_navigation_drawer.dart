import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> adminNavigationDrawerOpen =
    ValueNotifier<bool>(false);

OverlayEntry? _adminNavigationDrawerOverlayEntry;

void showAdminNavigationDrawer(BuildContext context) {
  if (_adminNavigationDrawerOverlayEntry != null) {
    return;
  }

  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;

  void closeNow() {
    adminNavigationDrawerOpen.value = false;
    if (entry.mounted) {
      entry.remove();
    }
    if (_adminNavigationDrawerOverlayEntry == entry) {
      _adminNavigationDrawerOverlayEntry = null;
    }
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      return _AdminNavigationDrawerOverlay(
        onClose: closeNow,
      );
    },
  );

  _adminNavigationDrawerOverlayEntry = entry;
  adminNavigationDrawerOpen.value = true;
  overlay.insert(entry);
}

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
    this.onCloseDrawer,
  });

  final int selectedIndex;
  final ValueChanged<String> onNavigate;
  final VoidCallback? onCloseDrawer;

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
              final closeDrawer =
                  onCloseDrawer ?? () => Navigator.of(context).pop();
              if (index == selectedIndex) {
                closeDrawer();
                return;
              }
              final route = switch (index) {
                0 => AppRoutes.adminHome,
                1 => AppRoutes.adminSuppliers,
                2 => AppRoutes.adminActivity,
                _ => AppRoutes.profile,
              };
              closeDrawer();
              await Future<void>.delayed(const Duration(milliseconds: 220));
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

class _AdminNavigationDrawerOverlay extends StatelessWidget {
  const _AdminNavigationDrawerOverlay({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.54),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: adminNavigationDrawerOpen,
            builder: (context, _) {
              return AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: adminNavigationDrawerOpen.value
                    ? Offset.zero
                    : const Offset(-1, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 272,
                    height: double.infinity,
                    child: AdminNavigationDrawer(
                      selectedIndex: 0,
                      onCloseDrawer: onClose,
                      onNavigate: (route) {
                        final navigator =
                            Navigator.of(context, rootNavigator: true);
                        onClose();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          navigator.pushReplacementNamed(route);
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
