import '../../../../app/app_router.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

enum CustomerDockTab {
  home,
  notifications,
  profile,
}

class CustomerDock extends StatelessWidget {
  const CustomerDock({
    super.key,
    required this.activeTab,
    this.onTabSelected,
    this.compact = false,
    this.tightToEdges = false,
  });

  final CustomerDockTab? activeTab;
  final ValueChanged<CustomerDockTab>? onTabSelected;
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
            activeTab != CustomerDockTab.notifications;
        return SharedDockHero(
          tag: 'customer',
          child: ActionDock(
            compact: compact,
            tightToEdges: tightToEdges,
            centered: true,
            liftCenter: false,
            leading: [
            DockButton(
              nativeId: 'customer_home',
              nativeSymbol: 'house',
              nativeSelectedSymbol: 'house.fill',
              nativeRouteName: AppRoutes.customerHome,
              nativeReplaceStack: true,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_filled,
              active: activeTab == CustomerDockTab.home,
              compact: compact,
              onTap: () {
                if (activeTab == CustomerDockTab.home) {
                  return;
                }
                if (onTabSelected != null) {
                  onTabSelected!(CustomerDockTab.home);
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.customerHome,
                    (route) => false,
                  );
                }
              },
            ),
            ],
            center: DockButton(
            nativeId: 'customer_notifications',
            nativeSymbol: 'bell',
            nativeSelectedSymbol: 'bell.fill',
            nativeRouteName: AppRoutes.customerNotifications,
            nativeReplaceStack: true,
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications,
            active: activeTab == CustomerDockTab.notifications,
            primary: false,
            showBadge: showBadge,
            compact: compact,
            onTap: () {
              if (activeTab == CustomerDockTab.notifications) {
                return;
              }
              if (onTabSelected != null) {
                onTabSelected!(CustomerDockTab.notifications);
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.customerNotifications,
                  (route) => false,
                );
              }
            },
            ),
            trailing: [
            DockButton(
              nativeId: 'customer_profile',
              nativeSymbol: 'person.crop.circle',
              nativeSelectedSymbol: 'person.crop.circle.fill',
              nativeRouteName: AppRoutes.profile,
              nativeReplaceStack: true,
              icon: Icons.account_circle_outlined,
              selectedIcon: Icons.account_circle,
              active: activeTab == CustomerDockTab.profile,
              compact: compact,
              onHoldComplete: activeTab == CustomerDockTab.profile
                  ? () => showLogoutPrompt(context)
                  : null,
              onTap: () {
                if (activeTab == CustomerDockTab.profile) {
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
