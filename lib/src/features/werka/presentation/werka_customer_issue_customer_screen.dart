import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/werka_runtime_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'widgets/m3_picker_sheet.dart';
import 'widgets/werka_dock.dart';
import 'dart:async';

import 'package:flutter/material.dart';

class WerkaCustomerIssueCustomerScreen extends StatefulWidget {
  const WerkaCustomerIssueCustomerScreen({
    super.key,
    this.prefill,
  });

  final WerkaCustomerIssuePrefillArgs? prefill;

  @override
  State<WerkaCustomerIssueCustomerScreen> createState() =>
      _WerkaCustomerIssueCustomerScreenState();
}

class _WerkaCustomerIssueCustomerScreenState
    extends State<WerkaCustomerIssueCustomerScreen> {
  late Future<List<CustomerDirectoryEntry>> _customersFuture;
  final TextEditingController _qtyController = TextEditingController(text: '1');

  CustomerDirectoryEntry? _selectedCustomer;
  SupplierItem? _selectedItem;
  List<SupplierItem> _customerItems = const <SupplierItem>[];
  bool _loadingItems = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _customersFuture = MobileApi.instance.werkaCustomers();
    if (widget.prefill != null) {
      _applyPrefill(widget.prefill!);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _reloadCustomers() async {
    final future = MobileApi.instance.werkaCustomers();
    setState(() => _customersFuture = future);
    await future;
  }

  Future<void> _applyPrefill(WerkaCustomerIssuePrefillArgs prefill) async {
    setState(() {
      _selectedCustomer = CustomerDirectoryEntry(
        ref: prefill.customerRef,
        name: prefill.customerName,
        phone: '',
      );
      _selectedItem = null;
      _customerItems = const <SupplierItem>[];
      _loadingItems = true;
      _qtyController.text = _formatQty(prefill.qty);
    });
    try {
      final items = await MobileApi.instance.werkaCustomerItems(
        customerRef: prefill.customerRef,
      );
      if (!mounted) {
        return;
      }
      final selected = items.cast<SupplierItem?>().firstWhere(
                (item) => item?.code == prefill.itemCode,
                orElse: () => null,
              ) ??
          SupplierItem(
            code: prefill.itemCode,
            name: prefill.itemName,
            uom: prefill.uom,
            warehouse: '',
          );
      setState(() {
        _customerItems = items;
        _selectedItem = selected;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> _pickCustomer() async {
    final customers = await _customersFuture;
    if (!mounted) {
      return;
    }
    final picked = await showModalBottomSheet<CustomerDirectoryEntry>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3PickerSheet<CustomerDirectoryEntry>(
          title: 'Customer tanlang',
          hintText: 'Customer qidiring',
          items: customers,
          itemTitle: (item) => item.name,
          itemSubtitle: (_) => '',
          matchesQuery: (item, query) {
            final needle = query.trim().toLowerCase();
            return item.name.toLowerCase().contains(needle) ||
                item.phone.toLowerCase().contains(needle) ||
                item.ref.toLowerCase().contains(needle);
          },
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCustomer = picked;
      _selectedItem = null;
      _customerItems = const <SupplierItem>[];
      _loadingItems = true;
    });
    try {
      final items = await MobileApi.instance.werkaCustomerItems(
        customerRef: picked.ref,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _customerItems = items;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
  }

  Future<void> _pickItem() async {
    if (_selectedCustomer == null || _loadingItems) {
      return;
    }
    if (_customerItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customerga biriktirilgan mol topilmadi')),
      );
      return;
    }

    final picked = await showModalBottomSheet<SupplierItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3PickerSheet<SupplierItem>(
          title: 'Mol tanlang',
          supportingText: _selectedCustomer!.name,
          hintText: 'Mol qidiring',
          items: _customerItems,
          itemTitle: (item) => item.name,
          itemSubtitle: (_) => '',
          matchesQuery: (item, query) {
            final needle = query.trim().toLowerCase();
            return item.name.toLowerCase().contains(needle) ||
                item.code.toLowerCase().contains(needle);
          },
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _selectedItem = picked);
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null || _selectedItem == null) {
      return;
    }
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Miqdor kiriting')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasdiqlash',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  _selectedCustomer!.name,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedItem!.name,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${qty.toStringAsFixed(0)} ${_selectedItem!.uom}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Yo‘q'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Ha'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final created = await MobileApi.instance.createWerkaCustomerIssue(
        customerRef: _selectedCustomer!.ref,
        itemCode: _selectedItem!.code,
        qty: qty,
      );
      if (!mounted) {
        return;
      }
      final record = DispatchRecord(
        id: created.entryID,
        supplierRef: created.customerRef,
        supplierName: created.customerName,
        itemCode: created.itemCode,
        itemName: created.itemName,
        uom: created.uom,
        sentQty: created.qty,
        acceptedQty: 0,
        amount: 0,
        currency: '',
        note: '',
        eventType: 'customer_issue_pending',
        highlight: '',
        status: DispatchStatus.pending,
        createdLabel: created.createdLabel,
      );
      WerkaRuntimeStore.instance.recordCreatedPending(record);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.werkaSuccess,
        (route) => route.isFirst,
        arguments: record,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mol jo‘natish bo‘lmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canPickItem = _selectedCustomer != null && !_loadingItems;
    final canSubmit = _selectedCustomer != null &&
        _selectedItem != null &&
        !_submitting &&
        !_loadingItems;

    return Scaffold(
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        child: FutureBuilder<List<CustomerDirectoryEntry>>(
          future: _customersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _WerkaCustomerIssueHeader(theme: theme),
                  const SizedBox(height: 20),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Customerlar yuklanmadi: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reloadCustomers,
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                _WerkaCustomerIssueHeader(theme: theme),
                const SizedBox(height: 20),
                Card.filled(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mol jo‘natish',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 18),
                        Text('Customer', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _pickCustomer,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _selectedCustomer?.name ?? 'Customer tanlang',
                              ),
                            ),
                          ),
                        ),
                        if (_selectedCustomer != null) ...[
                          const SizedBox(height: 14),
                          Text('Mol', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: canPickItem ? _pickItem : null,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _loadingItems
                                      ? 'Yuklanmoqda...'
                                      : _selectedItem?.name ?? 'Mol tanlang',
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_selectedItem != null) ...[
                          const SizedBox(height: 14),
                          Text('Miqdor', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: _selectedItem!.uom,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: canSubmit ? _submit : null,
                            child: Text(
                              _submitting ? 'Saqlanmoqda...' : 'Tasdiqlash',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: WerkaDock(activeTab: null),
        ),
      ),
    );
  }
}

class WerkaCustomerIssuePrefillArgs {
  const WerkaCustomerIssuePrefillArgs({
    required this.customerRef,
    required this.customerName,
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
  });

  final String customerRef;
  final String customerName;
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
}

class _WerkaCustomerIssueHeader extends StatelessWidget {
  const _WerkaCustomerIssueHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 52,
          width: 52,
          child: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Mol jo‘natish',
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ],
    );
  }
}
