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
  late Future<AdminCustomerDetail> _future;
  bool _savingPhone = false;
  bool _regeneratingCode = false;
  int _retryAfterSec = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _future = _loadDetail();
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
    final future = _loadDetail();
    setState(() => _future = future);
    await future;
  }

  Future<void> _addPhone(AdminCustomerDetail detail) async {
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
      final updated = await MobileApi.instance.adminUpdateCustomerPhone(
        ref: detail.ref,
        phone: phone,
      );
      setState(() {
        _future = Future<AdminCustomerDetail>.value(updated);
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
          .adminRegenerateCustomerCode(widget.customerRef);
      _setRetryAfter(updated.codeRetryAfterSec);
      setState(() {
        _future = Future<AdminCustomerDetail>.value(updated);
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.shellStart(context),
      body: SafeArea(
        child: FutureBuilder<AdminCustomerDetail>(
          future: _future,
          builder: (context, snapshot) {
            final stateLabel = snapshot.connectionState != ConnectionState.done
                ? 'Yuklanmoqda'
                : snapshot.hasError
                    ? 'Xato'
                    : snapshot.hasData
                        ? 'Tayyor'
                        : 'Bo‘sh';
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
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
                _AdminCustomerInfoCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ref: ${widget.customerRef}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          stateLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState != ConnectionState.done)
                  _AdminCustomerInfoCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator.adaptive(),
                        const SizedBox(height: 14),
                        Text(
                          'Customer detail yuklanmoqda...',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                else if (snapshot.hasError)
                  _AdminCustomerInfoCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Customer detail yuklanmadi: ${snapshot.error}'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Qayta urinish'),
                        ),
                      ],
                    ),
                  )
                else if (!snapshot.hasData)
                  _AdminCustomerInfoCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Customer detail topilmadi.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Qayta urinish'),
                        ),
                      ],
                    ),
                  )
                else
                  _AdminCustomerDetailCard(
                    detail: snapshot.data!,
                    savingPhone: _savingPhone,
                    regeneratingCode: _regeneratingCode,
                    retryAfterSec: _retryAfterSec,
                    onAddPhone: _addPhone,
                    onRegenerateCode: _regenerateCode,
                    onCopyCode: _copyCode,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminCustomerInfoCard extends StatelessWidget {
  const _AdminCustomerInfoCard({required this.child});

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

class _AdminCustomerDetailCard extends StatelessWidget {
  const _AdminCustomerDetailCard({
    required this.detail,
    required this.savingPhone,
    required this.regeneratingCode,
    required this.retryAfterSec,
    required this.onAddPhone,
    required this.onRegenerateCode,
    required this.onCopyCode,
  });

  final AdminCustomerDetail detail;
  final bool savingPhone;
  final bool regeneratingCode;
  final int retryAfterSec;
  final Future<void> Function(AdminCustomerDetail detail) onAddPhone;
  final Future<void> Function() onRegenerateCode;
  final Future<void> Function(String code) onCopyCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasPhone = detail.phone.trim().isNotEmpty;

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
            Text(
              detail.name,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            Text('Ref', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            _AdminCustomerField(
              child: Text(
                detail.ref,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Telefon',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: savingPhone ? null : () => onAddPhone(detail),
                  child: Text(hasPhone ? 'Yangilash' : 'Qo‘shish'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _AdminCustomerField(
              child: Text(
                hasPhone ? detail.phone : 'Kiritilmagan',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            Text('Code', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            _AdminCustomerField(
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: regeneratingCode || retryAfterSec > 0
                    ? null
                    : onRegenerateCode,
                child: Text(
                  regeneratingCode
                      ? 'Generatsiya qilinmoqda...'
                      : 'Code generatsiya qilish',
                ),
              ),
            ),
            if (retryAfterSec > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Keyingi code uchun $retryAfterSec soniyadan keyin qayta urining.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminCustomerField extends StatelessWidget {
  const _AdminCustomerField({
    this.child,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
