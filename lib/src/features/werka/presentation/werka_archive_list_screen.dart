import '../../../core/api/mobile_api.dart';
import '../../../core/files/archive_pdf_saver.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaArchiveListArgs {
  const WerkaArchiveListArgs({
    required this.kind,
    required this.period,
    this.from,
    this.to,
  });

  final WerkaArchiveKind kind;
  final WerkaArchivePeriod period;
  final DateTime? from;
  final DateTime? to;
}

class WerkaArchiveListScreen extends StatefulWidget {
  const WerkaArchiveListScreen({
    super.key,
    required this.args,
  });

  final WerkaArchiveListArgs args;

  @override
  State<WerkaArchiveListScreen> createState() => _WerkaArchiveListScreenState();
}

class _WerkaArchiveListScreenState extends State<WerkaArchiveListScreen> {
  bool _loading = true;
  bool _downloading = false;
  Object? _error;
  WerkaArchiveResponse? _data;
  late DateTime? _from;
  late DateTime? _to;
  bool _showDateCalendar = false;

  @override
  void initState() {
    super.initState();
    _from = widget.args.from;
    _to = widget.args.to;
    final now = DateTime.now();
    if (widget.args.period == WerkaArchivePeriod.daily &&
        (_from == null || _to == null)) {
      final selected = DateUtils.dateOnly(now);
      _from = selected;
      _to = selected;
    } else if (widget.args.period == WerkaArchivePeriod.monthly &&
        (_from == null || _to == null)) {
      _from = DateTime(now.year, now.month, 1);
      _to = _lastDayOfMonth(now.year, now.month);
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MobileApi.instance.werkaArchive(
        kind: widget.args.kind,
        period: widget.args.period,
        from: _from,
        to: _to,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
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
    switch (widget.args.kind) {
      case WerkaArchiveKind.received:
        return l10n.archiveReceivedTitle;
      case WerkaArchiveKind.sent:
        return l10n.archiveSentTitle;
      case WerkaArchiveKind.returned:
        return l10n.archiveReturnedTitle;
    }
  }

  String _periodTitle(AppLocalizations l10n) {
    switch (widget.args.period) {
      case WerkaArchivePeriod.daily:
        return l10n.archiveDailyTitle;
      case WerkaArchivePeriod.monthly:
        return l10n.archiveMonthlyTitle;
      case WerkaArchivePeriod.yearly:
        return l10n.archiveYearlyTitle;
      case WerkaArchivePeriod.custom:
        return l10n.archiveCustomRangeTitle;
    }
  }

  String _subtitle(BuildContext context) {
    final from = _from;
    final to = _to;
    if (from == null || to == null) {
      return '';
    }
    final localizations =
        Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
    if (localizations == null) {
      return '';
    }
    return '${localizations.formatMediumDate(from)} - ${localizations.formatMediumDate(to)}';
  }

  String _metricLabel(DispatchRecord item) {
    switch (widget.args.kind) {
      case WerkaArchiveKind.received:
        final qty = item.acceptedQty > 0 ? item.acceptedQty : item.sentQty;
        return '${_formatQty(qty)} ${item.uom}';
      case WerkaArchiveKind.returned:
        final qty = (item.sentQty - item.acceptedQty)
            .clamp(0, double.infinity)
            .toDouble();
        return '${_formatQty(qty)} ${item.uom}';
      case WerkaArchiveKind.sent:
        return '${_formatQty(item.sentQty)} ${item.uom}';
    }
  }

  String _statusLabel(AppLocalizations l10n, DispatchStatus status) {
    switch (status) {
      case DispatchStatus.pending:
        return l10n.pendingStatus;
      case DispatchStatus.accepted:
        return l10n.confirmedStatus;
      case DispatchStatus.partial:
      case DispatchStatus.rejected:
      case DispatchStatus.cancelled:
        return l10n.returnedStatus;
      case DispatchStatus.draft:
        return l10n.draft;
    }
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Future<void> _downloadPdf() async {
    if (_downloading) {
      return;
    }
    setState(() => _downloading = true);
    try {
      final file = await MobileApi.instance.downloadWerkaArchivePdf(
        kind: widget.args.kind,
        period: widget.args.period,
        from: _from,
        to: _to,
      );
      final savedAt = await saveArchivePdfFile(
        bytes: file.bytes,
        filename: file.filename,
      );
      if (!mounted) {
        return;
      }
      final message = savedAt == file.filename
          ? context.l10n.archivePdfDownloadStartedWeb
          : context.l10n.archivePdfSavedAt(savedAt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.archivePdfFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_kindTitle(context.l10n)} • ${_periodTitle(context.l10n)}';
    useNativeNavigationTitle(context, title);
    return AppShell(
      title: title,
      subtitle: _subtitle(context),
      actions: [
        IconButton.filledTonal(
          onPressed: (_data?.items.isNotEmpty ?? false) && !_downloading
              ? _downloadPdf
              : null,
          icon: Icon(
            _downloading ? Icons.hourglass_top_rounded : Icons.download_rounded,
          ),
          tooltip: context.l10n.archiveDownloadPdfAction,
        ),
      ],
      leading: NativeBackButtonSlot(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showDailyFilter = widget.args.period == WerkaArchivePeriod.daily;
    if (_loading && _data == null) {
      return const Center(child: AppLoadingIndicator());
    }
    if (_error != null && _data == null) {
      return AppRetryState(onRetry: _load);
    }

    final data = _data;
    if (data == null || data.items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          if (showDailyFilter) ...[
            _ArchiveFilterCard(
              title: context.l10n.archiveDateTitle,
              value: _selectedDateLabel(context),
              actionLabel: context.l10n.archiveSelectDateAction,
              onTap: _toggleDailyCalendar,
            ),
            if (_showDateCalendar) ...[
              const SizedBox(height: 10),
              _DailyCalendarCard(
                initialDate: _from ?? DateUtils.dateOnly(DateTime.now()),
                onChanged: _setDailyDate,
              ),
            ],
            const SizedBox(height: 14),
          ],
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                context.l10n.archiveNoItems,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          if (showDailyFilter) ...[
            _ArchiveFilterCard(
              title: context.l10n.archiveDateTitle,
              value: _selectedDateLabel(context),
              actionLabel: context.l10n.archiveSelectDateAction,
              onTap: _toggleDailyCalendar,
            ),
            if (_showDateCalendar) ...[
              const SizedBox(height: 10),
              _DailyCalendarCard(
                initialDate: _from ?? DateUtils.dateOnly(DateTime.now()),
                onChanged: _setDailyDate,
              ),
            ],
            const SizedBox(height: 14),
          ],
          Card.filled(
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
                  Text(
                    context.l10n.archiveRecordCountLabel(
                      data.summary.recordCount,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (data.summary.totalsByUOM.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final total in data.summary.totalsByUOM)
                          Chip(
                            label: Text(
                              context.l10n.archiveTotalByUomLabel(
                                total.uom,
                                total.qty,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                for (int index = 0; index < data.items.length; index++) ...[
                  _ArchiveRow(
                    title: data.items[index].supplierName,
                    subtitle:
                        '${data.items[index].itemCode} • ${data.items[index].itemName}',
                    metric: _metricLabel(data.items[index]),
                    status:
                        _statusLabel(context.l10n, data.items[index].status),
                    createdLabel: data.items[index].createdLabel,
                    isLast: index == data.items.length - 1,
                  ),
                  if (index != data.items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 18,
                      endIndent: 18,
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.55),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _selectedDateLabel(BuildContext context) {
    final value = _from;
    if (value == null) {
      return context.l10n.archiveSelectDateAction;
    }
    final localizations =
        Localizations.of<MaterialLocalizations>(context, MaterialLocalizations);
    if (localizations == null) {
      return context.l10n.archiveSelectDateAction;
    }
    return localizations.formatMediumDate(value);
  }

  void _toggleDailyCalendar() {
    setState(() {
      _showDateCalendar = !_showDateCalendar;
    });
  }

  Future<void> _setDailyDate(DateTime picked) async {
    final selected = DateUtils.dateOnly(picked);
    setState(() {
      _from = selected;
      _to = selected;
      _showDateCalendar = false;
    });
    await _load();
  }
  DateTime _lastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
  }
}

class _ArchiveFilterCard extends StatelessWidget {
  const _ArchiveFilterCard({
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String value;
  final String actionLabel;
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
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
                  const SizedBox(height: 6),
                  Text(value, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyCalendarCard extends StatelessWidget {
  const _DailyCalendarCard({
    required this.initialDate,
    required this.onChanged,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: CalendarDatePicker(
          initialDate: initialDate,
          firstDate: DateTime(DateTime.now().year - 5),
          lastDate: DateTime(DateTime.now().year + 1, 12, 31),
          onDateChanged: onChanged,
        ),
      ),
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.status,
    required this.createdLabel,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final String metric;
  final String status;
  final String createdLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(metric, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                createdLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
