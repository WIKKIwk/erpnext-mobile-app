import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          final nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
          } else {
            nav.pushNamedAndRemoveUntil(
              AppRoutes.adminHome,
              (route) => false,
            );
          }
        },
      ),
      title: context.l10n.adminCreateTitle,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      child: ListView(
        padding: const EdgeInsets.only(top: 4),
        children: [
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _CreateHubRow(
                  title: context.l10n.adminCreateSupplierTitle,
                  subtitle: context.l10n.adminCreateSupplierSubtitle,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminSupplierCreate),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: context.l10n.adminCreateCustomerTitle,
                  subtitle: context.l10n.adminCreateCustomerSubtitle,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminCustomerCreate),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: context.l10n.adminCreateWerkaTitle,
                  subtitle: context.l10n.adminCreateWerkaSubtitle,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminWerka),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: context.l10n.adminErpSettingsTitle,
                  subtitle: context.l10n.adminErpSettingsSubtitle,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.adminSettings),
                ),
                const Divider(height: 1, thickness: 1),
                _CreateHubRow(
                  title: context.l10n.adminCreateItemTitle,
                  subtitle: context.l10n.adminCreateItemSubtitle,
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.adminItemCreate),
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
