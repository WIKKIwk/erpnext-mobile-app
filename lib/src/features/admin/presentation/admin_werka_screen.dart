import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminWerkaScreen extends StatefulWidget {
  const AdminWerkaScreen({super.key});

  @override
  State<AdminWerkaScreen> createState() => _AdminWerkaScreenState();
}

class _AdminWerkaScreenState extends State<AdminWerkaScreen> {
  late Future<AdminSettings> _future;
  final phone = TextEditingController();
  final name = TextEditingController();
  String werkaCode = '';
  int _retryAfterSec = 0;
  bool saving = false;
  bool regenerating = false;
  bool hydrated = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.adminSettings();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    phone.dispose();
    name.dispose();
    super.dispose();
  }

  void _fill(AdminSettings settings) {
    if (hydrated) {
      return;
    }
    phone.text = settings.werkaPhone;
    name.text = settings.werkaName;
    werkaCode = settings.werkaCode;
    _setRetryAfter(settings.werkaCodeRetryAfterSec);
    hydrated = true;
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

  Future<void> _save(AdminSettings current) async {
    setState(() => saving = true);
    try {
      final updated = await MobileApi.instance.updateAdminSettings(
        AdminSettings(
          erpUrl: current.erpUrl,
          erpApiKey: current.erpApiKey,
          erpApiSecret: current.erpApiSecret,
          defaultTargetWarehouse: current.defaultTargetWarehouse,
          defaultUom: current.defaultUom,
          werkaPhone: phone.text.trim(),
          werkaName: name.text.trim(),
          werkaCode: werkaCode,
          werkaCodeLocked: current.werkaCodeLocked,
          werkaCodeRetryAfterSec: _retryAfterSec,
          adminPhone: current.adminPhone,
          adminName: current.adminName,
        ),
      );
      setState(() {
        werkaCode = updated.werkaCode;
      });
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => regenerating = true);
    try {
      final updated = await MobileApi.instance.adminRegenerateWerkaCode();
      setState(() {
        werkaCode = updated.werkaCode;
      });
      _setRetryAfter(updated.werkaCodeRetryAfterSec);
    } finally {
      if (mounted) {
        setState(() => regenerating = false);
      }
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: werkaCode));
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
        child: FutureBuilder<AdminSettings>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                _AdminWerkaHeader(theme: theme),
                const SizedBox(height: 20),
                _AdminWerkaNoticeCard(
                child: Text('Werka yuklanmadi: ${snapshot.error}'),
                ),
              ],
            );
          }
          final current = snapshot.data!;
          _fill(current);
          final scheme = theme.colorScheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              _AdminWerkaHeader(theme: theme),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.text.trim().isEmpty ? 'Werka' : name.text.trim(),
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            phone.text.trim().isEmpty
                                ? 'Telefon raqam berilmagan'
                                : phone.text.trim(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Code', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          _AdminWerkaField(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    werkaCode,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      werkaCode.trim().isEmpty ? null : _copyCode,
                                  icon: const Icon(Icons.content_copy_outlined),
                                ),
                                IconButton(
                                  onPressed: regenerating || _retryAfterSec > 0
                                      ? null
                                      : _regenerate,
                                  icon: regenerating
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
                            const SizedBox(height: 12),
                            Text(
                              'Keyingi code uchun $_retryAfterSec soniya kuting.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Text('Werka name', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          _AdminWerkaField(
                            child: TextField(
                              controller: name,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Werka',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text('Werka phone', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 6),
                          _AdminWerkaField(
                            child: TextField(
                              controller: phone,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '+998901234567',
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: saving ? null : () => _save(current),
                              child: Text(
                                saving ? 'Saqlanmoqda...' : 'Saqlash',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _AdminWerkaHeader extends StatelessWidget {
  const _AdminWerkaHeader({required this.theme});

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
            'Werka',
            style: theme.textTheme.headlineMedium,
          ),
        ),
      ],
    );
  }
}

class _AdminWerkaField extends StatelessWidget {
  const _AdminWerkaField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _AdminWerkaNoticeCard extends StatelessWidget {
  const _AdminWerkaNoticeCard({required this.child});

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
