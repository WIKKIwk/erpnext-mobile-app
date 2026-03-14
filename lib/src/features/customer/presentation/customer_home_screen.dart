import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/customer_dock.dart';
import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late Future<_CustomerHomePayload> _future;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  Future<_CustomerHomePayload> _load() async {
    final summary = await MobileApi.instance.customerSummary();
    final history = await MobileApi.instance.customerHistory();
    return _CustomerHomePayload(
      summary: summary,
      previewItems: history.take(3).toList(),
    );
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => _future = future);
    await future;
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

  void _openStatus(CustomerStatusKind kind) {
    Navigator.of(context).pushNamed(
      AppRoutes.customerStatusDetail,
      arguments: kind,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Customer',
      subtitle: '',
      bottom: const CustomerDock(activeTab: CustomerDockTab.home),
      child: FutureBuilder<_CustomerHomePayload>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return Center(
              child: _QuietPanel(
                child: Text('${snapshot.error}'),
              ),
            );
          }

          final payload = snapshot.data!;
          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: _CustomerStatusPanel(
                    summary: payload.summary,
                    onOpenStatus: _openStatus,
                  ),
                ),
                const SizedBox(height: 18),
                SmoothAppear(
                  delay: const Duration(milliseconds: 60),
                  child: _CustomerShipmentsPanel(
                    items: payload.previewItems,
                    onTapRecord: _openDetail,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CustomerHomePayload {
  const _CustomerHomePayload({
    required this.summary,
    required this.previewItems,
  });

  final CustomerHomeSummary summary;
  final List<DispatchRecord> previewItems;
}

class _QuietPanel extends StatelessWidget {
  const _QuietPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerLow : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.16 : 0.08),
            blurRadius: isDark ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: child,
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
          _CustomerStatusRow(
            label: 'Pending',
            value: summary.pendingCount.toString(),
            highlighted: true,
            onTap: () => onOpenStatus(CustomerStatusKind.pending),
            isFirst: true,
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 18,
            endIndent: 18,
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          _CustomerStatusRow(
            label: 'Confirmed',
            value: summary.confirmedCount.toString(),
            onTap: () => onOpenStatus(CustomerStatusKind.confirmed),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 18,
            endIndent: 18,
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          _CustomerStatusRow(
            label: 'Rejected',
            value: summary.rejectedCount.toString(),
            onTap: () => onOpenStatus(CustomerStatusKind.rejected),
            isLast: true,
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

    return PressableScale(
      borderRadius: 26,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 26 : 0),
            topRight: Radius.circular(isFirst ? 26 : 0),
            bottomLeft: Radius.circular(isLast ? 26 : 0),
            bottomRight: Radius.circular(isLast ? 26 : 0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (highlighted) ...[
                    Container(
                      width: 3,
                      height: 22,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: highlighted ? scheme.onSurface : null,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 42),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: highlighted
                    ? scheme.secondaryContainer
                    : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: highlighted
                      ? scheme.onSecondaryContainer
                      : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: scheme.onSurfaceVariant,
            ),
          ],
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

    return _QuietPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent shipments', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const _CustomerEmptyState()
          else
            Column(
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  _CustomerPreviewRow(
                    record: items[index],
                    isFirst: index == 0,
                    isLast: index == items.length - 1,
                    onTap: () => onTapRecord(items[index].id),
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
        'No shipments',
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

    return PressableScale(
      borderRadius: 22,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 22 : 0),
            topRight: Radius.circular(isFirst ? 22 : 0),
            bottomLeft: Radius.circular(isLast ? 22 : 0),
            bottomRight: Radius.circular(isLast ? 22 : 0),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
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
            const SizedBox(width: 12),
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
    );
  }
}
