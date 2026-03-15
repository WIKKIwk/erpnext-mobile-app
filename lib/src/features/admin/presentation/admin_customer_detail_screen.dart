import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminCustomerDetailScreen extends StatefulWidget {
  const AdminCustomerDetailScreen({
    super.key,
    required this.customerRef,
    this.detailLoader,
  });

  final String customerRef;
  final Future<AdminCustomerDetail> Function(String ref)? detailLoader;

  @override
  State<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen> {
  AdminCustomerDetail? _detail;
  Object? _loadError;
  bool _loading = true;
  bool _savingPhone = false;
  bool _regeneratingCode = false;
  bool _removing = false;
  bool _addingItem = false;
  int _retryAfterSec = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<AdminCustomerDetail> _loadDetail() async {
    final loadDetail =
        widget.detailLoader ?? MobileApi.instance.adminCustomerDetail;
    final detail = await loadDetail(widget.customerRef).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Customer detail timeout'),
    );
    _setRetryAfter(detail.codeRetryAfterSec);
    return detail;
  }

  void _setRetryAfter(int seconds) {
    _retryTimer?.cancel();
    _retryAfterSec = seconds > 0 ? seconds : 0;
    if (_retryAfterSec <= 0) {
      return;
    }
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _retryAfterSec <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() => _retryAfterSec = 0);
        }
        return;
      }
      setState(() => _retryAfterSec -= 1);
    });
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail = await _loadDetail();
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = null;
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _addPhone(AdminCustomerDetail detail) async {
    final controller = TextEditingController(text: detail.phone);
    final phone = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Telefon raqam qo‘shish'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '+998901234567',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Saqlash'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (phone == null || phone.trim().isEmpty) {
      return;
    }

    setState(() => _savingPhone = true);
    try {
      final updated = await MobileApi.instance.adminUpdateCustomerPhone(
        ref: detail.ref,
        phone: phone,
      );
      if (!mounted) {
        return;
      }
      _setRetryAfter(updated.codeRetryAfterSec);
      setState(() => _detail = updated);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Telefon saqlanmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingPhone = false);
      }
    }
  }

  Future<void> _regenerateCode() async {
    setState(() => _regeneratingCode = true);
    try {
      final updated = await MobileApi.instance
          .adminRegenerateCustomerCode(widget.customerRef);
      if (!mounted) {
        return;
      }
      _setRetryAfter(updated.codeRetryAfterSec);
      setState(() => _detail = updated);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code yangilanmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _regeneratingCode = false);
      }
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code nusxalandi')),
    );
  }

  Future<void> _removeCustomer() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Customerni chiqarish'),
          content: const Text(
            'Bu customer admin panel ro‘yxatidan chiqariladi va kira olmaydi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Chiqarish'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _removing = true);
    try {
      await MobileApi.instance.adminRemoveCustomer(widget.customerRef);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Customer chiqarilmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _removing = false);
      }
    }
  }

  Future<void> _addItem() async {
    final detail = _detail;
    if (detail == null) {
      return;
    }

    final allItems = await MobileApi.instance.adminItems();
    if (!mounted) {
      return;
    }
    final assignedCodes = detail.assignedItems.map((item) => item.code).toSet();
    final availableItems =
        allItems.where((item) => !assignedCodes.contains(item.code)).toList();
    if (availableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biriktirilmagan mahsulot topilmadi')),
      );
      return;
    }

    final SupplierItem? selected = await showModalBottomSheet<SupplierItem>(
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
                      'Mahsulot qo‘shish',
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
                detail.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = availableItems[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      tileColor: scheme.surfaceContainerHighest,
                      title: Text(item.name),
                      subtitle: Text(item.code),
                      trailing: const Icon(Icons.add_rounded),
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
    if (selected == null) {
      return;
    }

    setState(() => _addingItem = true);
    try {
      final updated = await MobileApi.instance.adminAssignCustomerItem(
        ref: widget.customerRef,
        itemCode: selected.code,
      );
      if (!mounted) {
        return;
      }
      setState(() => _detail = updated);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mahsulot biriktirilmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _addingItem = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AdminCustomerDetail detail = _detail ??
        AdminCustomerDetail(
          ref: widget.customerRef,
          name: _loading ? 'Yuklanmoqda...' : 'Customer',
          phone: _loading ? 'Yuklanmoqda...' : 'Kiritilmagan',
          code: _loading ? 'Yuklanmoqda...' : 'Hali generatsiya qilinmagan',
          codeLocked: false,
          codeRetryAfterSec: _retryAfterSec,
          assignedItems: const [],
        );

    return Scaffold(
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Row(
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
                    'Customer',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AdminCustomerDetailCard(
              detail: detail,
              statusLabel: _loading
                  ? 'Yuklanmoqda'
                  : _loadError != null
                      ? 'Xato'
                      : _detail == null
                          ? 'Bo‘sh'
                          : 'Tayyor',
              savingPhone: _savingPhone || _loading,
              regeneratingCode: _regeneratingCode,
              removing: _removing,
              addingItem: _addingItem,
              onAddPhone: _addPhone,
              onAddItem: _addItem,
              onRegenerateCode: _regenerateCode,
              onCopyCode: _copyCode,
              onRemove: _removeCustomer,
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 12),
              _AdminCustomerNoticeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Customer detail yuklanmadi',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('$_loadError'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminCustomerDetailCard extends StatelessWidget {
  const _AdminCustomerDetailCard({
    required this.detail,
    required this.statusLabel,
    required this.savingPhone,
    required this.regeneratingCode,
    required this.removing,
    required this.addingItem,
    required this.onAddPhone,
    required this.onAddItem,
    required this.onRegenerateCode,
    required this.onCopyCode,
    required this.onRemove,
  });

  final AdminCustomerDetail detail;
  final String statusLabel;
  final bool savingPhone;
  final bool regeneratingCode;
  final bool removing;
  final bool addingItem;
  final Future<void> Function(AdminCustomerDetail detail) onAddPhone;
  final Future<void> Function() onAddItem;
  final Future<void> Function() onRegenerateCode;
  final Future<void> Function(String code) onCopyCode;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card.filled(
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    detail.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                _StatusChip(label: statusLabel),
              ],
            ),
            const SizedBox(height: 18),
            Text('Ref', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            _DetailField(value: detail.ref),
            const SizedBox(height: 14),
            Text('Telefon', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            _DetailField(value: detail.phone),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: savingPhone ? null : () => onAddPhone(detail),
                child: Text(savingPhone ? 'Saqlanmoqda...' : 'Telefonni yangilash'),
              ),
            ),
            const SizedBox(height: 14),
            Text('Code', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            _DetailField(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      detail.code.trim().isEmpty
                          ? 'Hali generatsiya qilinmagan'
                          : detail.code,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (detail.code.trim().isNotEmpty)
                    IconButton(
                      onPressed: () => onCopyCode(detail.code),
                      icon: const Icon(Icons.content_copy_outlined),
                    ),
                  IconButton(
                    onPressed: regeneratingCode || detail.codeLocked
                        ? null
                        : onRegenerateCode,
                    icon: regeneratingCode
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            if (detail.codeRetryAfterSec > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Keyingi code uchun ${detail.codeRetryAfterSec} soniya kuting.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text('Biriktirilgan mahsulotlar', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              detail.assignedItems.isEmpty
                  ? 'Hozircha mahsulot biriktirilmagan.'
                  : '${detail.assignedItems.length} ta mahsulot biriktirilgan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: detail.assignedItems.isEmpty
                        ? null
                        : () => _showAssignedItemsSheet(context, detail),
                    child: const Text('Ko‘rish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: addingItem ? null : onAddItem,
                    child: Text(addingItem ? 'Qo‘shilmoqda...' : 'Qo‘shish'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: removing ? null : onRemove,
                child: Text(removing ? 'Chiqarilmoqda...' : 'Tizimdan chiqarish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAssignedItemsSheet(
  BuildContext context,
  AdminCustomerDetail detail,
) async {
  await showModalBottomSheet<void>(
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
                    'Biriktirilgan mahsulotlar',
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
              detail.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: detail.assignedItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = detail.assignedItems[index];
                  return _DetailField(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.code,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _AdminCustomerNoticeCard extends StatelessWidget {
  const _AdminCustomerNoticeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
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
        child: child,
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    this.value,
    this.child,
  });

  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child ??
          Text(
            (value ?? '').trim().isEmpty ? 'Kiritilmagan' : value!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
