import '../../../app/app_router.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminCreateHubScreen extends StatelessWidget {
  const AdminCreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Qo‘shish',
      subtitle: '',
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _CreateHubRow(
                  title: 'Supplier qo‘shish',
                  subtitle: 'Supplier yaratish va code boshqaruvi',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminSupplierCreate),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: 'Customer qo‘shish',
                  subtitle: 'Customer yaratish va jo‘natma qabul oqimi',
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminCustomerCreate),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: 'Werka qo‘shish',
                  subtitle: 'Omborchi phone va name sozlash',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminWerka),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: 'ERP sozlamalari',
                  subtitle: 'URL, key, secret va ombor sozlamalari',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminSettings),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: 'Item qo‘shish',
                  subtitle: 'Yangi mahsulot yaratish',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminItemCreate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateHubRow extends StatelessWidget {
  const _CreateHubRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: 24,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}
