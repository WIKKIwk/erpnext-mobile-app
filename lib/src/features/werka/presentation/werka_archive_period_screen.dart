import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'werka_archive_list_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaArchivePeriodScreen extends StatefulWidget {
  const WerkaArchivePeriodScreen({
    super.key,
    required this.kind,
  });

  final WerkaArchiveKind kind;

  @override
  State<WerkaArchivePeriodScreen> createState() =>
      _WerkaArchivePeriodScreenState();
}

class _WerkaArchivePeriodScreenState extends State<WerkaArchivePeriodScreen> {
  DateTime? _from;
  DateTime? _to;

  String _kindTitle(AppLocalizations l10n) {
    switch (widget.kind) {
      case WerkaArchiveKind.received:
        return l10n.archiveReceivedTitle;
      case WerkaArchiveKind.sent:
        return l10n.archiveSentTitle;
      case WerkaArchiveKind.returned:
        return l10n.archiveReturnedTitle;
    }
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_from ?? _to ?? now)
        : (_to ?? _from ?? now);
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: isStart
          ? context.l10n.archiveStartDateLabel
          : context.l10n.archiveEndDateLabel,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (isStart) {
        _from = DateUtils.dateOnly(picked);
        if (_to != null && _to!.isBefore(_from!)) {
          _to = _from;
        }
      } else {
        _to = DateUtils.dateOnly(picked);
        if (_from != null && _to!.isBefore(_from!)) {
          _from = _to;
        }
      }
    });
  }

  void _openList(BuildContext context, WerkaArchivePeriod period) {
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: widget.kind,
        period: period,
      ),
    );
  }

  void _openCustomRange() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) {
      return;
    }
    if (to.isBefore(from)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.archiveInvalidRange)),
      );
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: widget.kind,
        period: WerkaArchivePeriod.custom,
        from: from,
        to: to,
      ),
    );
  }

  String _dateLabel(DateTime? value, String placeholder) {
    if (value == null) {
      return placeholder;
    }
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }

  @override
  Widget build(BuildContext context) {
    useNativeNavigationTitle(context, _kindTitle(context.l10n));
    return AppShell(
      title: _kindTitle(context.l10n),
      subtitle: context.l10n.archiveChoosePeriod,
      leading: NativeBackButtonSlot(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          _PeriodCard(
            title: context.l10n.archiveDailyTitle,
            onTap: () => _openList(context, WerkaArchivePeriod.daily),
          ),
          const SizedBox(height: 14),
          _PeriodCard(
            title: context.l10n.archiveMonthlyTitle,
            onTap: () => _openList(context, WerkaArchivePeriod.monthly),
          ),
          const SizedBox(height: 14),
          _PeriodCard(
            title: context.l10n.archiveYearlyTitle,
            onTap: () => _openList(context, WerkaArchivePeriod.yearly),
          ),
          const SizedBox(height: 14),
          _CustomRangeCard(
            title: context.l10n.archiveCustomRangeTitle,
            hint: context.l10n.archiveCustomRangeHint,
            startLabel: context.l10n.archiveStartDateLabel,
            endLabel: context.l10n.archiveEndDateLabel,
            startValue:
                _dateLabel(_from, context.l10n.archiveSelectDateAction),
            endValue: _dateLabel(_to, context.l10n.archiveSelectDateAction),
            onPickStart: () => _pickDate(isStart: true),
            onPickEnd: () => _pickDate(isStart: false),
            onView: _from != null && _to != null ? _openCustomRange : null,
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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

class _CustomRangeCard extends StatelessWidget {
  const _CustomRangeCard({
    required this.title,
    required this.hint,
    required this.startLabel,
    required this.endLabel,
    required this.startValue,
    required this.endValue,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onView,
  });

  final String title;
  final String hint;
  final String startLabel;
  final String endLabel;
  final String startValue;
  final String endValue;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              hint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _DateFieldRow(
              label: startLabel,
              value: startValue,
              onTap: onPickStart,
            ),
            const SizedBox(height: 10),
            _DateFieldRow(
              label: endLabel,
              value: endValue,
              onTap: onPickEnd,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(context.l10n.archiveViewAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFieldRow extends StatelessWidget {
  const _DateFieldRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(value, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              const Icon(Icons.calendar_month_outlined),
            ],
          ),
        ),
      ),
    );
  }
}
