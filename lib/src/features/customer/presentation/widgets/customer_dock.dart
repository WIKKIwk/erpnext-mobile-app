import '../../../../app/app_router.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/app_navigation_bar.dart';
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
        final bool selectionVisible = activeTab != null;
        final int selectedIndex = switch (activeTab) {
          CustomerDockTab.home => 0,
          CustomerDockTab.notifications => 1,
          CustomerDockTab.profile => 2,
          null => 0,
        };
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: tightToEdges ? 0 : 8),
          child: AppNavigationBar(
            height: compact ? 68 : 72,
            selectionVisible: selectionVisible,
            selectedIndex: selectedIndex,
            destinations: [
              AppNavigationDestination(
                label: 'Uy',
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_filled),
              ),
              AppNavigationDestination(
                label: 'Bildirish',
                icon: const Icon(Icons.notifications_outlined),
                selectedIcon: const Icon(Icons.notifications),
                showBadge: showBadge,
              ),
              AppNavigationDestination(
                label: 'Profil',
                icon: const Icon(Icons.account_circle_outlined),
                selectedIcon: const Icon(Icons.account_circle),
                onLongPress: activeTab == CustomerDockTab.profile
                    ? () => showLogoutPrompt(context)
                    : null,
              ),
            ],
            onDestinationSelected: (index) {
              if (index == 0) {
                if (activeTab == CustomerDockTab.home) return;
                if (onTabSelected != null) {
                  onTabSelected!(CustomerDockTab.home);
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.customerHome,
                    (route) => false,
                  );
                }
                return;
              }
              if (index == 1) {
                if (activeTab == CustomerDockTab.notifications) return;
                if (onTabSelected != null) {
                  onTabSelected!(CustomerDockTab.notifications);
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.customerNotifications,
                    (route) => false,
                  );
                }
                return;
              }
              if (activeTab == CustomerDockTab.profile) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.profile,
                (route) => false,
              );
            },
          ),
        );
      },
    );
  }
}
