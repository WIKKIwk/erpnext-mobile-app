import '../../../../app/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
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
    this.compact = false,
    this.tightToEdges = false,
  });

  final SupplierDockTab? activeTab;
  final bool centerActive;
  final bool compact;
  final bool tightToEdges;

  @override
  Widget build(BuildContext context) {
    return ActionDock(
      compact: compact,
      tightToEdges: tightToEdges,
      leading: [
        DockButton(
          iconWidget: const DockSvgIcon(
            fillAsset: 'assets/icons/home-fill.svg',
            lineAsset: 'assets/icons/home-line.svg',
            primary: false,
          ),
          active: activeTab == SupplierDockTab.home,
          compact: compact,
          onTap: () {
            if (activeTab == SupplierDockTab.home && !centerActive) {
              return;
            }
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.supplierHome,
              (route) => false,
            );
          },
        ),
        DockButton(
          iconWidget: const DockSvgIcon(
            fillAsset: 'assets/icons/notification-3-fill.svg',
            lineAsset: 'assets/icons/notification-3-line.svg',
            primary: false,
          ),
          active: activeTab == SupplierDockTab.notifications,
          compact: compact,
          onTap: () {
            if (activeTab == SupplierDockTab.notifications) {
              return;
            }
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.supplierNotifications,
              (route) => false,
            );
          },
        ),
      ],
      center: DockButton(
        icon: Icons.add_rounded,
        primary: true,
        compact: compact,
        onTap: () {
          if (centerActive) {
            return;
          }
          Navigator.of(context).pushNamed(AppRoutes.supplierItemPicker);
        },
      ),
      trailing: [
        DockButton(
          iconWidget: const DockSvgIcon(
            fillAsset: 'assets/icons/repeat-2-fill.svg',
            lineAsset: 'assets/icons/repeat-2-fill.svg',
            primary: false,
          ),
          active: activeTab == SupplierDockTab.recent,
          compact: compact,
          onTap: () {
            if (activeTab == SupplierDockTab.recent) {
              return;
            }
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.supplierRecent,
              (route) => false,
            );
          },
        ),
        DockButton(
          iconWidget: const DockSvgIcon(
            fillAsset: 'assets/icons/account-circle-fill.svg',
            lineAsset: 'assets/icons/account-circle-line.svg',
            primary: false,
          ),
          active: activeTab == SupplierDockTab.profile,
          compact: compact,
          onHoldComplete: activeTab == SupplierDockTab.profile
              ? () => showLogoutPrompt(context)
              : null,
          onTap: () {
            if (activeTab == SupplierDockTab.profile) {
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
  }
}
