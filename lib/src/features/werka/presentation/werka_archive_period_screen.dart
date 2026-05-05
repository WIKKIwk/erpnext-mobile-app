import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'werka_archive_list_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaArchivePeriodScreen extends StatelessWidget {
  const WerkaArchivePeriodScreen({
    super.key,
    required this.kind,
  });

  final WerkaArchiveKind kind;

  static const int _entryCount = 3;

  String _kindTitle(AppLocalizations l10n) {
    switch (kind) {
      case WerkaArchiveKind.received:
        return l10n.archiveReceivedTitle;
      case WerkaArchiveKind.sent:
        return l10n.archiveSentTitle;
      case WerkaArchiveKind.returned:
        return l10n.archiveReturnedTitle;
    }
  }

  void _openList(BuildContext context, WerkaArchivePeriod period) {
    if (period == WerkaArchivePeriod.daily) {
      Navigator.of(context).pushNamed(
        AppRoutes.werkaArchiveDailyCalendar,
        arguments: kind,
      );
      return;
    }
    if (period == WerkaArchivePeriod.monthly) {
      Navigator.of(context).pushNamed(
        AppRoutes.werkaArchiveMonthlyCalendar,
        arguments: kind,
      );
      return;
    }
    if (period == WerkaArchivePeriod.yearly) {
      Navigator.of(context).pushNamed(
        AppRoutes.werkaArchiveYearlyCalendar,
        arguments: kind,
      );
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: kind,
        period: period,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = _kindTitle(l10n);
    useNativeNavigationTitle(context, title);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;

    return AppShell(
      title: title,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const WerkaDock(activeTab: null),
      contentPadding: EdgeInsets.zero,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
        children: [
          M3SegmentSpacedColumn(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              _WerkaArchivePeriodSegmentTile(
                index: 0,
                itemCount: _entryCount,
                title: l10n.archiveDailyTitle,
                onTap: () => _openList(context, WerkaArchivePeriod.daily),
              ),
              _WerkaArchivePeriodSegmentTile(
                index: 1,
                itemCount: _entryCount,
                title: l10n.archiveMonthlyTitle,
                onTap: () => _openList(context, WerkaArchivePeriod.monthly),
              ),
              _WerkaArchivePeriodSegmentTile(
                index: 2,
                itemCount: _entryCount,
                title: l10n.archiveYearlyTitle,
                onTap: () => _openList(context, WerkaArchivePeriod.yearly),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WerkaArchivePeriodSegmentTile extends StatelessWidget {
  const _WerkaArchivePeriodSegmentTile({
    required this.index,
    required this.itemCount,
    required this.title,
    required this.onTap,
  });

  final int index;
  final int itemCount;
  final String title;
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
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
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
