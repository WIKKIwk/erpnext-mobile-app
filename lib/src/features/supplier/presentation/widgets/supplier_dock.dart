import '../../../../app/app_router.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

enum SupplierDockTab {
  home,
  notifications,
  recent,
}

class SupplierDock extends StatelessWidget {
  const SupplierDock({
    super.key,
    required this.activeTab,
  });

  final SupplierDockTab activeTab;

  @override
  Widget build(BuildContext context) {
    final profile = AppSession.instance.profile;

    return ActionDock(
      leading: [
        DockButton(
          icon: Icons.home_rounded,
          active: activeTab == SupplierDockTab.home,
          onTap: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.supplierHome,
              (route) => false,
            );
          },
        ),
        DockButton(
          icon: Icons.notifications_none_rounded,
          active: activeTab == SupplierDockTab.notifications,
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.supplierNotifications);
          },
        ),
      ],
      center: DockButton(
        icon: Icons.add_rounded,
        primary: true,
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.supplierItemPicker),
      ),
      trailing: [
        DockButton(
          icon: Icons.history_rounded,
          active: activeTab == SupplierDockTab.recent,
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.supplierRecent);
          },
        ),
        DockButton(
          icon: Icons.person_outline_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.profile,
            arguments: ProfileArgs(
              role: UserRole.supplier,
              name: profile?.displayName ?? 'Supplier',
              subtitle: 'Jo‘natish va statuslarni boshqaradi',
            ),
          ),
        ),
      ],
    );
  }
}
