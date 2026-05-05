import '../../../app/app_router.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'supplier_confirm_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierQtyArgs {
  const SupplierQtyArgs({
    required this.item,
    this.initialQty,
  });

  final SupplierItem item;
  final double? initialQty;
}

class SupplierQtyScreen extends StatefulWidget {
  const SupplierQtyScreen({
    super.key,
    required this.item,
    this.initialQty,
  });

  final SupplierItem item;
  final double? initialQty;

  @override
  State<SupplierQtyScreen> createState() => _SupplierQtyScreenState();
}

class _SupplierQtyScreenState extends State<SupplierQtyScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQty != null && widget.initialQty! > 0) {
      controller.text = widget.initialQty!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: 'Miqdor',
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      bottom: const SupplierDock(activeTab: null, centerActive: true),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlignVertical: TextAlignVertical.center,
                    style: textTheme.headlineMedium,
                    decoration: InputDecoration(
                      suffixText: widget.item.uom,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final double qty =
                            double.tryParse(controller.text.trim()) ?? 0;
                        if (qty <= 0) {
                          return;
                        }
                        Navigator.of(context).pushNamed(
                          AppRoutes.supplierConfirm,
                          arguments:
                              SupplierConfirmArgs(item: widget.item, qty: qty),
                        );
                      },
                      child: const Text('Davom etish'),
                    ),
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
