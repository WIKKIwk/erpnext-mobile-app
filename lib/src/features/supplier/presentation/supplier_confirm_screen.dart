import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/shell/app_shell.dart';
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
  final Future<DispatchRecord> Function(SupplierConfirmArgs args)?
      submitDispatch;

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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final detailRows = <({String label, String value})>[
      (label: 'Mahsulot', value: widget.args.item.code),
      (label: 'Nomi', value: widget.args.item.name),
      (
        label: 'Miqdor',
        value: '${widget.args.qty.toStringAsFixed(2)} ${widget.args.item.uom}',
      ),
      if (widget.args.item.warehouse.trim().isNotEmpty)
        (label: 'Ombor', value: widget.args.item.warehouse),
    ];
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: _submitting ? () {} : () => Navigator.of(context).maybePop(),
      ),
      title: 'Tasdiqlash',
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      bottom: AbsorbPointer(
        absorbing: _submitting,
        child: const SupplierDock(activeTab: null, centerActive: true),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.args.item.name,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.args.item.code,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        for (int index = 0;
                            index < detailRows.length;
                            index++) ...[
                          _ConfirmDetailRow(
                            label: detailRows[index].label,
                            value: detailRows[index].value,
                            isFirst: index == 0,
                            isLast: index == detailRows.length - 1,
                          ),
                          if (index != detailRows.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.55),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _handleSubmit,
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Text('Ha, jo‘natishni saqlash'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Orqaga qaytish'),
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

class _ConfirmDetailRow extends StatelessWidget {
  const _ConfirmDetailRow({
    required this.label,
    required this.value,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 24 : 0),
          topRight: Radius.circular(isFirst ? 24 : 0),
          bottomLeft: Radius.circular(isLast ? 24 : 0),
          bottomRight: Radius.circular(isLast ? 24 : 0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
