import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaArchiveScreen extends StatelessWidget {
  const WerkaArchiveScreen({super.key});

  static const int _entryCount = 3;

  @override
  Widget build(BuildContext context) {
    useNativeNavigationTitle(context, context.l10n.archiveTitle);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;

    return AppShell(
      title: context.l10n.archiveTitle,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const WerkaDock(activeTab: WerkaDockTab.archive),
      contentPadding: EdgeInsets.zero,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
        children: [
          M3SegmentSpacedColumn(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _WerkaArchiveSegmentTile(
                index: 0,
                itemCount: _entryCount,
                title: context.l10n.archiveReceivedTitle,
                icon: Icons.inventory_2_outlined,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.werkaArchivePeriods,
                  arguments: WerkaArchiveKind.received,
                ),
              ),
              _WerkaArchiveSegmentTile(
                index: 1,
                itemCount: _entryCount,
                title: context.l10n.archiveSentTitle,
                icon: Icons.outbox_outlined,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.werkaArchiveSentHub,
                ),
              ),
              _WerkaArchiveSegmentTile(
                index: 2,
                itemCount: _entryCount,
                title: context.l10n.archiveReturnedTitle,
                icon: Icons.assignment_return_outlined,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.werkaArchivePeriods,
                  arguments: WerkaArchiveKind.returned,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WerkaArchiveSegmentTile extends StatelessWidget {
  const _WerkaArchiveSegmentTile({
    required this.index,
    required this.itemCount,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final int index;
  final int itemCount;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slot = M3SegmentedListGeometry.standaloneListSlotForIndex(
      index,
      itemCount,
    );
    final r = M3SegmentedListGeometry.cornerRadiusForSlot(slot);

    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: r,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
