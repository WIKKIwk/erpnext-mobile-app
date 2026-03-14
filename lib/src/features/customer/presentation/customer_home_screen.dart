import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
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
      subtitle: 'Delivery confirmations and shipment overview',
      bottom: const CustomerDock(activeTab: CustomerDockTab.home),
      child: FutureBuilder<_CustomerHomePayload>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('${snapshot.error}'),
              ),
            );
          }

          final payload = snapshot.data!;
          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
              children: [
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: _CustomerHeroCard(
                    summary: payload.summary,
                    onOpenPending: () =>
                        _openStatus(CustomerStatusKind.pending),
                  ),
                ),
                const SizedBox(height: 18),
                SmoothAppear(
                  delay: const Duration(milliseconds: 60),
                  child: _CustomerStatusSection(
                    summary: payload.summary,
                    onOpenStatus: _openStatus,
                  ),
                ),
                const SizedBox(height: 18),
                SmoothAppear(
                  delay: const Duration(milliseconds: 90),
                  child: _CustomerPendingPreviewCard(
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

class _CustomerHeroCard extends StatelessWidget {
  const _CustomerHeroCard({
    required this.summary,
    required this.onOpenPending,
  });

  final CustomerHomeSummary summary;
  final VoidCallback onOpenPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            scheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live overview',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color:
                            scheme.onPrimaryContainer.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Awaiting your review',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                summary.pendingCount.toString(),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 68,
                  letterSpacing: -2.4,
                  color: scheme.onPrimaryContainer,
                  height: 0.92,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'pending\nshipments',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Confirm or reject delivery notes sent to your company. The list refreshes with live status updates.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CustomerMetricChip(
                icon: Icons.task_alt_rounded,
                label: 'Confirmed',
                value: summary.confirmedCount.toString(),
              ),
              _CustomerMetricChip(
                icon: Icons.cancel_outlined,
                label: 'Rejected',
                value: summary.rejectedCount.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: onOpenPending,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Open pending list'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.surface.withValues(alpha: 0.72),
              foregroundColor: scheme.onSurface,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerMetricChip extends StatelessWidget {
  const _CustomerMetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerStatusSection extends StatelessWidget {
  const _CustomerStatusSection({
    required this.summary,
    required this.onOpenStatus,
  });

  final CustomerHomeSummary summary;
  final ValueChanged<CustomerStatusKind> onOpenStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            label: 'Status breakdown',
            caption: 'Track every delivery response by current state',
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
              ),
              child: Column(
                children: [
                  _CustomerSummaryRow(
                    label: 'Pending',
                    subtitle: 'Needs your decision',
                    value: summary.pendingCount.toString(),
                    icon: Icons.schedule_rounded,
                    accent: const Color(0xFFB68A17),
                    onTap: () => onOpenStatus(CustomerStatusKind.pending),
                    isFirst: true,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
                  ),
                  _CustomerSummaryRow(
                    label: 'Confirmed',
                    subtitle: 'Accepted by customer',
                    value: summary.confirmedCount.toString(),
                    icon: Icons.task_alt_rounded,
                    accent: const Color(0xFF3D7D54),
                    onTap: () => onOpenStatus(CustomerStatusKind.confirmed),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: scheme.outlineVariant,
                  ),
                  _CustomerSummaryRow(
                    label: 'Rejected',
                    subtitle: 'Returned with a reason',
                    value: summary.rejectedCount.toString(),
                    icon: Icons.highlight_off_rounded,
                    accent: const Color(0xFFB34F46),
                    onTap: () => onOpenStatus(CustomerStatusKind.rejected),
                    isLast: true,
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

class _CustomerSummaryRow extends StatelessWidget {
  const _CustomerSummaryRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PressableScale(
      borderRadius: 24,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 24 : 0),
            topRight: Radius.circular(isFirst ? 24 : 0),
            bottomLeft: Radius.circular(isLast ? 24 : 0),
            bottomRight: Radius.circular(isLast ? 24 : 0),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPendingPreviewCard extends StatelessWidget {
  const _CustomerPendingPreviewCard({
    required this.items,
    required this.onTapRecord,
  });

  final List<DispatchRecord> items;
  final ValueChanged<String> onTapRecord;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            label: 'Recent shipments',
            caption: 'Open the latest delivery notes sent to your team',
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              color: scheme.surfaceContainer,
              child: items.isEmpty
                  ? const _CustomerEmptyState()
                  : Column(
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
                              color: scheme.outlineVariant,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.caption,
  });

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          caption,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _CustomerEmptyState extends StatelessWidget {
  const _CustomerEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No pending shipments yet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'New delivery notes will appear here as soon as they are created.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
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
      borderRadius: 24,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 24 : 0),
            topRight: Radius.circular(isFirst ? 24 : 0),
            bottomLeft: Radius.circular(isLast ? 24 : 0),
            bottomRight: Radius.circular(isLast ? 24 : 0),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.local_shipping_outlined,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.itemCode,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.scale_outlined,
                        label:
                            '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                      ),
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: record.createdLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusPill(status: record.status),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
