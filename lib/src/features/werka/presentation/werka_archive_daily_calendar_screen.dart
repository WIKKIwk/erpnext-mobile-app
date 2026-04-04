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

class WerkaArchiveDailyCalendarScreen extends StatefulWidget {
  const WerkaArchiveDailyCalendarScreen({
    super.key,
    required this.kind,
    this.archiveLoader,
  });

  final WerkaArchiveKind kind;
  final Future<WerkaArchiveResponse> Function({
    required WerkaArchiveKind kind,
    required WerkaArchivePeriod period,
    DateTime? from,
    DateTime? to,
  })? archiveLoader;

  @override
  State<WerkaArchiveDailyCalendarScreen> createState() =>
      _WerkaArchiveDailyCalendarScreenState();
}

class _WerkaArchiveDailyCalendarScreenState
    extends State<WerkaArchiveDailyCalendarScreen> {
  late DateTime _displayMonth;
  bool _loading = true;
  Object? _error;
  Set<int> _activeDays = <int>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month, 1);
    _loadMonth();
  }

  Future<WerkaArchiveResponse> _archiveLoader({
    required WerkaArchiveKind kind,
    required WerkaArchivePeriod period,
    DateTime? from,
    DateTime? to,
  }) {
    final loader = widget.archiveLoader;
    if (loader != null) {
      return loader(
        kind: kind,
        period: period,
        from: from,
        to: to,
      );
    }
    return MobileApi.instance.werkaArchive(
      kind: kind,
      period: period,
      from: from,
      to: to,
    );
  }

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final monthStart = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final monthEnd = DateTime(_displayMonth.year, _displayMonth.month + 1, 0);
    try {
      final result = await _archiveLoader(
        kind: widget.kind,
        period: WerkaArchivePeriod.monthly,
        from: monthStart,
        to: monthEnd,
      );
      if (!mounted) {
        return;
      }
      final activeDays = <int>{};
      for (final item in result.items) {
        final created = parseCreatedLabelTimestamp(item.createdLabel);
        if (created == null) {
          continue;
        }
        if (created.year == _displayMonth.year &&
            created.month == _displayMonth.month) {
          activeDays.add(created.day);
        }
      }
      setState(() {
        _activeDays = activeDays;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

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

  List<String> _weekdayLabels(MaterialLocalizations localizations) {
    final narrow = localizations.narrowWeekdays;
    final start = localizations.firstDayOfWeekIndex;
    return [
      for (int i = 0; i < 7; i++) narrow[(start + i) % 7],
    ];
  }

  List<_CalendarCell> _buildCells(MaterialLocalizations localizations) {
    final year = _displayMonth.year;
    final month = _displayMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOffset = DateUtils.firstDayOffset(year, month, localizations);
    final total = ((firstDayOffset + daysInMonth + 6) ~/ 7) * 7;
    return [
      for (int index = 0; index < total; index++)
        if (index < firstDayOffset || index >= firstDayOffset + daysInMonth)
          const _CalendarCell.empty()
        else
          _CalendarCell.day(
            day: index - firstDayOffset + 1,
            active: _activeDays.contains(index - firstDayOffset + 1),
          ),
    ];
  }

  void _openDay(int day) {
    if (!_activeDays.contains(day)) {
      return;
    }
    final selected = DateTime(_displayMonth.year, _displayMonth.month, day);
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: widget.kind,
        period: WerkaArchivePeriod.daily,
        from: selected,
        to: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    useNativeNavigationTitle(context, '${_kindTitle(l10n)} • ${l10n.archiveDailyTitle}');
    return AppShell(
      title: '${_kindTitle(l10n)} • ${l10n.archiveDailyTitle}',
      subtitle: l10n.archiveCalendarHint,
      leading: NativeBackButtonSlot(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _activeDays.isEmpty) {
      return const Center(child: AppLoadingIndicator());
    }
    if (_error != null && _activeDays.isEmpty) {
      return AppRetryState(onRetry: _loadMonth);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final cells = _buildCells(localizations);
    final weekdayLabels = _weekdayLabels(localizations);

    return RefreshIndicator(
      onRefresh: _loadMonth,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _displayMonth = DateTime(
                              _displayMonth.year,
                              _displayMonth.month - 1,
                              1,
                            );
                          });
                          _loadMonth();
                        },
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          localizations.formatMonthYear(_displayMonth),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _displayMonth = DateTime(
                              _displayMonth.year,
                              _displayMonth.month + 1,
                              1,
                            );
                          });
                          _loadMonth();
                        },
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final label in weekdayLabels)
                        Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cells.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final cell = cells[index];
                      if (!cell.hasDay) {
                        return const SizedBox.shrink();
                      }
                      return _CalendarDayCell(
                        day: cell.day!,
                        active: cell.active,
                        onTap: cell.active ? () => _openDay(cell.day!) : null,
                      );
                    },
                  ),
                  if (_activeDays.isEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.archiveCalendarEmptyMonth,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCell {
  const _CalendarCell.empty()
      : hasDay = false,
        day = null,
        active = false;

  const _CalendarCell.day({
    required this.day,
    required this.active,
  }) : hasDay = true;

  final bool hasDay;
  final int? day;
  final bool active;
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.active,
    required this.onTap,
  });

  final int day;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Material(
      color: active
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: active
                ? Border.all(color: scheme.primary, width: 1.2)
                : null,
          ),
          child: Text(
            '$day',
            style: theme.textTheme.titleMedium?.copyWith(
              color: active
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
