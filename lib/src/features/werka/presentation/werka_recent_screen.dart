import 'dart:math' as math;

import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
import 'werka_customer_issue_customer_screen.dart';
import 'werka_unannounced_supplier_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaRecentScreen extends StatefulWidget {
  const WerkaRecentScreen({
    super.key,
    this.loader,
  });

  final Future<List<DispatchRecord>> Function()? loader;

  @override
  State<WerkaRecentScreen> createState() => _WerkaRecentScreenState();
}

class _WerkaRecentScreenState extends State<WerkaRecentScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  double _cardStretch = 0.0;
  double _cardPull = 0.0;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    if (widget.loader == null) {
      WidgetsBinding.instance.addObserver(this);
      WerkaStore.instance.bootstrapHistory();
      RefreshHub.instance.addListener(_handlePushRefresh);
    }
  }

  @override
  void dispose() {
    if (widget.loader == null) {
      WidgetsBinding.instance.removeObserver(this);
      RefreshHub.instance.removeListener(_handlePushRefresh);
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.loader != null) {
      return;
    }
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  void _handlePushRefresh() {
    if (widget.loader != null || !mounted || RefreshHub.instance.topic != 'werka') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  Future<void> _reload() async {
    if (widget.loader != null) {
      return;
    }
    _settleTopEdge();
    await WerkaStore.instance.refreshHistory();
    _settleTopEdge();
  }

  void _settleTopEdge() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.minScrollExtent;
      if ((position.pixels - target).abs() <= 0.5) {
        return;
      }
      _scrollController.jumpTo(target);
    });
  }

  bool _usesCustomerFlow(DispatchRecord record) {
    return record.eventType.startsWith('customer_delivery_');
  }

  Future<void> _repeat(DispatchRecord record) async {
    if (_usesCustomerFlow(record)) {
      await Navigator.of(context).pushNamed(
        AppRoutes.werkaCustomerIssueCustomer,
        arguments: WerkaCustomerIssuePrefillArgs(
          customerRef: record.supplierRef,
          customerName: record.supplierName,
          itemCode: record.itemCode,
          itemName: record.itemName,
          qty: record.sentQty,
          uom: record.uom,
        ),
      );
      return;
    }
    await Navigator.of(context).pushNamed(
      AppRoutes.werkaUnannouncedSupplier,
      arguments: WerkaUnannouncedPrefillArgs(
        supplierRef: record.supplierRef,
        supplierName: record.supplierName,
        itemCode: record.itemCode,
        itemName: record.itemName,
        qty: record.sentQty,
        uom: record.uom,
      ),
    );
  }

  String _headline(DispatchRecord record) {
    return record.itemCode.trim().isEmpty ? record.itemName : record.itemCode;
  }

  String _subline(DispatchRecord record) {
    return '${record.supplierName} • ${record.itemName}';
  }

  String _metric(BuildContext context, DispatchRecord record) {
    final l10n = context.l10n;
    if (_usesCustomerFlow(record)) {
      return l10n.customerFlowMetric(record.sentQty, record.uom);
    }
    return l10n.supplierFlowMetric(record.sentQty, record.uom);
  }

  String _actionLabel(BuildContext context, DispatchRecord record) {
    final l10n = context.l10n;
    return _usesCustomerFlow(record)
        ? l10n.repeatSendAgain
        : l10n.repeatCreateAgain;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      final isAtBottom = notification.metrics.extentAfter <= 0.0;
      if (isAtBottom &&
          notification.dragDetails != null &&
          notification.overscroll > 0) {
        _cardPull = (_cardPull + notification.overscroll).clamp(0.0, 280.0);
        final easedPull = 1.0 - math.exp(-_cardPull / 110.0);
        final nextStretch = (easedPull * 0.075).clamp(0.0, 0.075).toDouble();
        if (nextStretch != _cardStretch) {
          setState(() => _cardStretch = nextStretch);
        }
        return false;
      }
    }

    if (notification is ScrollEndNotification) {
      if (_cardStretch != 0.0 || _cardPull != 0.0) {
        setState(() {
          _cardStretch = 0.0;
          _cardPull = 0.0;
        });
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WerkaStore.instance,
      builder: (context, _) => AppShell(
        title: context.l10n.recentTitle,
        subtitle: context.l10n.recentSubtitle,
        bottom: const WerkaDock(activeTab: WerkaDockTab.recent),
        contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
        child: _buildBody(Theme.of(context)),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final store = WerkaStore.instance;
    final items = widget.loader == null ? store.historyItems : _testItems;
    if (widget.loader == null && store.loadingHistory && !store.loadedHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.loader == null &&
        store.historyError != null &&
        !store.loadedHistory) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _RecentMessageCard(
            title: context.l10n.recentLoadFailed,
            body: context.l10n.recentLoadFailedWith(store.historyError!),
            actionLabel: context.l10n.retry,
            onPressed: _reload,
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _RecentInfoCard(
            title: context.l10n.noRecentActions,
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 110),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 1.0,
              end: 1.0 + _cardStretch,
            ),
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            builder: (context, scaleY, child) {
              return Transform.scale(
                scaleY: scaleY,
                alignment: Alignment.bottomCenter,
                child: child,
              );
            },
            child: _WerkaRecentSection(
              items: items,
              headlineFor: _headline,
              sublineFor: _subline,
              metricFor: (record) => _metric(context, record),
              actionLabelFor: (record) => _actionLabel(context, record),
              onRepeat: _repeat,
            ),
          ),
        ],
      ),
    );
  }

  List<DispatchRecord> get _testItems =>
      _cachedTestItems ?? const <DispatchRecord>[];

  List<DispatchRecord>? _cachedTestItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.loader != null && _cachedTestItems == null) {
      widget.loader!().then((items) {
        if (!mounted) return;
        setState(() {
          _cachedTestItems = items;
        });
      });
    }
  }
}

class _RecentMessageCard extends StatelessWidget {
  const _RecentMessageCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInfoCard extends StatelessWidget {
  const _RecentInfoCard({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(title, style: theme.textTheme.titleMedium),
      ),
    );
  }
}

class _WerkaRecentSection extends StatelessWidget {
  const _WerkaRecentSection({
    required this.items,
    required this.headlineFor,
    required this.sublineFor,
    required this.metricFor,
    required this.actionLabelFor,
    required this.onRepeat,
  });

  final List<DispatchRecord> items;
  final String Function(DispatchRecord record) headlineFor;
  final String Function(DispatchRecord record) sublineFor;
  final String Function(DispatchRecord record) metricFor;
  final String Function(DispatchRecord record) actionLabelFor;
  final Future<void> Function(DispatchRecord record) onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _WerkaRecentRow(
              record: items[index],
              headline: headlineFor(items[index]),
              subline: sublineFor(items[index]),
              metric: metricFor(items[index]),
              actionLabel: actionLabelFor(items[index]),
              onRepeat: () => onRepeat(items[index]),
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 18,
                endIndent: 18,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
              ),
          ],
        ],
      ),
    );
  }
}

class _WerkaRecentRow extends StatelessWidget {
  const _WerkaRecentRow({
    required this.record,
    required this.headline,
    required this.subline,
    required this.metric,
    required this.actionLabel,
    required this.onRepeat,
  });

  final DispatchRecord record;
  final String headline;
  final String subline;
  final String metric;
  final String actionLabel;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onRepeat,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    headline,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: onRepeat,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  record.createdLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (record.highlight.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.highlight,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
