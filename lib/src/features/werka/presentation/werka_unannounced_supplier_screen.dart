import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/notifications/werka_runtime_store.dart';
import '../../../core/search/search_activity_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/m3_segmented_list.dart';
import '../../../core/widgets/native_back_button.dart';
import '../../shared/models/app_models.dart';
import 'widgets/m3_picker_sheet.dart';
import 'widgets/werka_dock.dart';

import 'package:flutter/material.dart';

class WerkaUnannouncedSupplierScreen extends StatefulWidget {
  const WerkaUnannouncedSupplierScreen({
    super.key,
    this.prefill,
  });

  final WerkaUnannouncedPrefillArgs? prefill;

  @override
  State<WerkaUnannouncedSupplierScreen> createState() =>
      _WerkaUnannouncedSupplierScreenState();
}

class _WerkaUnannouncedSupplierScreenState
    extends State<WerkaUnannouncedSupplierScreen> {
  final TextEditingController _qtyController = TextEditingController(text: '1');

  SupplierDirectoryEntry? _selectedSupplier;
  SupplierItem? _selectedItem;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefill != null) {
      final prefill = widget.prefill!;
      _selectedSupplier = SupplierDirectoryEntry(
        ref: prefill.supplierRef,
        name: prefill.supplierName,
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

  Future<void> _pickSupplier() async {
    final picked = await showModalBottomSheet<SupplierDirectoryEntry>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<SupplierDirectoryEntry>(
          title: context.l10n.selectSupplier,
          hintText: context.l10n.searchSupplier,
          loadPage: (query, offset, limit) => MobileApi.instance.werkaSuppliers(
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
      _selectedSupplier = picked;
      _selectedItem = null;
    });
  }

  Future<void> _pickItem() async {
    if (_selectedSupplier == null || _submitting) {
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
        return M3AsyncPickerSheet<SupplierItem>(
          title: context.l10n.selectItem,
          supportingText: _selectedSupplier!.name,
          hintText: context.l10n.searchItem,
          showScanIcon: true,
          pageSize: 100,
          loadPage: (query, offset, limit) =>
              MobileApi.instance.werkaSupplierItems(
            supplierRef: _selectedSupplier!.ref,
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
  }

  Future<void> _submit() async {
    if (_selectedSupplier == null || _selectedItem == null) {
      return;
    }
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.qtyRequired)),
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
                  context.l10n.confirmTitle,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  _selectedSupplier!.name,
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
                        child: Text(context.l10n.no),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(context.l10n.yes),
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
      final record = await MobileApi.instance.createWerkaUnannouncedDraft(
        supplierRef: _selectedSupplier!.ref,
        itemCode: _selectedItem!.code,
        qty: qty,
      );
      await SearchActivityStore.instance.recordItemSelection(record.itemCode);
      WerkaRuntimeStore.instance.recordCreatedPending(record);
      RefreshHub.instance.emit('werka');
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.werkaSuccess,
        (route) => route.isFirst,
        arguments: record,
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
    final canPickItem = _selectedSupplier != null && !_submitting;
    final canSubmit =
        _selectedSupplier != null && _selectedItem != null && !_submitting;

    return AppShell(
      title: context.l10n.unannouncedTitle,
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
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.supplierLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _pickSupplier,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectedSupplier?.name ??
                              context.l10n.selectSupplier,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedSupplier != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.itemLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: canPickItem ? _pickItem : null,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _selectedItem?.name ?? context.l10n.selectItem,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_selectedItem != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.amountLabel,
                      style: theme.textTheme.bodySmall,
                    ),
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      child: Text(
                        _submitting
                            ? context.l10n.pinSaving
                            : context.l10n.confirmTitle,
                      ),
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

class WerkaUnannouncedPrefillArgs {
  const WerkaUnannouncedPrefillArgs({
    required this.supplierRef,
    required this.supplierName,
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.uom,
  });

  final String supplierRef;
  final String supplierName;
  final String itemCode;
  final String itemName;
  final double qty;
  final String uom;
}
