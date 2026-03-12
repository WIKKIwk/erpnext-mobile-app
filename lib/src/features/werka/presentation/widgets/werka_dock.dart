import '../../../../app/app_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/logout_prompt.dart';
import 'package:flutter/material.dart';

enum WerkaDockTab {
  home,
  notifications,
  profile,
}

class WerkaDock extends StatelessWidget {
  const WerkaDock({
    super.key,
    required this.activeTab,
    this.compact = false,
    this.tightToEdges = false,
  });

  final WerkaDockTab? activeTab;
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
          iconWidget: const DockSvgIcon(
            fillAsset: 'assets/icons/notification-3-fill.svg',
            lineAsset: 'assets/icons/notification-3-line.svg',
            primary: false,
          ),
          active: activeTab == WerkaDockTab.notifications,
          compact: compact,
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
        icon: Icons.inventory_2_outlined,
        primary: true,
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
      trailing: [
        DockButton(
          icon: Icons.history_rounded,
          compact: compact,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Werka recent keyingi bosqichda')),
            );
          },
        ),
        DockButton(
          icon: Icons.person_outline_rounded,
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
  }
}
