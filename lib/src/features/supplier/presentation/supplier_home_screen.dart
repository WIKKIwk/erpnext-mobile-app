import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatelessWidget {
  const SupplierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Supplier',
      subtitle: 'Jo‘natish va statuslarni shu yerdan boshqarasiz.',
      bottom: const SupplierDock(activeTab: SupplierDockTab.home),
      child: FutureBuilder<List<DispatchRecord>>(
        future: MobileApi.instance.supplierHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Text('Supplier history yuklanmadi: ${snapshot.error}'),
              ),
            );
          }

          final history = snapshot.data ?? <DispatchRecord>[];
          final pendingCount = history
              .where((item) => item.status == DispatchStatus.pending)
              .length;
          final acceptedCount = history
              .where((item) => item.status == DispatchStatus.accepted)
              .length;
          final partialCount = history
              .where((item) => item.status == DispatchStatus.partial)
              .length;
          final rejectedCount = history
              .where((item) => item.status == DispatchStatus.rejected)
              .length;
          final totalQty =
              history.fold<double>(0, (sum, item) => sum + item.sentQty);
          final uniqueItems = history
              .map((item) =>
                  item.itemCode.trim().isEmpty ? item.itemName : item.itemCode)
              .toSet()
              .length;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              SmoothAppear(
                child: _EnterpriseHero(
                  pendingCount: pendingCount,
                  acceptedCount: acceptedCount,
                  totalQty: totalQty,
                  uniqueItems: uniqueItems,
                ),
              ),
              const SizedBox(height: 18),
              SmoothAppear(
                delay: const Duration(milliseconds: 80),
                child: _MetricGrid(
                  pendingCount: pendingCount,
                  acceptedCount: acceptedCount,
                  partialCount: partialCount,
                  uniqueItems: uniqueItems,
                ),
              ),
              const SizedBox(height: 18),
              SmoothAppear(
                delay: const Duration(milliseconds: 130),
                child: SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status Mix',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jarayonlarning real taqsimoti.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      _StatusMixBar(
                        pending: pendingCount,
                        accepted: acceptedCount,
                        partial: partialCount,
                        rejected: rejectedCount,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const SoftCard(
                  child: Text('Hali jo‘natishlar yo‘q.'),
                )
              else
                SoftCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Mahsulot',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Miqdor',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Holat',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppTheme.dockDivider(context)),
                      ...history.asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        return SmoothAppear(
                          delay: Duration(milliseconds: 180 + (index * 45)),
                          offset: const Offset(0, 16),
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            record.itemName.isEmpty
                                                ? record.itemCode
                                                : record.itemName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            record.createdLabel,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child:
                                            StatusPill(status: record.status),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (index != history.length - 1)
                                Divider(height: 1, color: AppTheme.dockDivider(context)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EnterpriseHero extends StatelessWidget {
  const _EnterpriseHero({
    required this.pendingCount,
    required this.acceptedCount,
    required this.totalQty,
    required this.uniqueItems,
  });

  final int pendingCount;
  final int acceptedCount;
  final double totalQty;
  final int uniqueItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.cardBorder(context), width: 1.35),
        gradient: LinearGradient(
          colors: [
            AppTheme.isDark(context)
                ? const Color(0xFF080808)
                : const Color(0xFFFFFFFF),
            AppTheme.isDark(context)
                ? const Color(0xFF121212)
                : const Color(0xFFFFFFFF),
            AppTheme.isDark(context)
                ? const Color(0xFF0A0A0A)
                : const Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.actionSurface(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.cardBorder(context)),
                ),
                child: Text(
                  'Operations Overview',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                'Live',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            totalQty.toStringAsFixed(0),
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontSize: 40),
          ),
          const SizedBox(height: 6),
          Text(
            'Jami jo‘natilgan birlik',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Jarayonda',
                  value: pendingCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'Yopilgan',
                  value: acceptedCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'SKU',
                  value: uniqueItems.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.actionSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.pendingCount,
    required this.acceptedCount,
    required this.partialCount,
    required this.uniqueItems,
  });

  final int pendingCount;
  final int acceptedCount;
  final int partialCount;
  final int uniqueItems;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _EnterpriseMetricTile(
          label: 'Pending Queue',
          value: pendingCount.toString(),
          accent: const Color(0xFFFFD54F),
        ),
        _EnterpriseMetricTile(
          label: 'Accepted',
          value: acceptedCount.toString(),
          accent: const Color(0xFF5BB450),
        ),
        _EnterpriseMetricTile(
          label: 'Partial',
          value: partialCount.toString(),
          accent: const Color(0xFF2A6FDB),
        ),
        _EnterpriseMetricTile(
          label: 'Unique Items',
          value: uniqueItems.toString(),
          accent: const Color(0xFFA78BFA),
        ),
      ],
    );
  }
}

class _EnterpriseMetricTile extends StatelessWidget {
  const _EnterpriseMetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            width: 42,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _StatusMixBar extends StatelessWidget {
  const _StatusMixBar({
    required this.pending,
    required this.accepted,
    required this.partial,
    required this.rejected,
  });

  final int pending;
  final int accepted;
  final int partial;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final total = pending + accepted + partial + rejected;
    final safeTotal = total == 0 ? 1 : total;

    Widget segment(Color color, int value) {
      return Expanded(
        flex: value == 0 ? 1 : value,
        child: Container(
          height: 16,
          decoration: BoxDecoration(
            color: value == 0
                ? (AppTheme.isDark(context)
                    ? const Color(0xFF101010)
                    : const Color(0xFFE9E7E0))
                : color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            segment(const Color(0xFFFFD54F), pending),
            const SizedBox(width: 6),
            segment(const Color(0xFF5BB450), accepted),
            const SizedBox(width: 6),
            segment(const Color(0xFF2A6FDB), partial),
            const SizedBox(width: 6),
            segment(const Color(0xFFC53B30), rejected),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MixLegend(
                label: 'Pending',
                value: '$pending / $safeTotal',
                color: const Color(0xFFFFD54F),
              ),
            ),
            Expanded(
              child: _MixLegend(
                label: 'Accepted',
                value: '$accepted / $safeTotal',
                color: const Color(0xFF5BB450),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MixLegend(
                label: 'Partial',
                value: '$partial / $safeTotal',
                color: const Color(0xFF2A6FDB),
              ),
            ),
            Expanded(
              child: _MixLegend(
                label: 'Rejected',
                value: '$rejected / $safeTotal',
                color: const Color(0xFFC53B30),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MixLegend extends StatelessWidget {
  const _MixLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
