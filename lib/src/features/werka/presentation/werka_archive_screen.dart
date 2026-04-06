import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
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
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: _ArchiveModuleGroup(
              rows: [
                _ArchiveModuleRowData(
                  title: context.l10n.archiveReceivedTitle,
                  icon: Icons.inventory_2_outlined,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.werkaArchivePeriods,
                    arguments: WerkaArchiveKind.received,
                  ),
                ),
                _ArchiveModuleRowData(
                  title: context.l10n.archiveSentTitle,
                  icon: Icons.outbox_outlined,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.werkaArchiveSentHub,
                  ),
                ),
                _ArchiveModuleRowData(
                  title: context.l10n.archiveReturnedTitle,
                  icon: Icons.assignment_return_outlined,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.werkaArchivePeriods,
                    arguments: WerkaArchiveKind.returned,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveModuleRowData {
  const _ArchiveModuleRowData({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}

class _ArchiveModuleGroup extends StatelessWidget {
  const _ArchiveModuleGroup({
    required this.rows,
  });

  final List<_ArchiveModuleRowData> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (int index = 0; index < rows.length; index++) ...[
            _ArchiveModuleRow(
              title: rows[index].title,
              icon: rows[index].icon,
              onTap: rows[index].onTap,
              isFirst: index == 0,
              isLast: index == rows.length - 1,
            ),
            if (index != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 18,
                endIndent: 18,
                color: scheme.outlineVariant.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

class _ArchiveModuleRow extends StatelessWidget {
  const _ArchiveModuleRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isFirst ? 28 : 0),
        topRight: Radius.circular(isFirst ? 28 : 0),
        bottomLeft: Radius.circular(isLast ? 28 : 0),
        bottomRight: Radius.circular(isLast ? 28 : 0),
      ),
    );
    return PressableScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 74),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Center(
                      child: Icon(icon, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
