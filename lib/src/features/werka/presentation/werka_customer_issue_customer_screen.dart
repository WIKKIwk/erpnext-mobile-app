import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/notifications/werka_runtime_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'widgets/m3_picker_sheet.dart';
import 'widgets/werka_dock.dart';

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
  final TextEditingController _qtyController = TextEditingController(text: '1');

  CustomerDirectoryEntry? _selectedCustomer;
  SupplierItem? _selectedItem;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final prefill = widget.prefill!;
      _selectedCustomer = CustomerDirectoryEntry(
        ref: prefill.customerRef,
        name: prefill.customerName,
        phone: '',
      );
      _selectedItem = SupplierItem(
        code: prefill.itemCode,
        name: prefill.itemName,
        uom: prefill.uom,
        warehouse: '',
      );
      _qtyController.text = _formatQty(prefill.qty);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
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

  CustomerDirectoryEntry _customerFromOption(CustomerItemOption option) {
    return CustomerDirectoryEntry(
      ref: option.customerRef,
      name: option.customerName,
      phone: option.customerPhone,
    );
  }

  SupplierItem _itemFromOption(CustomerItemOption option) {
    return SupplierItem(
      code: option.itemCode,
      name: option.itemName,
      uom: option.uom,
      warehouse: option.warehouse,
    );
  }

  Future<void> _pickCustomer() async {
    final picked = await showModalBottomSheet<CustomerDirectoryEntry>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<CustomerDirectoryEntry>(
          title: context.l10n.selectCustomer,
          hintText: context.l10n.searchCustomer,
          loadPage: (query, offset, limit) => MobileApi.instance.werkaCustomers(
            query: query,
            offset: offset,
            limit: limit,
          ),
          itemTitle: (item) => item.name,
          itemSubtitle: (item) => item.phone,
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
    });
  }

  Future<void> _pickItem() async {
    if (_submitting) {
      return;
    }

    if (_selectedCustomer != null) {
      final picked = await showModalBottomSheet<SupplierItem>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: kM3PickerSheetAnimation,
        builder: (context) {
          return M3AsyncPickerSheet<SupplierItem>(
            title: context.l10n.selectItem,
            supportingText: _selectedCustomer!.name,
            hintText: context.l10n.searchItem,
            loadPage: (query, offset, limit) =>
                MobileApi.instance.werkaCustomerItems(
              customerRef: _selectedCustomer!.ref,
              query: query,
              offset: offset,
              limit: limit,
            ),
            itemTitle: (item) => item.name,
            itemSubtitle: (item) => item.code,
            onSelected: (item) => Navigator.of(context).pop(item),
          );
        },
      );
      if (!mounted || picked == null) {
        return;
      }
      setState(() => _selectedItem = picked);
      return;
    }

    final picked = await showModalBottomSheet<CustomerItemOption>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<CustomerItemOption>(
          title: context.l10n.selectItem,
          hintText: context.l10n.searchItem,
          loadPage: (query, offset, limit) =>
              MobileApi.instance.werkaCustomerItemOptions(
            query: query,
            offset: offset,
            limit: limit,
          ),
          itemTitle: (item) => item.itemName,
          itemSubtitle: (item) => '${item.customerName} • ${item.itemCode}',
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _selectedCustomer = _customerFromOption(picked);
      _selectedItem = _itemFromOption(picked);
    });
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_selectedCustomer == null || _selectedItem == null) {
      return;
    }
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.qtyRequired)),
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
                  l10n.confirmTitle,
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
                        child: Text(l10n.no),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.yes),
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
      RefreshHub.instance.emit('werka');
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.werkaSuccess,
        (route) => route.isFirst,
        arguments: record,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message =
          error is MobileApiException && error.code == 'insufficient_stock'
              ? l10n.insufficientStockMessage
              : l10n.customerIssueFailed(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canSubmit =
        _selectedCustomer != null && _selectedItem != null && !_submitting;

    return Scaffold(
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        child: ListView(
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
                      l10n.customerIssueTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 18),
                    Text(l10n.itemLabel, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _pickItem,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(_selectedItem?.name ?? l10n.selectItem),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(l10n.customerLabel, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _pickCustomer,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _selectedCustomer?.name ?? l10n.selectCustomer,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedCustomer != null &&
                        _selectedItem == null &&
                        _selectedCustomer!.phone.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        _selectedCustomer!.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (_selectedItem != null) ...[
                      const SizedBox(height: 14),
                      Text(l10n.amountLabel, style: theme.textTheme.bodySmall),
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
                          _submitting ? l10n.pinSaving : l10n.confirmTitle,
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
            context.l10n.customerIssueTitle,
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ],
    );
  }
}
