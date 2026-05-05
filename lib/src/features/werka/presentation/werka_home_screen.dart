import 'dart:math' as math;

import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/scroll/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
import 'widgets/werka_dock.dart';
import 'widgets/werka_navigation_drawer.dart';
import 'package:flutter/material.dart';

class WerkaHomeScreen extends StatefulWidget {
  const WerkaHomeScreen({super.key});

  @override
  State<WerkaHomeScreen> createState() => _WerkaHomeScreenState();
}

class _WerkaHomeScreenState extends State<WerkaHomeScreen>
    with WidgetsBindingObserver {
  int _refreshVersion = 0;
  final ValueNotifier<double> _bottomDockFadeStrength = ValueNotifier(0);
  double _listStretch = 0.0;
  double _listPull = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WerkaStore.instance.bootstrapHome();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    _bottomDockFadeStrength.dispose();
    super.dispose();
  }

  bool _onDockScrollRelated(Notification notification) {
    ScrollMetrics? metrics;
    if (notification is ScrollMetricsNotification) {
      metrics = notification.metrics;
    } else if (notification is ScrollNotification) {
      metrics = notification.metrics;
    }
    if (metrics == null) {
      return false;
    }
    final next = dockFadeStrengthFromScrollMetrics(metrics);
    if ((next - _bottomDockFadeStrength.value).abs() > 0.008) {
      _bottomDockFadeStrength.value = next;
    }

    if (notification is OverscrollNotification) {
      final isAtBottom = notification.metrics.extentAfter <= 0.0;
      if (isAtBottom &&
          notification.dragDetails != null &&
          notification.overscroll > 0) {
        _listPull = (_listPull + notification.overscroll).clamp(0.0, 280.0);
        final easedPull = 1.0 - math.exp(-_listPull / 110.0);
        final nextStretch = (easedPull * 0.075).clamp(0.0, 0.075).toDouble();
        if (nextStretch != _listStretch) {
          setState(() => _listStretch = nextStretch);
        }
      }
    }

    if (notification is ScrollEndNotification) {
      if (_listStretch != 0.0 || _listPull != 0.0) {
        setState(() {
          _listStretch = 0.0;
          _listPull = 0.0;
        });
      }
    }
    return false;
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'werka') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    await WerkaStore.instance.refreshHome();
  }

  void _openDrawerRoute(String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: context.l10n.werkaRoleName,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      drawer: WerkaNavigationDrawer(
        selectedIndex: 0,
        onNavigate: _openDrawerRoute,
      ),
      bottom: const WerkaDock(activeTab: WerkaDockTab.home),
      bottomDockFadeStrength: _bottomDockFadeStrength,
      contentPadding: EdgeInsets.zero,
      child: NotificationListener<Notification>(
        onNotification: _onDockScrollRelated,
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: WerkaStore.instance,
                builder: (context, _) {
                  final store = WerkaStore.instance;
                  if (store.loadingHome && !store.loadedHome) {
                    return const Center(child: AppLoadingIndicator());
                  }
                  if (store.homeError != null && !store.loadedHome) {
                    return AppRefreshIndicator(
                      onRefresh: _reload,
                      allowRefreshOnShortContent: true,
                      child: ListView(
                        physics: const TopRefreshScrollPhysics(),
                        children: [
                          AppRetryState(onRetry: _reload),
                        ],
                      ),
                    );
                  }
                  final currentSummary = store.summary;
                  final pendingItems = store.pendingItems;

                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    allowRefreshOnShortContent: true,
                    child: ListView(
                      physics: const TopRefreshScrollPhysics(),
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 1.0,
                            end: 1.0 + _listStretch,
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
                          child: Column(
                            children: [
                              const SizedBox(height: 4),
                              _WerkaSummaryList(summary: currentSummary),
                              if (pendingItems.isNotEmpty)
                                const SizedBox(height: 16),
                              if (pendingItems.isNotEmpty)
                                _WerkaPendingSection(items: pendingItems),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WerkaSummaryList extends StatelessWidget {
  const _WerkaSummaryList({
    required this.summary,
  });

  final WerkaHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return SmoothAppear(
      child: M3SegmentSpacedColumn(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _WerkaSummarySegmentCard(
            slot: M3SegmentVerticalSlot.top,
            cornerRadius: M3SegmentedListGeometry.cornerLarge,
            label: context.l10n.pendingStatus,
            value: summary.pendingCount.toString(),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaStatusBreakdown,
              arguments: WerkaStatusKind.pending,
            ),
          ),
          _WerkaSummarySegmentCard(
            slot: M3SegmentVerticalSlot.middle,
            cornerRadius: M3SegmentedListGeometry.cornerMiddle,
            label: context.l10n.confirmedStatus,
            value: summary.confirmedCount.toString(),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaStatusBreakdown,
              arguments: WerkaStatusKind.confirmed,
            ),
          ),
          _WerkaSummarySegmentCard(
            slot: M3SegmentVerticalSlot.bottom,
            cornerRadius: M3SegmentedListGeometry.cornerLarge,
            label: context.l10n.returnedStatus,
            value: summary.returnedCount.toString(),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaStatusBreakdown,
              arguments: WerkaStatusKind.returned,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bitta **to‘ldirilgan** list elementi — segmentlar bir-biriga ulanmaydi (faqat gap).
class _WerkaSummarySegmentCard extends StatelessWidget {
  const _WerkaSummarySegmentCard({
    required this.slot,
    required this.cornerRadius,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final double cornerRadius;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final BorderRadius radius =
        M3SegmentedListGeometry.borderRadius(slot, cornerRadius);
    final Color bg = switch (theme.brightness) {
      Brightness.dark => scheme.surfaceContainerLow,
      Brightness.light => scheme.surfaceContainerHighest,
    };
    final Color foreground = scheme.onSurface;
    final Color accent = scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WerkaPendingSection extends StatefulWidget {
  const _WerkaPendingSection({
    required this.items,
  });

  final List<DispatchRecord> items;

  @override
  State<_WerkaPendingSection> createState() => _WerkaPendingSectionState();
}

class _WerkaPendingSectionState extends State<_WerkaPendingSection> {
  /// Yopiq holatda pastdagi kartalar **build** qilinmaydi.
  late bool _itemsExpanded;

  @override
  void initState() {
    super.initState();
    _itemsExpanded = WerkaStore.instance.homePendingListExpanded;
  }

  void _toggleExpanded() {
    setState(() => _itemsExpanded = !_itemsExpanded);
    WerkaStore.instance.setHomePendingListExpanded(_itemsExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final n = widget.items.length;

    return SmoothAppear(
      delay: const Duration(milliseconds: 90),
      offset: const Offset(0, 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            M3SegmentFilledSurface(
              slot: M3SegmentVerticalSlot.top,
              cornerRadius: M3SegmentedListGeometry.cornerRadiusForSlot(
                M3SegmentVerticalSlot.top,
              ),
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.inProgressItemsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Icon(
                      _itemsExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 28,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.smooth,
              alignment: Alignment.topCenter,
              child: _itemsExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: M3SegmentedListGeometry.gap),
                        for (int index = 0; index < n; index++) ...[
                          if (index > 0)
                            const SizedBox(
                              height: M3SegmentedListGeometry.gap,
                            ),
                          _WerkaPendingItemTile(
                            record: widget.items[index],
                            index: index,
                            itemCount: n,
                          ),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WerkaPendingItemTile extends StatelessWidget {
  const _WerkaPendingItemTile({
    required this.record,
    required this.index,
    required this.itemCount,
  });

  final DispatchRecord record;
  final int index;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slot = M3SegmentedListGeometry.bodySlotForIndex(index, itemCount);
    final r = M3SegmentedListGeometry.cornerRadiusForSlot(slot);

    void navigate() => Navigator.of(context).pushNamed(
          record.isDeliveryNote
              ? AppRoutes.werkaCustomerDeliveryDetail
              : AppRoutes.werkaDetail,
          arguments: record,
        );

    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: r,
      onTap: navigate,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.supplierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.createdLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
