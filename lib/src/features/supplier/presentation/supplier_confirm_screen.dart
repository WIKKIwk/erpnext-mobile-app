import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierConfirmArgs {
  const SupplierConfirmArgs({
    required this.item,
    required this.qty,
  });

  final SupplierItem item;
  final double qty;
}

class SupplierConfirmScreen extends StatefulWidget {
  const SupplierConfirmScreen({
    super.key,
    required this.args,
    this.submitDispatch,
  });

  final SupplierConfirmArgs args;
  final Future<DispatchRecord> Function(SupplierConfirmArgs args)? submitDispatch;

  @override
  State<SupplierConfirmScreen> createState() => _SupplierConfirmScreenState();
}

class _SupplierConfirmScreenState extends State<SupplierConfirmScreen> {
  bool _submitting = false;

  Future<void> _handleSubmit() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final submitDispatch = widget.submitDispatch ??
          (args) => MobileApi.instance.createDispatch(
                itemCode: args.item.code,
                qty: args.qty,
              );
      final DispatchRecord record = await submitDispatch(widget.args);
      SupplierStore.instance.recordCreatedPending();
      if (!mounted) {
        return;
      }
      await Navigator.of(context)
          .pushNamed(AppRoutes.supplierSuccess, arguments: record);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jo‘natish saqlanmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppShell(
      title: 'Tasdiqlash',
      subtitle: '',
      bottom: AbsorbPointer(
        absorbing: _submitting,
        child: const SupplierDock(activeTab: null, centerActive: true),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text.rich(
            TextSpan(
              style: textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Mahsulot: '),
                TextSpan(
                  text: widget.args.item.code,
                  style: textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Nomi: '),
                TextSpan(
                  text: widget.args.item.name,
                  style: textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: textTheme.titleMedium,
              children: [
                const TextSpan(text: 'Miqdor: '),
                TextSpan(
                  text:
                      '${widget.args.qty.toStringAsFixed(2)} ${widget.args.item.uom}',
                  style: textTheme.titleLarge,
                ),
              ],
            ),
          ),
          if (widget.args.item.warehouse.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: textTheme.titleMedium,
                children: [
                  const TextSpan(text: 'Ombor: '),
                  TextSpan(
                    text: widget.args.item.warehouse,
                    style: textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _handleSubmit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text('Ha, jo‘natishni saqlash'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Orqaga qaytish'),
            ),
          ),
        ],
      ),
    );
  }
}
