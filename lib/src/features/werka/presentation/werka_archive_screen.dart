import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaArchiveScreen extends StatelessWidget {
  const WerkaArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: context.l10n.archiveTitle,
      subtitle: '',
      bottom: const WerkaDock(activeTab: WerkaDockTab.archive),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          _ArchiveModuleCard(
            title: context.l10n.archiveReceivedTitle,
            icon: Icons.inventory_2_outlined,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaArchivePeriods,
              arguments: WerkaArchiveKind.received,
            ),
          ),
          const SizedBox(height: 14),
          _ArchiveModuleCard(
            title: context.l10n.archiveSentTitle,
            icon: Icons.outbox_outlined,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaArchivePeriods,
              arguments: WerkaArchiveKind.sent,
            ),
          ),
          const SizedBox(height: 14),
          _ArchiveModuleCard(
            title: context.l10n.archiveReturnedTitle,
            icon: Icons.assignment_return_outlined,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaArchivePeriods,
              arguments: WerkaArchiveKind.returned,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ArchiveModuleCard extends StatelessWidget {
  const _ArchiveModuleCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
