import '../../../core/api/mobile_api.dart';
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
            padding: const EdgeInsets.only(bottom: 10),
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
                        'Dispatch Volume',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'So‘nggi jo‘natishlar bo‘yicha hajm ko‘rinishi.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      _VolumeChart(records: history),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SmoothAppear(
                delay: const Duration(milliseconds: 180),
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
                      const Divider(height: 1, color: Color(0xFF1F1F1F)),
                      ...history.asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        return SmoothAppear(
                          delay: Duration(milliseconds: 220 + (index * 45)),
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
                                const Divider(
                                    height: 1, color: Color(0xFF1F1F1F)),
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
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1.35),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF080808),
            Color(0xFF121212),
            Color(0xFF0A0A0A),
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
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF242424)),
                ),
                child: Text(
                  'Operations Overview',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
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
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF212121)),
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
          accent: const Color(0xFF1F8B4C),
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
        color: const Color(0xFF080808),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF252525), width: 1.2),
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

class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.records});

  final List<DispatchRecord> records;

  @override
  Widget build(BuildContext context) {
    final chartItems = records.take(6).toList().reversed.toList();
    return SizedBox(
      height: 190,
      child: chartItems.isEmpty
          ? Center(
              child: Text(
                'Chart uchun data yo‘q',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          : CustomPaint(
              painter: _VolumeChartPainter(
                values: chartItems.map((item) => item.sentQty).toList(),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: chartItems.map((item) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          (item.itemName.isEmpty
                                  ? item.itemCode
                                  : item.itemName)
                              .split(' ')
                              .first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}

class _VolumeChartPainter extends CustomPainter {
  _VolumeChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1C1C1C)
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF7A4A26),
          Color(0xFFB1733B),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    const chartTop = 10.0;
    const chartBottom = 36.0;
    final chartHeight = size.height - chartBottom - chartTop;
    final maxValue =
        values.fold<double>(0, (best, value) => value > best ? value : best);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    for (int i = 0; i < 4; i++) {
      final y = chartTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final segmentWidth = size.width / values.length;
    for (int index = 0; index < values.length; index++) {
      final value = values[index];
      final barHeight = (value / safeMax) * (chartHeight - 18);
      final left = segmentWidth * index + (segmentWidth * 0.34);
      final width = segmentWidth * 0.32;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          chartTop + chartHeight - barHeight,
          width,
          barHeight,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VolumeChartPainter oldDelegate) {
    return oldDelegate.values != values;
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
            color: value == 0 ? const Color(0xFF101010) : color,
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
            segment(const Color(0xFF1F8B4C), accepted),
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
                color: const Color(0xFF1F8B4C),
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
