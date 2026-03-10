import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_module_card.dart';
import 'package:flutter/material.dart';

class AdminCreateHubScreen extends StatelessWidget {
  const AdminCreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Qo‘shish',
      subtitle: 'Admin modullari va sozlamalari.',
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          AdminModuleCard(
            title: 'Supplier qo‘shish',
            subtitle: 'Supplier yaratish va code boshqaruvi',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.adminSuppliers),
          ),
          const SizedBox(height: 12),
          AdminModuleCard(
            title: 'Werka qo‘shish',
            subtitle: 'Omborchi phone va name sozlash',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminWerka),
          ),
          const SizedBox(height: 12),
          AdminModuleCard(
            title: 'ERP sozlamalari',
            subtitle: 'URL, key, secret va ombor sozlamalari',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.adminSettings),
          ),
          const SizedBox(height: 12),
          AdminModuleCard(
            title: 'Item qo‘shish',
            subtitle: 'Yangi mahsulot yaratish',
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.adminItemCreate),
          ),
        ],
      ),
    );
  }
}
