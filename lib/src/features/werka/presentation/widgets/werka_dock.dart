import '../../../../app/app_router.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

enum WerkaDockTab {
  home,
  notifications,
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
        return SharedDockHero(
          tag: 'werka',
          child: ActionDock(
            compact: compact,
            tightToEdges: tightToEdges,
            leading: [
              DockButton(
                nativeId: 'werka_home',
                nativeSymbol: 'house',
                nativeSelectedSymbol: 'house.fill',
                nativeRouteName: AppRoutes.werkaHome,
                nativeReplaceStack: true,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                active: activeTab == WerkaDockTab.home,
                compact: compact,
                onTap: () {
                  if (activeTab == WerkaDockTab.home) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.werkaHome,
                    (route) => false,
                  );
                },
              ),
              DockButton(
                nativeId: 'werka_notifications',
                nativeSymbol: 'bell',
                nativeSelectedSymbol: 'bell.fill',
                nativeRouteName: AppRoutes.werkaNotifications,
                nativeReplaceStack: true,
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications_rounded,
                active: activeTab == WerkaDockTab.notifications,
                compact: compact,
                showBadge: showBadge,
                onTap: () {
                  if (activeTab == WerkaDockTab.notifications) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.werkaNotifications,
                    (route) => false,
                  );
                },
              ),
            ],
            center: DockButton(
              nativeId: 'werka_create',
              nativeSymbol: 'plus',
              nativeSelectedSymbol: 'plus',
              nativeRouteName: AppRoutes.werkaCreateHub,
              icon: Icons.add_rounded,
              selectedIcon: Icons.add_rounded,
              primary: true,
              compact: compact,
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.werkaCreateHub);
              },
            ),
            trailing: [
              DockButton(
                nativeId: 'werka_archive',
                nativeSymbol: 'archivebox',
                nativeSelectedSymbol: 'archivebox.fill',
                nativeRouteName: AppRoutes.werkaArchive,
                nativeReplaceStack: true,
                icon: Icons.archive_outlined,
                selectedIcon: Icons.archive_rounded,
                active: activeTab == WerkaDockTab.archive,
                compact: compact,
                onTap: () {
                  if (activeTab == WerkaDockTab.archive) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.werkaArchive,
                    (route) => false,
                  );
                },
              ),
              DockButton(
                nativeId: 'werka_profile',
                nativeSymbol: 'person.crop.circle',
                nativeSelectedSymbol: 'person.crop.circle.fill',
                nativeRouteName: AppRoutes.profile,
                nativeReplaceStack: true,
                icon: Icons.account_circle_outlined,
                selectedIcon: Icons.account_circle_rounded,
                active: activeTab == WerkaDockTab.profile,
                compact: compact,
                onHoldComplete: activeTab == WerkaDockTab.profile
                    ? () => showLogoutPrompt(context)
                    : null,
                onTap: () {
                  if (activeTab == WerkaDockTab.profile) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.profile,
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
