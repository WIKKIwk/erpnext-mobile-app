import '../../../../app/app_router.dart';
import '../../../../core/widgets/app_navigation_bar.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

enum AdminDockTab {
  home,
  suppliers,
  settings,
  activity,
  profile,
}

class AdminDock extends StatelessWidget {
  const AdminDock({
    super.key,
    required this.activeTab,
    this.compact = true,
    this.tightToEdges = true,
  });

  final AdminDockTab activeTab;
  final bool compact;
  final bool tightToEdges;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = switch (activeTab) {
      AdminDockTab.home => 0,
      AdminDockTab.suppliers => 1,
      AdminDockTab.settings => 2,
      AdminDockTab.activity => 3,
      AdminDockTab.profile => 4,
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tightToEdges ? 0 : 8),
      child: AppNavigationBar(
        height: compact ? 68 : 72,
        selectedIndex: selectedIndex,
        destinations: [
          AppNavigationDestination(
            label: 'Uy',
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
          ),
          AppNavigationDestination(
            label: 'Yetkazuvchilar',
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
          ),
          AppNavigationDestination(
            label: 'Yangi',
            icon: const Icon(Icons.add_rounded),
            selectedIcon: const Icon(Icons.add_rounded),
            isPrimary: true,
          ),
          AppNavigationDestination(
            label: 'Faoliyat',
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
          ),
          AppNavigationDestination(
            label: 'Profil',
            icon: const Icon(Icons.account_circle_outlined),
            selectedIcon: const Icon(Icons.account_circle_rounded),
            onLongPress: activeTab == AdminDockTab.profile
                ? () => showLogoutPrompt(context)
                : null,
          ),
        ],
        onDestinationSelected: (index) {
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
            if (activeTab == AdminDockTab.settings) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminCreateHub,
              (route) => false,
            );
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
          if (activeTab == AdminDockTab.profile) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.profile,
            (route) => false,
          );
        },
      ),
    );
  }
}
