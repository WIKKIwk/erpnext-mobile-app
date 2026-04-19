import '../../../../app/app_router.dart';
import '../../../../core/notifications/notification_unread_store.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/app_navigation_bar.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

enum SupplierDockTab {
  home,
  notifications,
  recent,
  profile,
}

class SupplierDock extends StatelessWidget {
  const SupplierDock({
    super.key,
    required this.activeTab,
    this.centerActive = false,
    this.compact = true,
    this.tightToEdges = true,
  });

  final SupplierDockTab? activeTab;
  final bool centerActive;
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
            activeTab != SupplierDockTab.notifications;
        final bool selectionVisible = activeTab != null || centerActive;
        final int selectedIndex = switch (activeTab) {
          SupplierDockTab.home => 0,
          SupplierDockTab.notifications => 1,
          SupplierDockTab.recent => 3,
          SupplierDockTab.profile => 4,
          null => centerActive ? 2 : 0,
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
                label: 'Tarix',
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history_rounded),
              ),
              AppNavigationDestination(
                label: 'Profil',
                icon: const Icon(Icons.account_circle_outlined),
                selectedIcon: const Icon(Icons.account_circle_rounded),
                onLongPress: activeTab == SupplierDockTab.profile
                    ? () => showLogoutPrompt(context)
                    : null,
              ),
            ],
            onDestinationSelected: (index) {
              if (index == 0) {
                if (activeTab == SupplierDockTab.home && !centerActive) {
                  return;
                }
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.supplierHome,
                  (route) => false,
                );
                return;
              }
              if (index == 1) {
                if (activeTab == SupplierDockTab.notifications) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.supplierNotifications,
                  (route) => false,
                );
                return;
              }
              if (index == 2) {
                if (centerActive) return;
                Navigator.of(context).pushNamed(AppRoutes.supplierItemPicker);
                return;
              }
              if (index == 3) {
                if (activeTab == SupplierDockTab.recent) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.supplierRecent,
                  (route) => false,
                );
                return;
              }
              if (activeTab == SupplierDockTab.profile) return;
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
