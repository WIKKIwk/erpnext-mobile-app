import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'dart:async';

import 'package:flutter/material.dart';

class WerkaUnannouncedSupplierScreen extends StatefulWidget {
  const WerkaUnannouncedSupplierScreen({super.key});

  @override
  State<WerkaUnannouncedSupplierScreen> createState() =>
      _WerkaUnannouncedSupplierScreenState();
}

class _WerkaUnannouncedSupplierScreenState
    extends State<WerkaUnannouncedSupplierScreen> {
  late Future<List<SupplierDirectoryEntry>> _suppliersFuture;
  final TextEditingController _qtyController = TextEditingController(text: '1');

  SupplierDirectoryEntry? _selectedSupplier;
  SupplierItem? _selectedItem;
  List<SupplierItem> _supplierItems = const <SupplierItem>[];
  bool _loadingItems = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _suppliersFuture = MobileApi.instance.werkaSuppliers();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _reloadSuppliers() async {
    final future = MobileApi.instance.werkaSuppliers();
    setState(() => _suppliersFuture = future);
    await future;
  }

  Future<void> _pickSupplier() async {
    final suppliers = await _suppliersFuture;
    if (!mounted) {
      return;
    }
    final picked = await showModalBottomSheet<SupplierDirectoryEntry>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Supplier tanlang',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = suppliers[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: scheme.surfaceContainerHighest,
                      title: Text(item.name),
                      subtitle: Text(item.phone),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedSupplier = picked;
      _selectedItem = null;
      _supplierItems = const <SupplierItem>[];
      _loadingItems = true;
    });
    try {
      final items = await MobileApi.instance.werkaSupplierItems(
        supplierRef: picked.ref,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _supplierItems = items;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingItems = false);
      }
    }
  }

  Future<void> _pickItem() async {
    if (_selectedSupplier == null || _loadingItems) {
      return;
    }
    if (_supplierItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplierga biriktirilgan mol topilmadi')),
      );
      return;
    }

    final picked = await showModalBottomSheet<SupplierItem>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mol tanlang',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _selectedSupplier!.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _supplierItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _supplierItems[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: scheme.surfaceContainerHighest,
                      title: Text(item.name),
                      subtitle: Text(item.code),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
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
      final record = await MobileApi.instance.createWerkaUnannouncedDraft(
        supplierRef: _selectedSupplier!.ref,
        itemCode: _selectedItem!.code,
        qty: qty,
      );
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
    final scheme = theme.colorScheme;
    final canPickItem = _selectedSupplier != null && !_loadingItems;
    final canSubmit = _selectedSupplier != null &&
        _selectedItem != null &&
        !_submitting &&
        !_loadingItems;

    return Scaffold(
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        child: FutureBuilder<List<SupplierDirectoryEntry>>(
          future: _suppliersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _WerkaUnannouncedHeader(theme: theme),
                  const SizedBox(height: 20),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Supplierlar yuklanmadi: ${snapshot.error}'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reloadSuppliers,
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
                _WerkaUnannouncedHeader(theme: theme),
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
                          'Aytilmagan mol',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 18),
                        Text('Supplier', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _pickSupplier,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _selectedSupplier?.name ?? 'Supplier tanlang',
                              ),
                            ),
                          ),
                        ),
                        if (_selectedSupplier != null) ...[
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
          padding: EdgeInsets.fromLTRB(20, 0, 24, 0),
          child: WerkaDock(activeTab: null),
        ),
      ),
    );
  }
}

class _WerkaUnannouncedHeader extends StatelessWidget {
  const _WerkaUnannouncedHeader({required this.theme});

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
            'Aytilmagan mol',
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ],
    );
  }
}
