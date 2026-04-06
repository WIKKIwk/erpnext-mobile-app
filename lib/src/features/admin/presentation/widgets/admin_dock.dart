import '../../../../app/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
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
    return SharedDockHero(
      tag: 'admin',
      child: ActionDock(
        compact: compact,
        tightToEdges: tightToEdges,
        leading: [
        DockButton(
          nativeId: 'admin_home',
          nativeSymbol: 'house',
          nativeSelectedSymbol: 'house.fill',
          nativeRouteName: AppRoutes.adminHome,
          nativeReplaceStack: true,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          active: activeTab == AdminDockTab.home,
          compact: compact,
          onTap: () {
            if (activeTab == AdminDockTab.home) return;
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.adminHome, (route) => false);
          },
        ),
        DockButton(
          nativeId: 'admin_suppliers',
          nativeSymbol: 'person.3',
          nativeSelectedSymbol: 'person.3.fill',
          nativeRouteName: AppRoutes.adminSuppliers,
          nativeReplaceStack: true,
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups_rounded,
          active: activeTab == AdminDockTab.suppliers,
          compact: compact,
          onTap: () {
            if (activeTab == AdminDockTab.suppliers) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminSuppliers,
              (route) => false,
            );
          },
        ),
        ],
        center: DockButton(
        nativeId: 'admin_create',
        nativeSymbol: 'plus',
        nativeSelectedSymbol: 'plus',
        nativeRouteName: AppRoutes.adminCreateHub,
        nativeReplaceStack: true,
        icon: Icons.add_rounded,
        selectedIcon: Icons.add_rounded,
        primary: true,
        compact: compact,
        onTap: () {
          if (activeTab == AdminDockTab.settings) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.adminCreateHub,
            (route) => false,
          );
        },
        ),
        trailing: [
        DockButton(
          nativeId: 'admin_activity',
          nativeSymbol: 'clock',
          nativeSelectedSymbol: 'clock.fill',
          nativeRouteName: AppRoutes.adminActivity,
          nativeReplaceStack: true,
          icon: Icons.history_outlined,
          selectedIcon: Icons.history_rounded,
          active: activeTab == AdminDockTab.activity,
          compact: compact,
          onTap: () {
            if (activeTab == AdminDockTab.activity) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminActivity,
              (route) => false,
            );
          },
        ),
        DockButton(
          nativeId: 'admin_profile',
          nativeSymbol: 'person.crop.circle',
          nativeSelectedSymbol: 'person.crop.circle.fill',
          nativeRouteName: AppRoutes.profile,
          nativeReplaceStack: true,
          icon: Icons.account_circle_outlined,
          selectedIcon: Icons.account_circle_rounded,
          active: activeTab == AdminDockTab.profile,
          compact: compact,
          onHoldComplete: activeTab == AdminDockTab.profile
              ? () => showLogoutPrompt(context)
              : null,
          onTap: () {
            if (activeTab == AdminDockTab.profile) {
              return;
            }
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.profile, (route) => false);
          },
        ),
        ],
      ),
    );
  }
}
