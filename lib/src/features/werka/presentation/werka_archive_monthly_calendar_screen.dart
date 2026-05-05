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

class WerkaArchiveMonthlyCalendarScreen extends StatefulWidget {
  const WerkaArchiveMonthlyCalendarScreen({
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
  State<WerkaArchiveMonthlyCalendarScreen> createState() =>
      _WerkaArchiveMonthlyCalendarScreenState();
}

class _WerkaArchiveMonthlyCalendarScreenState
    extends State<WerkaArchiveMonthlyCalendarScreen> {
  late int _displayYear;
  bool _loading = true;
  Object? _error;
  Set<int> _activeMonths = <int>{};

  @override
  void initState() {
    super.initState();
    _displayYear = DateTime.now().year;
    _loadYear();
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

  Future<void> _loadYear() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final from = DateTime(_displayYear, 1, 1);
    final to = DateTime(_displayYear, 12, 31);
    try {
      final result = await _archiveLoader(
        kind: widget.kind,
        period: WerkaArchivePeriod.yearly,
        from: from,
        to: to,
      );
      if (!mounted) {
        return;
      }
      final activeMonths = <int>{};
      for (final item in result.items) {
        final created = parseCreatedLabelTimestamp(item.createdLabel);
        if (created == null) {
          continue;
        }
        if (created.year == _displayYear) {
          activeMonths.add(created.month);
        }
      }
      setState(() {
        _activeMonths = activeMonths;
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

  void _openMonth(int month) {
    final from = DateTime(_displayYear, month, 1);
    final to = DateTime(_displayYear, month + 1, 0);
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: widget.kind,
        period: WerkaArchivePeriod.monthly,
        from: from,
        to: to,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = '${_kindTitle(l10n)} • ${l10n.archiveMonthlyTitle}';
    useNativeNavigationTitle(context, title);
    return AppShell(
      title: title,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      appBarBottomLoading: _loading && _activeMonths.isEmpty,
      bottom: const WerkaDock(activeTab: null),
      contentPadding: EdgeInsets.zero,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _activeMonths.isEmpty) {
      return const SizedBox.expand();
    }
    if (_error != null && _activeMonths.isEmpty) {
      return AppRetryState(onRetry: _loadYear);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return RefreshIndicator(
      onRefresh: _loadYear,
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
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() => _displayYear--);
                          _loadYear();
                        },
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$_displayYear',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _displayYear++);
                          _loadYear();
                        },
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (int month = 1; month <= 12; month++)
                        _MonthCell(
                          month: month,
                          label: localizations
                              .formatMonthYear(DateTime(_displayYear, month, 1))
                              .split(' ')
                              .first,
                          active: _activeMonths.contains(month),
                          onTap: () => _openMonth(month),
                        ),
                    ],
                  ),
                  if (_activeMonths.isEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.archiveCalendarEmptyYear,
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

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.month,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final int month;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return SizedBox(
      width: 100,
      child: Material(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        child: GestureDetector(
          key: ValueKey('archive_month_$month'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border:
                  active ? Border.all(color: scheme.primary, width: 1.2) : null,
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
