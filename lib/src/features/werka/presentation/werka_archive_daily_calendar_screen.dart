import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
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
  DateTime? _selectedDate;
  bool _loading = true;
  Object? _error;
  bool _calendarOpen = false;
  Set<int> _activeDays = <int>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateUtils.dateOnly(now);
    _calendarOpen = false;
    _loadMonth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _calendarOpen = true;
      });
    });
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

  String _monthSummaryLabel(AppLocalizations l10n) {
    final count = _activeDays.length;
    if (count == 0) {
      return l10n.archiveCalendarEmptyMonth;
    }
    return '$count ta faol kun';
  }

  void _openDay(DateTime selected) {
    final normalized = DateUtils.dateOnly(selected);
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: widget.kind,
        period: WerkaArchivePeriod.daily,
        from: normalized,
        to: normalized,
      ),
    );
  }

  String _selectedDateLabel(BuildContext context) {
    final selected = _selectedDate;
    if (selected == null) {
      return context.l10n.archiveSelectDateAction;
    }
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatMediumDate(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = '${_kindTitle(l10n)} • ${l10n.archiveDailyTitle}';
    useNativeNavigationTitle(context, title);
    return AppShell(
      title: title,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      appBarBottomLoading: _loading && _activeDays.isEmpty,
      bottom: const WerkaDock(activeTab: null),
      contentPadding: EdgeInsets.zero,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _activeDays.isEmpty) {
      return const SizedBox.expand();
    }
    if (_error != null && _activeDays.isEmpty) {
      return AppRetryState(onRetry: _loadMonth);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return RefreshIndicator(
      onRefresh: _loadMonth,
      child: ListView(
        padding: EdgeInsets.fromLTRB(4, 4, 4, bottomPadding),
        children: [
          Card.filled(
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
                                    l10n.archiveDateTitle,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDateLabel(context),
                                    style: AppTheme.archiveSelectionValueStyle(
                                      context,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                setState(() {
                                  _calendarOpen = !_calendarOpen;
                                });
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: Icon(
                                _calendarOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.calendar_month_outlined,
                              ),
                              label: Text(l10n.archiveSelectDateAction),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            _monthSummaryLabel(l10n),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        _AnimatedCalendarReveal(
                          open: _calendarOpen,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Theme(
                              data: theme.copyWith(
                                colorScheme: scheme.copyWith(
                                  primary: scheme.primary,
                                  onPrimary: scheme.onPrimary,
                                  surface: scheme.surfaceContainerHigh,
                                  onSurface: scheme.onSurface,
                                  onSurfaceVariant: scheme.onSurfaceVariant,
                                ),
                              ),
                              child: CalendarDatePicker(
                                initialDate: _selectedDate ?? _displayMonth,
                                firstDate: DateTime(DateTime.now().year - 5),
                                lastDate:
                                    DateTime(DateTime.now().year + 1, 12, 31),
                                currentDate: DateTime.now(),
                                onDisplayedMonthChanged: (value) {
                                  final nextMonth = DateTime(
                                    value.year,
                                    value.month,
                                    1,
                                  );
                                  if (nextMonth == _displayMonth) {
                                    return;
                                  }
                                  setState(() {
                                    _displayMonth = nextMonth;
                                  });
                                  _loadMonth();
                                },
                                onDateChanged: (value) {
                                  setState(() {
                                    _selectedDate = DateUtils.dateOnly(value);
                                    _calendarOpen = false;
                                  });
                                  _openDay(value);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCalendarReveal extends StatelessWidget {
  const _AnimatedCalendarReveal({
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
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            opacity: open ? 1 : 0,
            child: child,
          ),
        ),
      ),
    );
  }
}
