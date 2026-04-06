import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'werka_archive_list_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaArchiveSentHubScreen extends StatefulWidget {
  const WerkaArchiveSentHubScreen({
    super.key,
    this.archiveLoader,
  });

  final Future<WerkaArchiveResponse> Function({
    required WerkaArchiveKind kind,
    required WerkaArchivePeriod period,
    DateTime? from,
    DateTime? to,
  })? archiveLoader;

  @override
  State<WerkaArchiveSentHubScreen> createState() =>
      _WerkaArchiveSentHubScreenState();
}

class _WerkaArchiveSentHubScreenState extends State<WerkaArchiveSentHubScreen> {
  late DateTime _displayMonth;
  late DateTime _selectedDate;
  late int _displayYear;
  late int _startYear;

  bool _loading = true;
  Object? _error;
  bool _dailyOpen = true;
  bool _monthlyOpen = false;
  bool _yearlyOpen = false;
  Set<int> _activeDays = <int>{};
  Set<int> _activeMonths = <int>{};
  Set<int> _activeYears = <int>{};

  void _toggleSection(WerkaArchivePeriod period) {
    setState(() {
      final currentlyOpen = switch (period) {
        WerkaArchivePeriod.daily => _dailyOpen,
        WerkaArchivePeriod.monthly => _monthlyOpen,
        WerkaArchivePeriod.yearly => _yearlyOpen,
        WerkaArchivePeriod.custom => false,
      };
      _dailyOpen = false;
      _monthlyOpen = false;
      _yearlyOpen = false;
      if (!currentlyOpen) {
        switch (period) {
          case WerkaArchivePeriod.daily:
            _dailyOpen = true;
          case WerkaArchivePeriod.monthly:
            _monthlyOpen = true;
          case WerkaArchivePeriod.yearly:
            _yearlyOpen = true;
          case WerkaArchivePeriod.custom:
            break;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateUtils.dateOnly(now);
    _displayYear = now.year;
    _startYear = now.year - 5;
    _loadCurrent();
  }

  Future<WerkaArchiveResponse> _archive({
    required WerkaArchivePeriod period,
    DateTime? from,
    DateTime? to,
  }) {
    final loader = widget.archiveLoader;
    if (loader != null) {
      return loader(
        kind: WerkaArchiveKind.sent,
        period: period,
        from: from,
        to: to,
      );
    }
    return MobileApi.instance.werkaArchive(
      kind: WerkaArchiveKind.sent,
      period: period,
      from: from,
      to: to,
    );
  }

  Future<void> _loadCurrent() async {
    await Future.wait([
      _loadDaily(),
      _loadMonthly(),
      _loadYearly(),
    ]);
  }

  Future<void> _loadDaily() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _archive(
        period: WerkaArchivePeriod.monthly,
        from: DateTime(_displayMonth.year, _displayMonth.month, 1),
        to: DateTime(_displayMonth.year, _displayMonth.month + 1, 0),
      );
      if (!mounted) {
        return;
      }
      final days = <int>{};
      for (final item in result.items) {
        final created = parseCreatedLabelTimestamp(item.createdLabel);
        if (created != null &&
            created.year == _displayMonth.year &&
            created.month == _displayMonth.month) {
          days.add(created.day);
        }
      }
      setState(() {
        _activeDays = days;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMonthly() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _archive(
        period: WerkaArchivePeriod.yearly,
        from: DateTime(_displayYear, 1, 1),
        to: DateTime(_displayYear, 12, 31),
      );
      if (!mounted) {
        return;
      }
      final months = <int>{};
      for (final item in result.items) {
        final created = parseCreatedLabelTimestamp(item.createdLabel);
        if (created != null && created.year == _displayYear) {
          months.add(created.month);
        }
      }
      setState(() {
        _activeMonths = months;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadYearly() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _archive(
        period: WerkaArchivePeriod.yearly,
        from: DateTime(_startYear, 1, 1),
        to: DateTime(_startYear + 11, 12, 31),
      );
      if (!mounted) {
        return;
      }
      final years = <int>{};
      for (final item in result.items) {
        final created = parseCreatedLabelTimestamp(item.createdLabel);
        if (created != null &&
            created.year >= _startYear &&
            created.year <= _startYear + 11) {
          years.add(created.year);
        }
      }
      setState(() {
        _activeYears = years;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _openList({
    required WerkaArchivePeriod period,
    required DateTime from,
    required DateTime to,
  }) {
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: WerkaArchiveKind.sent,
        period: period,
        from: from,
        to: to,
      ),
    );
  }

  String _selectedDateLabel(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatMediumDate(_selectedDate);
  }

  String _selectedMonthLabel(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatMonthYear(DateTime(_displayYear, 1, 1));
  }

  String _selectedYearLabel() => '$_startYear - ${_startYear + 11}';

  double _dailyCalendarHeightFactor(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstDayOffset = DateUtils.firstDayOffset(
      _displayMonth.year,
      _displayMonth.month,
      localizations,
    );
    final rowCount = ((firstDayOffset + daysInMonth + 6) ~/ 7);
    return (rowCount + 1) / 7;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    useNativeNavigationTitle(context, l10n.archiveSentTitle);
    return AppShell(
      title: l10n.archiveSentTitle,
      subtitle: l10n.archiveChoosePeriod,
      leading: NativeBackButtonSlot(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading &&
        _activeDays.isEmpty &&
        _activeMonths.isEmpty &&
        _activeYears.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }
    if (_error != null &&
        _activeDays.isEmpty &&
        _activeMonths.isEmpty &&
        _activeYears.isEmpty) {
      return AppRetryState(onRetry: _loadCurrent);
    }

    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: _loadCurrent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          _SentArchiveExpandableCard(
            title: l10n.archiveDailyTitle,
            value: _selectedDateLabel(context),
            actionLabel: l10n.archiveSelectDateAction,
            open: _dailyOpen,
            topGap: 0,
            onToggle: () => _toggleSection(WerkaArchivePeriod.daily),
            child: _buildDailyPanel(context),
          ),
          const SizedBox(height: 14),
          _SentArchiveExpandableCard(
            title: l10n.archiveMonthlyTitle,
            value: _selectedMonthLabel(context),
            actionLabel: l10n.archiveSelectMonthAction,
            open: _monthlyOpen,
            onToggle: () => _toggleSection(WerkaArchivePeriod.monthly),
            child: _buildMonthlyPanel(context),
          ),
          const SizedBox(height: 14),
          _SentArchiveExpandableCard(
            title: l10n.archiveYearlyTitle,
            value: _selectedYearLabel(),
            actionLabel: l10n.archiveSelectDateAction,
            open: _yearlyOpen,
            onToggle: () => _toggleSection(WerkaArchivePeriod.yearly),
            child: _buildYearlyPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPanel(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () async {
                setState(() => _displayYear--);
                await _loadMonthly();
              },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '$_displayYear',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: () async {
                setState(() => _displayYear++);
                await _loadMonthly();
              },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (int month = 1; month <= 12; month++)
              _SentHubMonthCell(
                label: localizations
                    .formatMonthYear(DateTime(_displayYear, month, 1))
                    .split(' ')
                    .first,
                active: _activeMonths.contains(month),
                onTap: () {
                  final from = DateTime(_displayYear, month, 1);
                  final to = DateTime(_displayYear, month + 1, 0);
                  _openList(
                    period: WerkaArchivePeriod.monthly,
                    from: from,
                    to: to,
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearlyPanel(BuildContext context) {
    final theme = Theme.of(context);
    final years = [for (int year = _startYear; year <= _startYear + 11; year++) year];
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () async {
                setState(() => _startYear -= 12);
                await _loadYearly();
              },
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                '${years.first} - ${years.last}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: () async {
                setState(() => _startYear += 12);
                await _loadYearly();
              },
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final cellWidth = (constraints.maxWidth - (spacing * 2)) / 3;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final year in years)
                  _SentHubYearCell(
                    width: cellWidth,
                    year: year,
                    active: _activeYears.contains(year),
                    onTap: () {
                      _openList(
                        period: WerkaArchivePeriod.yearly,
                        from: DateTime(year, 1, 1),
                        to: DateTime(year, 12, 31),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDailyPanel(BuildContext context) {
    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: _dailyCalendarHeightFactor(context),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) {},
          onVerticalDragUpdate: (_) {},
          onVerticalDragEnd: (_) {},
          onVerticalDragCancel: () {},
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(DateTime.now().year - 5),
            lastDate: DateTime(DateTime.now().year + 1, 12, 31),
            currentDate: DateTime.now(),
            onDisplayedMonthChanged: (value) async {
              final nextMonth = DateTime(value.year, value.month, 1);
              if (nextMonth == _displayMonth) return;
              setState(() => _displayMonth = nextMonth);
              await _loadDaily();
            },
            onDateChanged: (value) {
              final date = DateUtils.dateOnly(value);
              setState(() => _selectedDate = date);
              _openList(period: WerkaArchivePeriod.daily, from: date, to: date);
            },
          ),
        ),
      ),
    );
  }
}

class _SentArchiveExpandableCard extends StatelessWidget {
  const _SentArchiveExpandableCard({
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.open,
    this.topGap = 14,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String value;
  final String actionLabel;
  final bool open;
  final double topGap;
  final VoidCallback onToggle;
  final Widget child;

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
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.40),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onToggle,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: Icon(
                          open
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.calendar_month_outlined,
                        ),
                        label: Text(actionLabel),
                      ),
                    ],
                  ),
                  _AnimatedSentCalendarReveal(
                    open: open,
                    child: Padding(
                      padding: EdgeInsets.only(top: topGap),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSentCalendarReveal extends StatelessWidget {
  const _AnimatedSentCalendarReveal({
    required this.open,
    required this.child,
  });

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        heightFactor: open ? 1 : 0,
        child: IgnorePointer(
          ignoring: !open,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (_) {},
            onVerticalDragUpdate: (_) {},
            onVerticalDragEnd: (_) {},
            onVerticalDragCancel: () {},
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              opacity: open ? 1 : 0,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SentHubMonthCell extends StatelessWidget {
  const _SentHubMonthCell({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return SizedBox(
      width: 86,
      child: Material(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: active
                  ? Border.all(color: scheme.primary, width: 1.2)
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SentHubYearCell extends StatelessWidget {
  const _SentHubYearCell({
    required this.width,
    required this.year,
    required this.active,
    required this.onTap,
  });

  final double width;
  final int year;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Material(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: active
                  ? Border.all(color: scheme.primary, width: 1.2)
                  : null,
            ),
            child: Text(
              '$year',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
