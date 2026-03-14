import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/customer_dock.dart';
import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/refresh_hub.dart';

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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: SoftCard(child: Text('${snapshot.error}')));
          }
          final payload = snapshot.data!;
          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _CustomerSummaryCard(summary: payload.summary),
                const SizedBox(height: 16),
                _CustomerPendingPreviewCard(
                  items: payload.previewItems,
                  onTapRecord: _openDetail,
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

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({
    required this.summary,
  });

  final CustomerHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      backgroundColor: const Color(0xFF161616),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      borderWidth: 1.35,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CustomerSectionLabel(label: 'Holatlar'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFF000000),
                child: Column(
                  children: [
                    _CustomerSummaryRow(
                      label: 'Kutilmoqda',
                      value: summary.pendingCount.toString(),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.customerStatusDetail,
                        arguments: CustomerStatusKind.pending,
                      ),
                      isFirst: true,
                    ),
                    const Divider(height: 1, thickness: 1),
                    _CustomerSummaryRow(
                      label: 'Tasdiqlangan',
                      value: summary.confirmedCount.toString(),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.customerStatusDetail,
                        arguments: CustomerStatusKind.confirmed,
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    _CustomerSummaryRow(
                      label: 'Rad etilgan',
                      value: summary.rejectedCount.toString(),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.customerStatusDetail,
                        arguments: CustomerStatusKind.rejected,
                      ),
                      isLast: true,
                    ),
                  ],
                ),
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
    required this.value,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 16 : 0),
            topRight: Radius.circular(isFirst ? 16 : 0),
            bottomLeft: Radius.circular(isLast ? 20 : 0),
            bottomRight: Radius.circular(isLast ? 20 : 0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 34,
                  ),
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
    return SoftCard(
      backgroundColor: const Color(0xFF161616),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      borderWidth: 1.35,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CustomerSectionLabel(label: 'Kutilayotgan jo‘natmalar'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFF000000),
                child: items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Hozircha kutilayotgan jo‘natmalar yo‘q.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : Column(
                        children: [
                          for (int index = 0;
                              index < items.length;
                              index++) ...[
                            _CustomerPreviewRow(
                              record: items[index],
                              isFirst: index == 0,
                              isLast: index == items.length - 1,
                              onTap: () => onTapRecord(items[index].id),
                            ),
                            if (index != items.length - 1)
                              const Divider(height: 1, thickness: 1),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSectionLabel extends StatelessWidget {
  const _CustomerSectionLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
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
    return PressableScale(
      borderRadius: 20,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 16 : 0),
            topRight: Radius.circular(isFirst ? 16 : 0),
            bottomLeft: Radius.circular(isLast ? 20 : 0),
            bottomRight: Radius.circular(isLast ? 20 : 0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.itemName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.itemCode,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  record.createdLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
