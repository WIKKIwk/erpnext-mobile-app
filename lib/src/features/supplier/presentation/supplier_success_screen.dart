import '../../../app/app_router.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/display/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierSuccessScreen extends StatelessWidget {
  const SupplierSuccessScreen({
    super.key,
    required this.record,
  });

  final DispatchRecord record;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Saqlandi',
      subtitle: '',
      bottom: const SupplierDock(activeTab: null, centerActive: true),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 72, color: Color(0xFFFFFFFF)),
                    const SizedBox(height: 16),
                    Text(record.id,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                        '${record.itemCode} • ${record.sentQty.toStringAsFixed(2)} ${record.uom}'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.supplierHome,
                (route) => route.isFirst,
              ),
              child: const Text('Home ga qaytish'),
            ),
          ),
        ],
      ),
    );
  }
}
