import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/m3_confirm_dialog.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminSupplierDetailScreen extends StatefulWidget {
  const AdminSupplierDetailScreen({
    super.key,
    required this.supplierRef,
  });

  final String supplierRef;

  @override
  State<AdminSupplierDetailScreen> createState() =>
      _AdminSupplierDetailScreenState();
}

class _AdminSupplierDetailScreenState extends State<AdminSupplierDetailScreen> {
  late Future<AdminSupplierDetail> _detailFuture;
  bool _savingStatus = false;
  bool _savingPhone = false;
  bool _regeneratingCode = false;
  bool _removing = false;
  bool _changed = false;
  int _retryAfterSec = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<AdminSupplierDetail> _loadDetail() async {
    final detail =
        await MobileApi.instance.adminSupplierDetail(widget.supplierRef);
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
    final future = _loadDetail();
    setState(() {
      _detailFuture = future;
    });
    await future;
  }

  Future<void> _toggleBlocked(AdminSupplierDetail detail) async {
    setState(() => _savingStatus = true);
    try {
      final updated = await MobileApi.instance.adminSetSupplierBlocked(
        ref: detail.ref,
        blocked: !detail.blocked,
      );
      _changed = true;
      setState(() {
        _detailFuture = Future<AdminSupplierDetail>.value(updated);
      });
    } finally {
      if (mounted) {
        setState(() => _savingStatus = false);
      }
    }
  }

  Future<void> _addPhone(AdminSupplierDetail detail) async {
    final controller = TextEditingController();
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
      final updated = await MobileApi.instance.adminUpdateSupplierPhone(
        ref: detail.ref,
        phone: phone,
      );
      _changed = true;
      setState(() {
        _detailFuture = Future<AdminSupplierDetail>.value(updated);
      });
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
          .adminRegenerateSupplierCode(widget.supplierRef);
      _setRetryAfter(updated.codeRetryAfterSec);
      _changed = true;
      setState(() {
        _detailFuture = Future<AdminSupplierDetail>.value(updated);
      });
    } finally {
      if (mounted) {
        setState(() => _regeneratingCode = false);
      }
    }
  }

  Future<void> _removeSupplier() async {
    final bool? confirmed = await showM3ConfirmDialog(
      context: context,
      title: 'Supplierni chiqarish',
      message:
          'Bu supplier admin panel ro‘yxatidan chiqariladi va kira olmaydi.',
      cancelLabel: 'Bekor qilish',
      confirmLabel: 'Chiqarish',
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }

    setState(() => _removing = true);
    try {
      await MobileApi.instance.adminRemoveSupplier(widget.supplierRef);
      _changed = true;
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _removing = false);
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_changed);
      },
      child: AppShell(
        leading: AppShellIconAction(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(_changed),
        ),
        title: 'Supplier',
        subtitle: '',
        contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
        bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
        child: FutureBuilder<AdminSupplierDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: AppRetryState(onRetry: _reload),
            );
          }

          final detail = snapshot.data!;
          final hasPhone = detail.phone.trim().isNotEmpty;
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              SmoothAppear(
                delay: const Duration(milliseconds: 20),
                child: Card.filled(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
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
                            if (detail.blocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Blocked',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onErrorContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasPhone ? detail.phone : 'Telefon raqam berilmagan',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        if (!hasPhone) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            width: 32,
                            child: OutlinedButton(
                              onPressed:
                                  _savingPhone ? null : () => _addPhone(detail),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _savingPhone
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded, size: 18),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text('Code', style: theme.textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  detail.code,
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _copyCode(detail.code),
                                icon: const Icon(Icons.content_copy_outlined),
                              ),
                              IconButton(
                                onPressed:
                                    _regeneratingCode || _retryAfterSec > 0
                                        ? null
                                        : _regenerateCode,
                                icon: _regeneratingCode
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                              ),
                            ],
                          ),
                        ),
                        if (_retryAfterSec > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Keyingi code uchun $_retryAfterSec soniyadan keyin qayta urining.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _savingStatus
                                ? null
                                : () => _toggleBlocked(detail),
                            child: Text(
                              _savingStatus
                                  ? 'Saqlanmoqda...'
                                  : detail.blocked
                                      ? 'Unblock qilish'
                                      : 'Block qilish',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SmoothAppear(
                delay: const Duration(milliseconds: 60),
                child: Card.filled(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biriktirilgan mahsulotlar',
                          style: theme.textTheme.titleLarge,
                        ),
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
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                  AppRoutes.adminSupplierItemsView,
                                  arguments: widget.supplierRef,
                                ),
                                child: const Text('Ko‘rish'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                  AppRoutes.adminSupplierItemsAdd,
                                  arguments: widget.supplierRef,
                                ),
                                child: const Text('Qo‘shish'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _removing ? null : _removeSupplier,
                  child: Text(
                    _removing ? 'Chiqarilmoqda...' : 'Tizimdan chiqarish',
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
          },
        ),
      ),
    );
  }
}
