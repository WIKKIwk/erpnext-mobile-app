import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/notifications/werka_runtime_store.dart';
import '../../../core/search/search_normalizer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
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
  Future<List<CustomerItemOption>>? _itemOptionsFuture;
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
    _itemOptionsFuture = MobileApi.instance.werkaCustomerItemOptions();
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
    MobileApi.instance.clearWerkaCustomerIssueLookups();
    final customersFuture = MobileApi.instance.werkaCustomers();
    final itemOptionsFuture = MobileApi.instance.werkaCustomerItemOptions();
    setState(() {
      _customersFuture = customersFuture;
      _itemOptionsFuture = itemOptionsFuture;
    });
    await customersFuture;
  }

  Future<void> _loadItemsForCustomer(
    CustomerDirectoryEntry customer, {
    String? preferredItemCode,
  }) async {
    setState(() {
      _selectedCustomer = customer;
      _selectedItem = null;
      _customerItems = const <SupplierItem>[];
      _loadingItems = true;
    });
    try {
      final items = await MobileApi.instance.werkaCustomerItems(
        customerRef: customer.ref,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _customerItems = items;
        if (preferredItemCode != null && preferredItemCode.trim().isNotEmpty) {
          _selectedItem = items.cast<SupplierItem?>().firstWhere(
                    (item) => item?.code == preferredItemCode,
                    orElse: () => null,
                  ) ??
              SupplierItem(
                code: preferredItemCode,
                name: items
                        .cast<SupplierItem?>()
                        .firstWhere(
                          (item) => item?.code == preferredItemCode,
                          orElse: () => null,
                        )
                        ?.name ??
                    '',
                uom: items
                        .cast<SupplierItem?>()
                        .firstWhere(
                          (item) => item?.code == preferredItemCode,
                          orElse: () => null,
                        )
                        ?.uom ??
                    '',
                warehouse: items
                        .cast<SupplierItem?>()
                        .firstWhere(
                          (item) => item?.code == preferredItemCode,
                          orElse: () => null,
                        )
                        ?.warehouse ??
                    '',
              );
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
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
          title: context.l10n.selectCustomer,
          hintText: context.l10n.searchCustomer,
          items: customers,
          itemTitle: (item) => item.name,
          itemSubtitle: (_) => '',
          matchesQuery: (item, query) {
            return searchMatches(query, [
              item.name,
              item.phone,
              item.ref,
            ]);
          },
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    await _loadItemsForCustomer(picked);
  }

  Future<void> _pickItem() async {
    if (_loadingItems) {
      return;
    }
    final l10n = context.l10n;
    final future =
        _itemOptionsFuture ??= MobileApi.instance.werkaCustomerItemOptions();
    List<CustomerItemOption> options;
    try {
      options = await future;
    } catch (error) {
      _itemOptionsFuture = null;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mol ro‘yxati yuklanmadi: $error')),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    if (_selectedCustomer != null && _customerItems.isNotEmpty) {
      final picked = await showModalBottomSheet<SupplierItem>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: kM3PickerSheetAnimation,
        builder: (context) {
          return M3PickerSheet<SupplierItem>(
            title: l10n.selectItem,
            supportingText: _selectedCustomer!.name,
            hintText: l10n.searchItem,
            items: _customerItems,
            itemTitle: (item) => item.name,
            itemSubtitle: (_) => '',
            matchesQuery: (item, query) {
              return searchMatches(query, [
                item.name,
                item.code,
              ]);
            },
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
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biriktirilgan mol topilmadi')),
      );
      return;
    }
    final picked = await showModalBottomSheet<CustomerItemOption>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3PickerSheet<CustomerItemOption>(
          title: l10n.selectItem,
          hintText: l10n.searchItem,
          items: options,
          itemTitle: (item) => item.itemName,
          itemSubtitle: (item) => item.customerName,
          matchesQuery: (item, query) {
            return searchMatches(query, [
              item.itemName,
              item.itemCode,
              item.customerName,
              item.customerPhone,
            ]);
          },
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
    if (!mounted || picked == null) {
      return;
    }
    await _loadItemsForCustomer(
      CustomerDirectoryEntry(
        ref: picked.customerRef,
        name: picked.customerName,
        phone: picked.customerPhone,
      ),
      preferredItemCode: picked.itemCode,
    );
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
    final canPickItem = !_loadingItems;
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
              return const Center(child: AppLoadingIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _WerkaCustomerIssueHeader(theme: theme),
                  const SizedBox(height: 20),
                  AppRetryState(onRetry: _reloadCustomers),
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
                          l10n.customerIssueTitle,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 18),
                        Text(l10n.itemLabel, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: canPickItem ? _pickItem : null,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _loadingItems
                                    ? l10n.loading
                                    : _selectedItem?.name ?? l10n.selectItem,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(l10n.customerLabel,
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _pickCustomer,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _selectedCustomer?.name ?? l10n.selectCustomer,
                              ),
                            ),
                          ),
                        ),
                        if (_selectedCustomer != null &&
                            _selectedItem == null) ...[
                          const SizedBox(height: 14),
                          if (_selectedCustomer!.phone.trim().isNotEmpty)
                            Text(
                              _selectedCustomer!.phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                        if (_selectedItem != null) ...[
                          const SizedBox(height: 14),
                          Text(l10n.amountLabel,
                              style: theme.textTheme.bodySmall),
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
            context.l10n.customerIssueTitle,
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ],
    );
  }
}
