import '../../../../app/app_router.dart';
import '../../../../core/navigation/profile_route_overlay_notifier.dart';
import '../../../../core/native_dock_bridge.dart';
import '../../../../core/widgets/navigation/app_navigation_bar.dart';
import 'admin_create_hub_sheet.dart';
import 'package:flutter/material.dart';

enum AdminDockTab {
  home,
  suppliers,
  settings,
  activity,
}

class AdminDock extends StatelessWidget {
  const AdminDock({
    super.key,
    required this.activeTab,
    this.compact = true,
    this.tightToEdges = true,
    this.showPrimaryFab = true,
  });

  final AdminDockTab? activeTab;
  final bool compact;
  final bool tightToEdges;
  final bool showPrimaryFab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        NativeDockBridge.instance,
        ProfileRouteOverlayNotifier.instance,
      ]),
      builder: (context, _) {
        final effectiveShowPrimaryFab = showPrimaryFab &&
            !ProfileRouteOverlayNotifier.instance.obscuresDockPrimaryFab;
        final bool selectionVisible = activeTab != null;
        final int selectedIndex = switch (activeTab) {
          AdminDockTab.home => 0,
          AdminDockTab.suppliers => 1,
          AdminDockTab.settings => 2,
          AdminDockTab.activity => 3,
          null => 0,
        };

        return ValueListenableBuilder<bool>(
          valueListenable: adminCreateHubMenuOpen,
          builder: (context, menuOpen, _) {
            void handleSelection(int index) {
              if (index == 0) {
                if (activeTab == AdminDockTab.home) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.adminHome,
                  (route) => false,
                );
                return;
              }
              if (index == 1) {
                if (activeTab == AdminDockTab.suppliers) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.adminSuppliers,
                  (route) => false,
                );
                return;
              }
              if (index == 2) {
                showAdminCreateHubSheet(context);
                return;
              }
              if (index == 3) {
                if (activeTab == AdminDockTab.activity) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.adminActivity,
                  (route) => false,
                );
                return;
              }
            }

            final useNativeDock = NativeDockBridge.isSupportedPlatform &&
                NativeDockBridge.instance.supportsSystemDock;
            if (useNativeDock) {
              NativeDockBridge.instance.register(
                NativeDockState(
                  visible: true,
                  compact: compact,
                  tightToEdges: tightToEdges,
                  items: [
                    NativeDockItem(
                      id: 'admin-home',
                      label: 'Uy',
                      iconCodePoint: Icons.home_outlined.codePoint,
                      selectedIconCodePoint: Icons.home_rounded.codePoint,
                      active: activeTab == AdminDockTab.home,
                      primary: false,
                      showBadge: false,
                      routeName: AppRoutes.adminHome,
                      replaceStack: true,
                      onTap: () => handleSelection(0),
                    ),
                    NativeDockItem(
                      id: 'admin-suppliers',
                      label: 'Foydalanuvchilar',
                      iconCodePoint: Icons.groups_outlined.codePoint,
                      selectedIconCodePoint: Icons.groups_rounded.codePoint,
                      active: activeTab == AdminDockTab.suppliers,
                      primary: false,
                      showBadge: false,
                      routeName: AppRoutes.adminSuppliers,
                      replaceStack: true,
                      onTap: () => handleSelection(1),
                    ),
                    if (!menuOpen && effectiveShowPrimaryFab)
                      NativeDockItem(
                        id: 'admin-create',
                        label: 'Yangi',
                        iconCodePoint: Icons.add_rounded.codePoint,
                        selectedIconCodePoint: Icons.add_rounded.codePoint,
                        active: activeTab == AdminDockTab.settings,
                        primary: true,
                        showBadge: false,
                        onTap: () => handleSelection(2),
                      ),
                    NativeDockItem(
                      id: 'admin-activity',
                      label: 'Faoliyat',
                      iconCodePoint: Icons.history_outlined.codePoint,
                      selectedIconCodePoint: Icons.history_rounded.codePoint,
                      active: activeTab == AdminDockTab.activity,
                      primary: false,
                      showBadge: false,
                      routeName: AppRoutes.adminActivity,
                      replaceStack: true,
                      onTap: () => handleSelection(3),
                    ),
                  ],
                ),
              );
              return const SizedBox.shrink();
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: tightToEdges ? 0 : 8),
              child: AppNavigationBar(
                height: compact ? 60 : 64,
                selectionVisible: selectionVisible,
                selectedIndex: selectedIndex,
                primaryVisible: !menuOpen && effectiveShowPrimaryFab,
                destinations: const [
                  AppNavigationDestination(
                    label: 'Uy',
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                  ),
                  AppNavigationDestination(
                    label: 'Foydalanuvchilar',
                    icon: Icon(Icons.groups_outlined),
                    selectedIcon: Icon(Icons.groups_rounded),
                  ),
                  AppNavigationDestination(
                    label: 'Yangi',
                    icon: Icon(Icons.add_rounded),
                    selectedIcon: Icon(Icons.add_rounded),
                    isPrimary: true,
                  ),
                  AppNavigationDestination(
                    label: 'Faoliyat',
                    icon: Icon(Icons.history_outlined),
                    selectedIcon: Icon(Icons.history_rounded),
                  ),
                ],
                onDestinationSelected: handleSelection,
              ),
            );
          },
        );
      },
    );
  }
}
