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

class WerkaArchiveYearlyCalendarScreen extends StatefulWidget {
  const WerkaArchiveYearlyCalendarScreen({
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
  State<WerkaArchiveYearlyCalendarScreen> createState() =>
      _WerkaArchiveYearlyCalendarScreenState();
}

class _WerkaArchiveYearlyCalendarScreenState
    extends State<WerkaArchiveYearlyCalendarScreen> {
  late int _startYear;
  bool _loading = true;
  Object? _error;
  Set<int> _activeYears = <int>{};

  @override
  void initState() {
    super.initState();
    _startYear = DateTime.now().year - 5;
    _loadYears();
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

  Future<void> _loadYears() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final from = DateTime(_startYear, 1, 1);
    final to = DateTime(_startYear + 11, 12, 31);
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
      final activeYears = <int>{};
      for (final item in result.items) {
        final created = parseCreatedLabelTimestamp(item.createdLabel);
        if (created == null) {
          continue;
        }
        if (created.year >= _startYear && created.year <= _startYear + 11) {
          activeYears.add(created.year);
        }
      }
      setState(() {
        _activeYears = activeYears;
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

  void _openYear(int year) {
    final from = DateTime(year, 1, 1);
    final to = DateTime(year, 12, 31);
    Navigator.of(context).pushNamed(
      AppRoutes.werkaArchiveList,
      arguments: WerkaArchiveListArgs(
        kind: widget.kind,
        period: WerkaArchivePeriod.yearly,
        from: from,
        to: to,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = '${_kindTitle(l10n)} • ${l10n.archiveYearlyTitle}';
    useNativeNavigationTitle(context, title);
    return AppShell(
      title: title,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      appBarBottomLoading: _loading && _activeYears.isEmpty,
      bottom: const WerkaDock(activeTab: null),
      contentPadding: EdgeInsets.zero,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _activeYears.isEmpty) {
      return const SizedBox.expand();
    }
    if (_error != null && _activeYears.isEmpty) {
      return AppRetryState(onRetry: _loadYears);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final years = [
      for (int year = _startYear; year <= _startYear + 11; year++) year
    ];

    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return RefreshIndicator(
      onRefresh: _loadYears,
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
                          setState(() => _startYear -= 12);
                          _loadYears();
                        },
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${years.first} - ${years.last}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _startYear += 12);
                          _loadYears();
                        },
                        icon: Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 10.0;
                      final cellWidth =
                          (constraints.maxWidth - (spacing * 2)) / 3;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final year in years)
                            _YearCell(
                              width: cellWidth,
                              year: year,
                              active: _activeYears.contains(year),
                              onTap: () => _openYear(year),
                            ),
                        ],
                      );
                    },
                  ),
                  if (_activeYears.isEmpty) ...[
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

class _YearCell extends StatelessWidget {
  const _YearCell({
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
          key: ValueKey('archive_year_$year'),
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
