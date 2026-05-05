import '../../../../app/app_router.dart';
import '../../../../core/navigation/profile_route_overlay_notifier.dart';
import '../../../../core/native_dock_bridge.dart';
import '../../../../core/notifications/store/notification_unread_store.dart';
import '../../../../core/session/session.dart';
import '../../../../core/widgets/navigation/app_navigation_bar.dart';
import 'werka_create_hub_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum WerkaDockTab {
  home,
  notifications,
  create,
  archive,
}

class WerkaDock extends StatelessWidget {
  const WerkaDock({
    super.key,
    required this.activeTab,
    this.compact = true,
    this.tightToEdges = true,
    this.showPrimaryFab = true,
  });

  final WerkaDockTab? activeTab;
  final bool compact;
  final bool tightToEdges;
  final bool showPrimaryFab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        NotificationUnreadStore.instance,
        NativeDockBridge.instance,
        ProfileRouteOverlayNotifier.instance,
      ]),
      builder: (context, _) {
        final effectiveShowPrimaryFab = showPrimaryFab &&
            !ProfileRouteOverlayNotifier.instance.obscuresDockPrimaryFab;
        final showBadge = NotificationUnreadStore.instance.hasUnreadForProfile(
              AppSession.instance.profile,
            ) &&
            activeTab != WerkaDockTab.notifications;
        final bool selectionVisible = activeTab != null;
        final int selectedIndex = switch (activeTab) {
          WerkaDockTab.home => 0,
          WerkaDockTab.notifications => 1,
          WerkaDockTab.create => 2,
          WerkaDockTab.archive => 3,
          null => 0,
        };
        return ValueListenableBuilder<bool>(
          valueListenable: werkaCreateHubMenuOpen,
          builder: (context, menuOpen, child) {
            void handleSelection(int index) {
              if (index == 0) {
                if (activeTab == WerkaDockTab.home) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.werkaHome,
                  (route) => false,
                );
                return;
              }
              if (index == 1) {
                if (activeTab == WerkaDockTab.notifications) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.werkaNotifications,
                  (route) => false,
                );
                return;
              }
              if (index == 2) {
                showWerkaCreateHubSheet(context);
                return;
              }
              if (index == 3) {
                if (activeTab == WerkaDockTab.archive) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.werkaArchive,
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
                      id: 'werka-home',
                      label: 'Uy',
                      iconCodePoint: Icons.home_outlined.codePoint,
                      selectedIconCodePoint: Icons.home_rounded.codePoint,
                      active: activeTab == WerkaDockTab.home,
                      primary: false,
                      showBadge: false,
                      routeName: AppRoutes.werkaHome,
                      replaceStack: true,
                      onTap: () => handleSelection(0),
                    ),
                    NativeDockItem(
                      id: 'werka-notifications',
                      label: 'Bildirish',
                      iconCodePoint: Icons.notifications_outlined.codePoint,
                      selectedIconCodePoint:
                          Icons.notifications_rounded.codePoint,
                      active: activeTab == WerkaDockTab.notifications,
                      primary: false,
                      showBadge: showBadge,
                      routeName: AppRoutes.werkaNotifications,
                      replaceStack: true,
                      onTap: () => handleSelection(1),
                    ),
                    if (!menuOpen && effectiveShowPrimaryFab)
                      NativeDockItem(
                        id: 'werka-create',
                        label: 'Yangi',
                        iconCodePoint: Icons.add_rounded.codePoint,
                        selectedIconCodePoint: Icons.add_rounded.codePoint,
                        active: activeTab == WerkaDockTab.create,
                        primary: true,
                        showBadge: false,
                        onTap: () => handleSelection(2),
                      ),
                    NativeDockItem(
                      id: 'werka-archive',
                      label: 'Arxiv',
                      iconCodePoint: Icons.playlist_add_check_rounded.codePoint,
                      selectedIconCodePoint:
                          Icons.playlist_add_check_rounded.codePoint,
                      active: activeTab == WerkaDockTab.archive,
                      primary: false,
                      showBadge: false,
                      routeName: AppRoutes.werkaArchive,
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
                destinations: [
                  const AppNavigationDestination(
                    label: 'Uy',
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                  ),
                  AppNavigationDestination(
                    label: 'Bildirish',
                    icon: const Icon(Icons.notifications_outlined),
                    selectedIcon: const Icon(Icons.notifications_rounded),
                    showBadge: showBadge,
                  ),
                  const AppNavigationDestination(
                    label: 'Yangi',
                    icon: Icon(Icons.add_rounded),
                    selectedIcon: Icon(Icons.add_rounded),
                    isPrimary: true,
                  ),
                  const AppNavigationDestination(
                    label: 'Arxiv',
                    icon: _WerkaDockSvgIcon(),
                    selectedIcon: _WerkaDockSvgIcon(),
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

class _WerkaDockSvgIcon extends StatelessWidget {
  const _WerkaDockSvgIcon();

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final color = iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    final size = (iconTheme.size ?? 24) + 5;
    return SvgPicture.asset(
      'assets/icons/data-check.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color,
        BlendMode.srcIn,
      ),
    );
  }
}
