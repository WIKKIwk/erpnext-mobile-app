import '../../../../app/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
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
  });

  final AdminDockTab activeTab;

  @override
  Widget build(BuildContext context) {
    return ActionDock(
      leading: [
        DockButton(
          icon: Icons.home_rounded,
          active: activeTab == AdminDockTab.home,
          onTap: () {
            if (activeTab == AdminDockTab.home) return;
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.adminHome, (route) => false);
          },
        ),
        DockButton(
          icon: Icons.inventory_2_outlined,
          active: activeTab == AdminDockTab.suppliers,
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
        icon: Icons.add_rounded,
        primary: true,
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
          iconWidget: const DockSvgIcon(
            fillAsset: 'assets/icons/chat-history-fill.svg',
            lineAsset: 'assets/icons/chat-history-line.svg',
            primary: false,
          ),
          active: activeTab == AdminDockTab.activity,
          onTap: () {
            if (activeTab == AdminDockTab.activity) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.adminActivity,
              (route) => false,
            );
          },
        ),
        DockButton(
          icon: Icons.person_outline_rounded,
          active: activeTab == AdminDockTab.profile,
          onTap: () {
            if (activeTab == AdminDockTab.profile) return;
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.profile, (route) => false);
          },
        ),
      ],
    );
  }
}
