import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/customer_store.dart';
import 'widgets/customer_dock.dart';
import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    this.showShell = true,
  });

  final bool showShell;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    CustomerStore.instance.bootstrap();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _settleTopEdge();
    await CustomerStore.instance.refresh();
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

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'customer') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  Future<void> _openDetail(String deliveryNoteID) async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.customerDetail,
      arguments: deliveryNoteID,
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openStatus(CustomerStatusKind kind) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.customerStatusDetail,
      arguments: kind,
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    final content = AnimatedBuilder(
      animation: CustomerStore.instance,
      builder: (context, _) {
        final store = CustomerStore.instance;
        if (store.loading && !store.loaded) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (store.error != null && !store.loaded) {
          return Center(
            child: _QuietPanel(
              child: Text('${store.error}'),
            ),
          );
        }

        final summary = store.summary;
        final previewItems = store.historyItems.take(3).toList();

        return AppRefreshIndicator(
          onRefresh: _reload,
          allowRefreshOnShortContent: true,
          child: ListView(
            controller: _scrollController,
            physics: const TopRefreshScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
            children: [
              SmoothAppear(
                delay: const Duration(milliseconds: 20),
                child: _CustomerStatusPanel(
                  summary: summary,
                  onOpenStatus: _openStatus,
                ),
              ),
              const SizedBox(height: 18),
              SmoothAppear(
                delay: const Duration(milliseconds: 60),
                child: _CustomerShipmentsPanel(
                  items: previewItems,
                  onTapRecord: _openDetail,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!widget.showShell) {
      return content;
    }

    return AppShell(
      title: context.l10n.customerRoleName,
      subtitle: '',
      animateOnEnter: false,
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const CustomerDock(activeTab: CustomerDockTab.home),
      child: content,
    );
  }
}

class _QuietPanel extends StatelessWidget {
  const _QuietPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: color ??
          (isDark ? const Color(0xFF25242B) : scheme.surfaceContainerLow),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _CustomerStatusPanel extends StatelessWidget {
  const _CustomerStatusPanel({
    required this.summary,
    required this.onOpenStatus,
  });

  final CustomerHomeSummary summary;
  final ValueChanged<CustomerStatusKind> onOpenStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _QuietPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SoftReveal(
            delay: const Duration(milliseconds: 20),
            child: _CustomerStatusRow(
              label: context.l10n.pendingLabel,
              value: summary.pendingCount.toString(),
              highlighted: true,
              onTap: () => onOpenStatus(CustomerStatusKind.pending),
              isFirst: true,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 18,
            endIndent: 18,
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          SoftReveal(
            delay: const Duration(milliseconds: 60),
            child: _CustomerStatusRow(
              label: context.l10n.confirmedStatus,
              value: summary.confirmedCount.toString(),
              onTap: () => onOpenStatus(CustomerStatusKind.confirmed),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 18,
            endIndent: 18,
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          SoftReveal(
            delay: const Duration(milliseconds: 100),
            child: _CustomerStatusRow(
              label: context.l10n.rejectedLabel,
              value: summary.rejectedCount.toString(),
              onTap: () => onOpenStatus(CustomerStatusKind.rejected),
              isLast: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerStatusRow extends StatelessWidget {
  const _CustomerStatusRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.highlighted = false,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlighted;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 28 : 0),
      topRight: Radius.circular(isFirst ? 28 : 0),
      bottomLeft: Radius.circular(isLast ? 28 : 0),
      bottomRight: Radius.circular(isLast ? 28 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.smooth,
          color: highlighted ? scheme.surfaceContainer : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (highlighted) ...[
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(label, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(44, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.medium,
                    switchInCurve: AppMotion.smooth,
                    switchOutCurve: AppMotion.smooth,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      value,
                      key: ValueKey<String>(value),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerShipmentsPanel extends StatelessWidget {
  const _CustomerShipmentsPanel({
    required this.items,
    required this.onTapRecord,
  });

  final List<DispatchRecord> items;
  final ValueChanged<String> onTapRecord;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return _QuietPanel(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      color: isDark ? null : scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.recentShipmentsTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _CustomerEmptyState(),
            )
          else
            Card.filled(
              margin: EdgeInsets.zero,
              color: isDark ? const Color(0xFF2A2931) : scheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  for (int index = 0; index < items.length; index++) ...[
                    SoftReveal(
                      delay: Duration(milliseconds: 20 + (index * 40)),
                      child: _CustomerPreviewRow(
                        record: items[index],
                        isFirst: index == 0,
                        isLast: index == items.length - 1,
                        onTap: () => onTapRecord(items[index].id),
                      ),
                    ),
                    if (index != items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerEmptyState extends StatelessWidget {
  const _CustomerEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Text(
        context.l10n.noShipments,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _CustomerPreviewRow extends StatelessWidget {
  const _CustomerPreviewRow({
    required this.record,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final DispatchRecord record;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 24 : 0),
      topRight: Radius.circular(isFirst ? 24 : 0),
      bottomLeft: Radius.circular(isLast ? 24 : 0),
      bottomRight: Radius.circular(isLast ? 24 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
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
                      record.itemCode,
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
              Text(
                '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
