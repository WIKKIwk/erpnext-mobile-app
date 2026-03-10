import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({super.key});

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen> {
  late Future<List<DispatchRecord>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = MobileApi.instance.supplierHistory();
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.supplierHistory();
    setState(() {
      _historyFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Supplier',
      subtitle: 'Faqat asosiy holatlar.',
      bottom: const SupplierDock(activeTab: SupplierDockTab.home),
      child: FutureBuilder<List<DispatchRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return RefreshIndicator.adaptive(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 120),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Home yuklanmadi', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _reload,
                            child: const Text('Qayta urinish'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data ?? <DispatchRecord>[];
          final pendingCount = history
              .where((item) => item.status == DispatchStatus.pending)
              .length;
          final submittedCount = history
              .where((item) => item.status == DispatchStatus.accepted)
              .length;
          final returnedCount = history
              .where((item) =>
                  item.status == DispatchStatus.rejected ||
                  item.status == DispatchStatus.cancelled)
              .length;

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _HomeStatCard(
                  label: 'Jarayonda',
                  value: pendingCount.toString(),
                ),
                const SizedBox(height: 12),
                _HomeStatCard(
                  label: 'Submit',
                  value: submittedCount.toString(),
                ),
                const SizedBox(height: 12),
                _HomeStatCard(
                  label: 'Qaytarilgan',
                  value: returnedCount.toString(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SmoothAppear(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 34,
                    color: AppTheme.isDark(context)
                        ? Colors.white
                        : const Color(0xFF1F1A17),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
