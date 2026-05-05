import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/notifications/store/werka_runtime_store.dart';
import '../../../core/widgets/feedback/m3_confirm_dialog.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../../core/theme/app_theme.dart';
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
  late final TextEditingController returnCommentController;
  bool showReturnFields = false;
  bool fullReturnMode = false;
  bool submitting = false;
  String? returnReason;
  String? _acceptedQtyBeforeFullReturn;

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
    returnCommentController = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    returnedController.dispose();
    returnCommentController.dispose();
    super.dispose();
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    final double acceptedQty =
        fullReturnMode ? 0.0 : (double.tryParse(controller.text.trim()) ?? 0.0);
    if (acceptedQty <= 0) {
      if (fullReturnMode) {
        // full return mode handles zero accepted qty
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Qabul qilingan miqdorni kiriting.')),
        );
        return;
      }
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
    final returnComment = returnCommentController.text.trim();
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
      if (returnedQty - difference > 0.0001) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Qaytarilayotgan miqdor farqdan oshmasin.'),
          ),
        );
        return;
      }
    }

    final bool? confirmed = await showM3ConfirmDialog(
      context: context,
      title: 'Tasdiqlash',
      message: 'Haqiqatan ham shu qabulni yakunlaysizmi?',
      cancelLabel: 'Yo‘q',
      confirmLabel: 'Ha',
    );
    if (confirmed != true) {
      return;
    }

    setState(() => submitting = true);
    try {
      final accepted = await MobileApi.instance.confirmReceipt(
        receiptID: widget.record.id,
        acceptedQty: acceptedQty,
        returnedQty: fullReturnMode ? widget.record.sentQty : returnedQty,
        returnReason: returnReason ?? '',
        returnComment: returnComment,
      );
      WerkaRuntimeStore.instance.recordTransition(
        before: widget.record,
        after: accepted,
      );
      RefreshHub.instance.emit('werka');
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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    useNativeNavigationTitle(context, 'Qabul qilish');
    final detailRows = <({String label, String value})>[
      (label: 'Supplier', value: widget.record.supplierName),
      (
        label: 'Mahsulot',
        value: widget.record.itemName,
      ),
      (
        label: 'Jo‘natilgan',
        value:
            '${widget.record.sentQty.toStringAsFixed(2)} ${widget.record.uom}',
      ),
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const NativeNavigationTitleHeader(title: 'Qabul qilish'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 12, 110),
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
                            widget.record.itemName,
                            style: textTheme.headlineSmall,
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
                                  _WerkaDetailInfoRow(
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
                                      color: scheme.outlineVariant
                                          .withValues(alpha: 0.55),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Card.filled(
                            margin: EdgeInsets.zero,
                            color: scheme.surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Qabul qilingan',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: controller,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    style: textTheme.displaySmall,
                                    readOnly: fullReturnMode,
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      suffixText: widget.record.uom,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  fullReturnMode = !fullReturnMode;
                                  if (fullReturnMode) {
                                    _acceptedQtyBeforeFullReturn =
                                        controller.text;
                                    controller.text = '0';
                                    showReturnFields = false;
                                    returnedController.clear();
                                  } else {
                                    controller.text =
                                        _acceptedQtyBeforeFullReturn ??
                                            widget.record.sentQty
                                                .toStringAsFixed(0);
                                    showReturnFields = false;
                                  }
                                });
                              },
                              child: Text(
                                fullReturnMode
                                    ? 'Hammasini qaytarish tanlangan'
                                    : 'Hammasini qaytarish',
                              ),
                            ),
                          ),
                          if (fullReturnMode) ...[
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sabab',
                                style: textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._returnReasons.map(
                              (reason) => InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() => returnReason = reason);
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        returnReason == reason
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                .radio_button_unchecked_rounded,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style: textTheme.bodyLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: returnCommentController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                labelText: 'Izoh',
                                hintText: 'Ixtiyoriy izoh',
                              ),
                            ),
                          ] else if (showReturnFields) ...[
                            const SizedBox(height: 18),
                            TextField(
                              controller: returnedController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: textTheme.displaySmall,
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
                                style: textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._returnReasons.map(
                              (reason) => InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() => returnReason = reason);
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        returnReason == reason
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                .radio_button_unchecked_rounded,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style: textTheme.bodyLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: submitting ? null : _submit,
                              child: Text(
                                submitting ? 'Saqlanmoqda...' : 'Yakunlash',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const WerkaDock(activeTab: null),
    );
  }
}

class _WerkaDetailInfoRow extends StatelessWidget {
  const _WerkaDetailInfoRow({
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
