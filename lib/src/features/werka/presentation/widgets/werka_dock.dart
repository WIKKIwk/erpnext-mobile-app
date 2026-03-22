import '../../../../app/app_router.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/ios_liquid_dock.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum WerkaDockTab {
  home,
  notifications,
  recent,
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
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          return IOSLiquidDock(
            compact: compact,
            tightToEdges: tightToEdges,
            items: <IOSLiquidDockItem>[
              IOSLiquidDockItem(
                id: 'home',
                active: activeTab == WerkaDockTab.home,
              ),
              IOSLiquidDockItem(
                id: 'notifications',
                active: activeTab == WerkaDockTab.notifications,
                showBadge: showBadge,
              ),
              const IOSLiquidDockItem(
                id: 'create',
                active: false,
                primary: true,
              ),
              IOSLiquidDockItem(
                id: 'recent',
                active: activeTab == WerkaDockTab.recent,
              ),
              IOSLiquidDockItem(
                id: 'profile',
                active: activeTab == WerkaDockTab.profile,
                allowLongPress: activeTab == WerkaDockTab.profile,
              ),
            ],
            onTap: (id) {
              switch (id) {
                case 'home':
                  if (activeTab == WerkaDockTab.home) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.werkaHome,
                    (route) => false,
                  );
                  return;
                case 'notifications':
                  if (activeTab == WerkaDockTab.notifications) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.werkaNotifications,
                    (route) => false,
                  );
                  return;
                case 'create':
                  Navigator.of(context).pushNamed(AppRoutes.werkaCreateHub);
                  return;
                case 'recent':
                  if (activeTab == WerkaDockTab.recent) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.werkaRecent,
                    (route) => false,
                  );
                  return;
                case 'profile':
                  if (activeTab == WerkaDockTab.profile) {
                    return;
                  }
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.profile,
                    (route) => false,
                  );
                  return;
              }
            },
            onLongPress: (id) {
              if (id == 'profile' && activeTab == WerkaDockTab.profile) {
                showLogoutPrompt(context);
              }
            },
          );
        }
        return ActionDock(
          compact: compact,
          tightToEdges: tightToEdges,
          leading: [
            DockButton(
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
              icon: Icons.history_rounded,
              selectedIcon: Icons.history_rounded,
              active: activeTab == WerkaDockTab.recent,
              compact: compact,
              onTap: () {
                if (activeTab == WerkaDockTab.recent) {
                  return;
                }
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.werkaRecent,
                  (route) => false,
                );
              },
            ),
            DockButton(
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
        );
      },
    );
  }
}
