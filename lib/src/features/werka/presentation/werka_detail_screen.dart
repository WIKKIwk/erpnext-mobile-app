import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaDetailScreen extends StatefulWidget {
  const WerkaDetailScreen({
    super.key,
    required this.record,
  });

  final DispatchRecord record;

  @override
  State<WerkaDetailScreen> createState() => _WerkaDetailScreenState();
}

class _WerkaDetailScreenState extends State<WerkaDetailScreen> {
  late final TextEditingController controller;
  late final TextEditingController returnedController;
  bool showReturnFields = false;
  bool submitting = false;
  String? returnReason;

  static const List<String> _returnReasons = <String>[
    'Yaroqsiz',
    'Ko‘p berilgan',
    'Hujjatdagi mahsulot emas',
  ];

  @override
  void initState() {
    super.initState();
    controller =
        TextEditingController(text: widget.record.sentQty.toStringAsFixed(0));
    returnedController = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    returnedController.dispose();
    super.dispose();
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    final acceptedQty = double.tryParse(controller.text.trim()) ?? 0;
    if (acceptedQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qabul qilingan miqdorni kiriting.')),
      );
      return;
    }
    if (acceptedQty > widget.record.sentQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Qabul qilingan miqdor ${widget.record.sentQty.toStringAsFixed(2)} ${widget.record.uom} dan oshmasin.',
          ),
        ),
      );
      return;
    }

    final difference = widget.record.sentQty - acceptedQty;
    if (difference > 0.0001 && !showReturnFields) {
      setState(() {
        showReturnFields = true;
        returnedController.text = _formatQty(difference);
      });
      return;
    }

    final returnedText = returnedController.text.trim();
    double returnedQty = 0;
    if (returnedText.isNotEmpty) {
      returnedQty = double.tryParse(returnedText) ?? -1;
      if (returnedQty < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Qaytarilayotgan miqdor noto‘g‘ri.')),
        );
        return;
      }
      if (returnedQty-difference > 0.0001) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Qaytarilayotgan miqdor farqdan oshmasin.'),
          ),
        );
        return;
      }
    }

    setState(() => submitting = true);
    try {
      final accepted = await MobileApi.instance.confirmReceipt(
        receiptID: widget.record.id,
        acceptedQty: acceptedQty,
        returnedQty: returnedQty,
        returnReason: returnReason ?? '',
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context)
          .pushNamed(AppRoutes.werkaSuccess, arguments: accepted);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Qabul qilish bo‘lmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Qabul qilish',
      subtitle: '',
      bottom: const WerkaDock(activeTab: null),
      child: Column(
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Supplier', value: widget.record.supplierName),
                _InfoRow(
                    label: 'Mahsulot',
                    value:
                        '${widget.record.itemCode} • ${widget.record.itemName}'),
                _InfoRow(
                    label: 'Jo‘natilgan',
                    value:
                        '${widget.record.sentQty.toStringAsFixed(2)} ${widget.record.uom}'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.displaySmall,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: widget.record.uom,
            ),
          ),
          if (showReturnFields) ...[
            const SizedBox(height: 18),
            TextField(
              controller: returnedController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Qaytarilayotgan',
                hintText: '0',
                suffixText: widget.record.uom,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sabab',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _returnReasons.map((reason) {
                return ChoiceChip(
                  label: Text(reason),
                  selected: returnReason == reason,
                  onSelected: (_) {
                    setState(() => returnReason = reason);
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: submitting ? null : _submit,
              child: Text(
                submitting ? 'Saqlanmoqda...' : 'Qabul qilishni yakunlash',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
