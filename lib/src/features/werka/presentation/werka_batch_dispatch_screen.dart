import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/app_preview.dart';
import '../../../core/customer/customer_priority.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/notifications/store/werka_runtime_store.dart';
import '../../../core/search/search_activity_store.dart';
import '../../../core/search/search_normalizer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'dart:math';
import 'widgets/m3_picker_sheet.dart';
import 'widgets/werka_dock.dart';
import 'package:full_screen_back_gesture/cupertino.dart'
    as fullscreen_cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

int _compareSupplierItemsByName(SupplierItem left, SupplierItem right) {
  final nameCompare =
      left.name.toLowerCase().compareTo(right.name.toLowerCase());
  if (nameCompare != 0) {
    return nameCompare;
  }
  return left.code.toLowerCase().compareTo(right.code.toLowerCase());
}

int _compareCustomerItemOptionsByName(
  CustomerItemOption left,
  CustomerItemOption right,
) {
  final itemCompare =
      left.itemName.toLowerCase().compareTo(right.itemName.toLowerCase());
  if (itemCompare != 0) {
    return itemCompare;
  }
  final customerCompare = compareCustomerNamesForDefault(
    left.customerName,
    right.customerName,
  );
  if (customerCompare != 0) {
    return customerCompare;
  }
  return left.itemCode.toLowerCase().compareTo(right.itemCode.toLowerCase());
}

class WerkaBatchDispatchScreen extends StatefulWidget {
  const WerkaBatchDispatchScreen({super.key});

  @override
  State<WerkaBatchDispatchScreen> createState() =>
      _WerkaBatchDispatchScreenState();
}

class _WerkaBatchDispatchScreenState extends State<WerkaBatchDispatchScreen> {
  final TextEditingController _qtyController = TextEditingController();
  final List<_WerkaBatchDraftLine> _drafts = <_WerkaBatchDraftLine>[];
  final bool _previewMode = AppPreview.batchDispatchDemo;

  CustomerDirectoryEntry? _selectedCustomer;
  SupplierItem? _selectedItem;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
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

  Future<CustomerDirectoryEntry> _preferredCustomerForOption(
    CustomerItemOption option,
  ) async {
    final fallback = _customerFromOption(option);
    if (_previewMode) {
      final previewCustomers = _previewOptions
          .where((item) => item.itemCode == option.itemCode)
          .map(_customerFromOption);
      return preferPrimaryCustomer<CustomerDirectoryEntry>(
            previewCustomers,
            customerName: (item) => item.name,
          ) ??
          fallback;
    }
    try {
      final customers = await MobileApi.instance.werkaCustomersForItem(
        itemCode: option.itemCode,
        itemName: option.itemName,
        limit: 200,
        offset: 0,
      );
      return preferPrimaryCustomer<CustomerDirectoryEntry>(
            customers,
            customerName: (item) => item.name,
          ) ??
          fallback;
    } catch (_) {
      return fallback;
    }
  }

  void _clearSelectedItem() {
    setState(() {
      _selectedItem = null;
      _qtyController.clear();
    });
  }

  void _clearSelectedCustomer() {
    setState(() {
      _selectedCustomer = null;
    });
  }

  double get _currentQty => double.tryParse(_qtyController.text.trim()) ?? 0;

  bool get _hasCurrentValidLine =>
      _selectedCustomer != null && _selectedItem != null && _currentQty > 0;

  Future<void> _pickCustomer() async {
    if (_previewMode) {
      final previewCustomers = _selectedItem == null
          ? _previewCustomers
          : _previewOptions
              .where((item) => item.itemCode == _selectedItem!.code)
              .map(_customerFromOption)
              .fold<List<CustomerDirectoryEntry>>(<CustomerDirectoryEntry>[], (
              result,
              customer,
            ) {
              if (result.any((item) => item.ref == customer.ref)) {
                return result;
              }
              return [...result, customer];
            })
        ..sort((left, right) => compareCustomerNamesForDefault(
              left.name,
              right.name,
            ));
      final picked = await showModalBottomSheet<CustomerDirectoryEntry>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: kM3PickerSheetAnimation,
        builder: (context) {
          return M3PickerSheet<CustomerDirectoryEntry>(
            title: context.l10n.selectCustomer,
            hintText: context.l10n.searchCustomer,
            items: previewCustomers,
            itemTitle: (item) => item.name,
            itemSubtitle: (item) => item.phone,
            matchesQuery: (item, query) => searchMatches(query, [
              item.name,
              item.phone,
            ]),
            onSelected: (item) => Navigator.of(context).pop(item),
          );
        },
      );
      if (picked == null || !mounted) {
        return;
      }
      setState(() {
        _selectedCustomer = picked;
        if (_selectedItem == null) {
          _qtyController.clear();
        }
      });
      return;
    }

    final picked = await showModalBottomSheet<CustomerDirectoryEntry>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<CustomerDirectoryEntry>(
          title: context.l10n.selectCustomer,
          hintText: context.l10n.searchCustomer,
          loadPage: (query, offset, limit) => _selectedItem != null
              ? MobileApi.instance.werkaCustomersForItem(
                  itemCode: _selectedItem!.code,
                  itemName: _selectedItem!.name,
                  query: query,
                  offset: offset,
                  limit: limit,
                )
              : MobileApi.instance.werkaCustomers(
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
      if (_selectedItem == null) {
        _qtyController.clear();
      }
    });
  }

  Future<void> _pickItem() async {
    if (_previewMode) {
      if (_selectedCustomer != null) {
        final items = await SearchActivityStore.instance.sortByItemCode(
          _previewOptions
              .where((item) => item.customerRef == _selectedCustomer!.ref)
              .map(_itemFromOption),
          itemCode: (item) => item.code,
          fallback: _compareSupplierItemsByName,
        );
        if (!mounted) {
          return;
        }
        final picked = await showModalBottomSheet<SupplierItem>(
          context: context,
          isDismissible: true,
          enableDrag: true,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          sheetAnimationStyle: kM3PickerSheetAnimation,
          builder: (context) {
            return M3PickerSheet<SupplierItem>(
              title: context.l10n.selectItem,
              supportingText: _selectedCustomer!.name,
              hintText: context.l10n.searchItem,
              showScanIcon: true,
              items: items,
              itemTitle: (item) => item.name,
              itemSubtitle: (item) => item.code,
              matchesQuery: (item, query) => searchMatches(query, [
                item.name,
                item.code,
                _selectedCustomer!.name,
              ]),
              onSelected: (item) => Navigator.of(context).pop(item),
            );
          },
        );
        if (picked == null || !mounted) {
          return;
        }
        setState(() {
          _selectedItem = picked;
          _qtyController.clear();
        });
        return;
      }

      final options = await SearchActivityStore.instance.sortByItemCode(
        _previewOptions,
        itemCode: (item) => item.itemCode,
        fallback: _compareCustomerItemOptionsByName,
      );
      if (!mounted) {
        return;
      }
      final picked = await showModalBottomSheet<CustomerItemOption>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: kM3PickerSheetAnimation,
        builder: (context) {
          return M3PickerSheet<CustomerItemOption>(
            title: context.l10n.selectItem,
            hintText: context.l10n.searchItem,
            showScanIcon: true,
            items: options,
            itemTitle: (item) => item.itemName,
            itemSubtitle: (item) => '${item.customerName} • ${item.itemCode}',
            matchesQuery: (item, query) => searchMatches(query, [
              item.itemName,
              item.itemCode,
              item.customerName,
            ]),
            onSelected: (item) => Navigator.of(context).pop(item),
          );
        },
      );
      if (picked == null || !mounted) {
        return;
      }
      final preferredCustomer = await _preferredCustomerForOption(picked);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedCustomer = preferredCustomer;
        _selectedItem = _itemFromOption(picked);
        _qtyController.clear();
      });
      return;
    }

    if (_selectedCustomer != null) {
      final picked = await showModalBottomSheet<SupplierItem>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        sheetAnimationStyle: kM3PickerSheetAnimation,
        builder: (context) {
          return M3AsyncPickerSheet<SupplierItem>(
            title: context.l10n.selectItem,
            supportingText: _selectedCustomer!.name,
            hintText: context.l10n.searchItem,
            showScanIcon: true,
            pageSize: 100,
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
      if (picked == null || !mounted) {
        return;
      }
      setState(() {
        _selectedItem = picked;
        _qtyController.clear();
      });
      return;
    }

    final picked = await showModalBottomSheet<CustomerItemOption>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<CustomerItemOption>(
          title: context.l10n.selectItem,
          hintText: context.l10n.searchItem,
          showScanIcon: true,
          pageSize: 200,
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
    if (picked == null || !mounted) {
      return;
    }
    final preferredCustomer = await _preferredCustomerForOption(picked);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedCustomer = preferredCustomer;
      _selectedItem = _itemFromOption(picked);
      _qtyController.clear();
    });
  }

  _WerkaBatchDraftLine _buildCurrentLine() {
    return _WerkaBatchDraftLine(
      localID: DateTime.now().microsecondsSinceEpoch.toString(),
      customer: _selectedCustomer!,
      item: _selectedItem!,
      qty: _currentQty,
    );
  }

  void _prepareNextLine() {
    _selectedItem = null;
    _qtyController.clear();
  }

  void _saveCurrentLine() {
    if (!_hasCurrentValidLine) {
      return;
    }
    final line = _buildCurrentLine();
    setState(() {
      _drafts.add(line);
      _prepareNextLine();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.batchDraftAdded)),
    );
  }

  Future<void> _openReview({bool saveCurrentLine = false}) async {
    if (saveCurrentLine && !_hasCurrentValidLine) {
      return;
    }

    final lines = <_WerkaBatchDraftLine>[
      ..._drafts,
      if (saveCurrentLine) _buildCurrentLine(),
    ];
    if (lines.isEmpty) {
      return;
    }

    if (saveCurrentLine) {
      setState(() {
        _drafts
          ..clear()
          ..addAll(lines);
        _prepareNextLine();
      });
    }

    final updated =
        await Navigator.of(context).push<List<_WerkaBatchDraftLine>>(
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
          ? fullscreen_cupertino.CupertinoPageRoute<List<_WerkaBatchDraftLine>>(
              builder: (context) => _WerkaBatchDispatchReviewScreen(
                initialLines: lines,
                previewMode: _previewMode,
              ),
              settings: const RouteSettings(
                name: 'werka-batch-dispatch-review',
              ),
            )
          : MaterialPageRoute<List<_WerkaBatchDraftLine>>(
              builder: (context) => _WerkaBatchDispatchReviewScreen(
                initialLines: lines,
                previewMode: _previewMode,
              ),
              settings: const RouteSettings(
                name: 'werka-batch-dispatch-review',
              ),
            ),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() {
      _drafts
        ..clear()
        ..addAll(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasSavedLines = _drafts.isNotEmpty;
    final pickerButtonStyle = FilledButton.styleFrom(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      disabledBackgroundColor: scheme.surfaceContainerLow,
      disabledForegroundColor: scheme.onSurfaceVariant,
      elevation: 0,
      minimumSize: const Size.fromHeight(58),
      alignment: Alignment.centerLeft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
    final qtyInputDecoration = InputDecoration(
      hintText: '0',
      suffixText: _selectedItem?.uom,
      filled: true,
      fillColor: scheme.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );

    return AppShell(
      title: l10n.batchDispatchTitle,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      leading: NativeBackButtonSlot(
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      bottom: const WerkaDock(activeTab: null),
      contentPadding: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        children: [
          M3SegmentFilledSurface(
            slot: M3SegmentVerticalSlot.top,
            cornerRadius: M3SegmentedListGeometry.cornerLarge,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.batchDispatchTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_previewMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Preview mode',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                  if (hasSavedLines) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l10n.batchDraftCountLabel(_drafts.length),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: l10n.batchViewListAction,
                          child: IconButton.filledTonal(
                            onPressed: _openReview,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.list_alt_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(l10n.itemLabel, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          style: pickerButtonStyle,
                          onPressed: _pickItem,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedItem?.name ?? l10n.selectItem,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedItem != null) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Clear item',
                          onPressed: _clearSelectedItem,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(l10n.customerLabel, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          style: pickerButtonStyle,
                          onPressed: _pickCustomer,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCustomer?.name ??
                                      l10n.selectCustomer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedCustomer != null) ...[
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Clear customer',
                          onPressed: _clearSelectedCustomer,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ],
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
                      onChanged: (_) => setState(() {}),
                      decoration: qtyInputDecoration,
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (!hasSavedLines)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _hasCurrentValidLine ? _saveCurrentLine : null,
                        child: Text(l10n.nextItemAction),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _hasCurrentValidLine ? _saveCurrentLine : null,
                            child: Text(l10n.addAnotherAction),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _hasCurrentValidLine
                                ? () => _openReview(saveCurrentLine: true)
                                : _drafts.length >= 2
                                    ? () => _openReview()
                                    : null,
                            child: Text(l10n.confirmTitle),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WerkaBatchDispatchReviewScreen extends StatefulWidget {
  const _WerkaBatchDispatchReviewScreen({
    required this.initialLines,
    required this.previewMode,
  });

  final List<_WerkaBatchDraftLine> initialLines;
  final bool previewMode;

  @override
  State<_WerkaBatchDispatchReviewScreen> createState() =>
      _WerkaBatchDispatchReviewScreenState();
}

class _WerkaBatchDispatchReviewScreenState
    extends State<_WerkaBatchDispatchReviewScreen> {
  final ScrollController _scrollController = ScrollController();

  late List<_WerkaBatchDraftLine> _lines;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _lines = List<_WerkaBatchDraftLine>.from(widget.initialLines);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _customerCount =>
      _lines.map((item) => item.customer.ref).toSet().length;

  DispatchRecord _recordFromIssue(WerkaCustomerIssueRecord created) {
    return DispatchRecord(
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
  }

  Future<void> _submit() async {
    if (_submitting || _lines.length < 2) {
      return;
    }

    if (widget.previewMode) {
      setState(() => _submitting = true);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => _WerkaBatchSuccessScreen(
            createdCount: _lines.length,
            failedCount: 0,
            returnRouteName: AppRoutes.werkaBatchDispatch,
            returnLabel:
                context.l10n.backToFlow(context.l10n.batchDispatchTitle),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final batchID =
        'batch-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    final result = await MobileApi.instance.createWerkaCustomerIssueBatch(
      clientBatchID: batchID,
      lines: _lines
          .map(
            (line) => WerkaCustomerIssueBatchLineRequest(
              customerRef: line.customer.ref,
              itemCode: line.item.code,
              qty: line.qty,
            ),
          )
          .toList(),
    );

    final failedIndices = result.failed.map((item) => item.lineIndex).toSet();
    final failed = <_WerkaBatchDraftLine>[
      for (var i = 0; i < _lines.length; i++)
        if (failedIndices.contains(i)) _lines[i],
    ];
    final createdCount = result.created.length;

    await SearchActivityStore.instance.recordItemSelections(
      result.created
          .map((item) => item.record?.itemCode ?? '')
          .where((item) => item.trim().isNotEmpty),
    );

    for (final created in result.created) {
      final record = created.record;
      if (record == null) {
        continue;
      }
      WerkaRuntimeStore.instance.recordCreatedPending(
        _recordFromIssue(record),
      );
    }

    RefreshHub.instance.emit('werka');

    if (!mounted) {
      return;
    }

    setState(() => _submitting = false);

    final l10n = context.l10n;
    if (failed.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => _WerkaBatchSuccessScreen(
            createdCount: createdCount,
            failedCount: 0,
            returnRouteName: AppRoutes.werkaBatchDispatch,
            returnLabel:
                context.l10n.backToFlow(context.l10n.batchDispatchTitle),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.batchSubmitResultTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.batchCreatedCountLabel(createdCount)),
              const SizedBox(height: 8),
              Text(l10n.batchFailedCountLabel(failed.length)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.closeAction),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(failed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canSubmit = !_submitting && _lines.length >= 2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_lines);
      },
      child: AppShell(
        title: l10n.batchReviewTitle,
        subtitle: '',
        nativeTopBar: true,
        nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
        leading: NativeBackButtonSlot(
          onPressed: () => Navigator.of(context).pop(_lines),
        ),
        contentPadding: EdgeInsets.zero,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                children: [
                  M3SegmentFilledSurface(
                    slot: M3SegmentVerticalSlot.top,
                    cornerRadius: M3SegmentedListGeometry.cornerLarge,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.batchReviewTitle,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SummaryChip(
                                label: l10n.batchCustomerCountLabel(
                                  _customerCount,
                                ),
                              ),
                              _SummaryChip(
                                label: l10n.batchDraftCountLabel(_lines.length),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: M3SegmentedListGeometry.gap),
                  for (var index = 0; index < _lines.length; index++) ...[
                    M3SegmentFilledSurface(
                      slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
                        index,
                        _lines.length,
                      ),
                      cornerRadius: M3SegmentedListGeometry.cornerRadiusForSlot(
                        M3SegmentedListGeometry.standaloneListSlotForIndex(
                          index,
                          _lines.length,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _lines[index].customer.name,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _lines[index].item.name,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_lines[index].qty.toStringAsFixed(0)} ${_lines[index].item.uom} • ${_lines[index].item.code}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: _submitting
                                  ? null
                                  : () {
                                      final localID = _lines[index].localID;
                                      setState(() {
                                        _lines = _lines
                                            .where((item) =>
                                                item.localID != localID)
                                            .toList();
                                      });
                                    },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (index != _lines.length - 1)
                      const SizedBox(height: M3SegmentedListGeometry.gap),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_lines.length < 2) ...[
                      Text(
                        l10n.batchNeedAtLeastTwoItems,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: Text(
                        _submitting ? l10n.sending : l10n.confirmTitle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WerkaBatchDraftLine {
  const _WerkaBatchDraftLine({
    required this.localID,
    required this.customer,
    required this.item,
    required this.qty,
  });

  final String localID;
  final CustomerDirectoryEntry customer;
  final SupplierItem item;
  final double qty;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WerkaBatchSuccessScreen extends StatelessWidget {
  const _WerkaBatchSuccessScreen({
    required this.createdCount,
    required this.failedCount,
    required this.returnRouteName,
    required this.returnLabel,
  });

  final int createdCount;
  final int failedCount;
  final String returnRouteName;
  final String returnLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppShell(
      title: l10n.sentSuccess,
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const WerkaDock(activeTab: null),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 140),
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
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: 44,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.batchCreatedCountLabel(createdCount),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    failedCount > 0
                        ? l10n.batchFailedCountLabel(failedCount)
                        : l10n.batchSentLine(createdCount),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                returnRouteName,
                (route) => route.isFirst,
              ),
              child: Text(returnLabel),
            ),
          ),
        ],
      ),
    );
  }
}

const List<CustomerDirectoryEntry> _previewCustomers = [
  CustomerDirectoryEntry(
    ref: 'CUST-001',
    name: 'Aziz Market',
    phone: '+998901111111',
  ),
  CustomerDirectoryEntry(
    ref: 'CUST-002',
    name: 'Sardor Do\'kon',
    phone: '+998902222222',
  ),
  CustomerDirectoryEntry(
    ref: 'CUST-003',
    name: 'Dilnoza Shop',
    phone: '+998903333333',
  ),
];

const List<CustomerItemOption> _previewOptions = [
  CustomerItemOption(
    customerRef: 'CUST-001',
    customerName: 'Aziz Market',
    customerPhone: '+998901111111',
    itemCode: 'ITEM-001',
    itemName: 'Un 5kg',
    uom: 'Qop',
    warehouse: 'Stores - CH',
  ),
  CustomerItemOption(
    customerRef: 'CUST-001',
    customerName: 'Aziz Market',
    customerPhone: '+998901111111',
    itemCode: 'ITEM-002',
    itemName: 'Yog\' 1L',
    uom: 'Dona',
    warehouse: 'Stores - CH',
  ),
  CustomerItemOption(
    customerRef: 'CUST-002',
    customerName: 'Sardor Do\'kon',
    customerPhone: '+998902222222',
    itemCode: 'ITEM-003',
    itemName: 'Shakar 5kg',
    uom: 'Qop',
    warehouse: 'Stores - CH',
  ),
  CustomerItemOption(
    customerRef: 'CUST-003',
    customerName: 'Dilnoza Shop',
    customerPhone: '+998903333333',
    itemCode: 'ITEM-004',
    itemName: 'Guruch 1kg',
    uom: 'Dona',
    warehouse: 'Stores - CH',
  ),
  CustomerItemOption(
    customerRef: 'CUST-003',
    customerName: 'Dilnoza Shop',
    customerPhone: '+998903333333',
    itemCode: 'ITEM-005',
    itemName: 'Makaron',
    uom: 'Dona',
    warehouse: 'Stores - CH',
  ),
];
