import '../../../../app/app_router.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/app_navigation_bar.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'werka_create_hub_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum WerkaDockTab {
  home,
  notifications,
  create,
  archive,
  profile,
}

class WerkaDock extends StatelessWidget {
  const WerkaDock({
    super.key,
    required this.activeTab,
    this.compact = true,
    this.tightToEdges = true,
  });

  final WerkaDockTab? activeTab;
  final bool compact;
  final bool tightToEdges;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NotificationUnreadStore.instance,
      builder: (context, _) {
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
          WerkaDockTab.profile => 4,
          null => 0,
        };
        return ValueListenableBuilder<bool>(
          valueListenable: werkaCreateHubMenuOpen,
          builder: (context, menuOpen, child) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: tightToEdges ? 0 : 8),
              child: AppNavigationBar(
                height: compact ? 68 : 72,
                selectionVisible: selectionVisible,
                selectedIndex: selectedIndex,
                primaryVisible: !menuOpen,
                destinations: [
                  AppNavigationDestination(
                    label: 'Uy',
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                  ),
                  AppNavigationDestination(
                    label: 'Bildirish',
                    icon: const Icon(Icons.notifications_outlined),
                    selectedIcon: const Icon(Icons.notifications_rounded),
                    showBadge: showBadge,
                  ),
                  AppNavigationDestination(
                    label: 'Yangi',
                    icon: const Icon(Icons.add_rounded),
                    selectedIcon: const Icon(Icons.add_rounded),
                    isPrimary: true,
                  ),
                  AppNavigationDestination(
                    label: 'Arxiv',
                    icon: const _WerkaDockSvgIcon(),
                    selectedIcon: const _WerkaDockSvgIcon(),
                  ),
                  AppNavigationDestination(
                    label: 'Profil',
                    icon: const Icon(Icons.account_circle_outlined),
                    selectedIcon: const Icon(Icons.account_circle_rounded),
                    onLongPress: activeTab == WerkaDockTab.profile
                        ? () => showLogoutPrompt(context)
                        : null,
                  ),
                ],
                onDestinationSelected: (index) {
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
                  if (activeTab == WerkaDockTab.profile) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.profile,
                    (route) => false,
                  );
                },
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
