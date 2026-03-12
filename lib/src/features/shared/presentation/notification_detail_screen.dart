import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../supplier/presentation/widgets/supplier_dock.dart';
import '../../werka/presentation/widgets/werka_dock.dart';
import '../models/app_models.dart';
import 'package:flutter/material.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({
    super.key,
    required this.receiptID,
  });

  final String receiptID;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  late Future<NotificationDetail> _future;
  final TextEditingController _commentController = TextEditingController();
  bool _sending = false;
  bool _hasCommentText = false;
  String _accountKey = '';

  @override
  void initState() {
    super.initState();
    _accountKey = _currentAccountKey();
    _future = _load();
    _commentController.addListener(_handleCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_handleCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _handleCommentChanged() {
    final hasText = _commentController.text.trim().isNotEmpty;
    if (hasText == _hasCommentText || !mounted) {
      return;
    }
    setState(() => _hasCommentText = hasText);
  }

  Future<NotificationDetail> _load() {
    return MobileApi.instance.notificationDetail(widget.receiptID);
  }

  String _currentAccountKey() {
    final profile = AppSession.instance.profile;
    if (profile == null) {
      return '';
    }
    return '${profile.role.name}:${profile.ref}';
  }

  Future<void> _reloadForAccountChange() async {
    _accountKey = _currentAccountKey();
    final future = _load();
    if (!mounted) {
      return;
    }
    setState(() {
      _future = future;
      _hasCommentText = false;
      _commentController.clear();
    });
    await future;
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _sendComment() async {
    final message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      final updated = await MobileApi.instance.addNotificationComment(
        receiptID: widget.receiptID,
        message: message,
      );
      _commentController.clear();
      setState(() {
        _hasCommentText = false;
        _future = Future<NotificationDetail>.value(updated);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final text = '$error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text.contains('forbidden')
                ? 'Bu receipt sizga tegishli emas.'
                : 'Comment yuborilmadi: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _respondWerkaUnannounced(bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    String reason = '';
    if (!approve) {
      final controller = TextEditingController();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Rad etish'),
            content: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Sabab (ixtiyoriy)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Yo‘q'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Rad etish'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
      reason = controller.text.trim();
    } else {
      final bool? first = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Tasdiqlash'),
            content: const Text('Haqiqatan ham tasdiqlaysizmi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Yo‘q'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ha'),
              ),
            ],
          );
        },
      );
      if (first != true) {
        return;
      }
      if (!mounted) return;
      final bool? second = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Yakuniy tasdiq'),
            content: const Text('Draft submit bo‘ladi. Davom etasizmi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Yo‘q'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ha'),
              ),
            ],
          );
        },
      );
      if (second != true) {
        return;
      }
    }

    setState(() => _sending = true);
    try {
      final updated = await MobileApi.instance.supplierRespondUnannounced(
        receiptID: widget.receiptID,
        approve: approve,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _future = Future<NotificationDetail>.value(updated);
      });
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Javob yuborilmadi: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AppSession.instance.profile?.role;
    final textTheme = Theme.of(context).textTheme;
    if (_accountKey != _currentAccountKey()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadForAccountChange();
      });
      return AppShell(
        leading: AppShellIconAction(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: 'Batafsil',
        subtitle: '',
        bottom: role == UserRole.supplier
            ? const SupplierDock(activeTab: null)
            : role == UserRole.werka
                ? const WerkaDock(activeTab: null)
                : null,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: 'Batafsil',
      subtitle: '',
      bottom: role == UserRole.supplier
          ? const SupplierDock(activeTab: null)
          : role == UserRole.werka
              ? const WerkaDock(activeTab: null)
              : null,
      child: FutureBuilder<NotificationDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Detail yuklanmadi: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reload,
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            );
          }

          final detail = snapshot.data!;
          final record = detail.record;
          final currentProfile = AppSession.instance.profile;
          final belongsToCurrentSupplier = role != UserRole.supplier ||
              currentProfile == null ||
              record.supplierRef.trim().isEmpty ||
              record.supplierRef.trim() == currentProfile.ref.trim();
          if (!belongsToCurrentSupplier) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              Navigator.of(context).maybePop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu receipt sizga tegishli emas.'),
                ),
              );
            });
            return const SizedBox.shrink();
          }
          final canConfirm = role == UserRole.werka &&
              record.eventType.isEmpty &&
              (record.status == DispatchStatus.pending ||
                  record.status == DispatchStatus.draft);
          final canRespondWerkaUnannounced = role == UserRole.supplier &&
              record.eventType == 'werka_unannounced_pending';
          final isSupplierAckEvent = record.eventType == 'supplier_ack';
          final supplierAcknowledged = detail.comments.any(
            (item) =>
                item.authorLabel.startsWith('Supplier') &&
                item.body.toLowerCase().contains('tasdiqlayman'),
          );
          final canAcknowledge = role == UserRole.supplier &&
              !canRespondWerkaUnannounced &&
              !supplierAcknowledged &&
              (record.status == DispatchStatus.partial ||
                  record.status == DispatchStatus.rejected ||
                  record.status == DispatchStatus.cancelled ||
                  record.note.trim().isNotEmpty);
          final canComment = record.note.trim().isNotEmpty ||
              record.status == DispatchStatus.partial ||
              record.status == DispatchStatus.rejected ||
              record.status == DispatchStatus.cancelled;
          final canWriteIssueComment = canComment &&
              !canRespondWerkaUnannounced &&
              !isSupplierAckEvent &&
              !(role == UserRole.supplier && supplierAcknowledged);

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Text.rich(
                  TextSpan(
                    style: textTheme.titleMedium,
                    children: [
                      const TextSpan(text: 'Supplier: '),
                      TextSpan(
                        text: record.supplierName,
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: textTheme.titleMedium,
                    children: [
                      const TextSpan(text: 'Mahsulot: '),
                      TextSpan(
                        text: '${record.itemCode} • ${record.itemName}',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: textTheme.titleMedium,
                    children: [
                      const TextSpan(text: 'Jo‘natilgan: '),
                      TextSpan(
                        text:
                            '${record.sentQty.toStringAsFixed(2)} ${record.uom}',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: textTheme.titleMedium,
                    children: [
                      const TextSpan(text: 'Qabul qilingan: '),
                      TextSpan(
                        text:
                            '${record.acceptedQty.toStringAsFixed(2)} ${record.uom}',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: textTheme.titleMedium,
                    children: [
                      const TextSpan(text: 'Status: '),
                      TextSpan(
                        text: _statusLabel(record.status),
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                if (record.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SoftCard(
                    child: Text(record.note),
                  ),
                ],
                if (isSupplierAckEvent && record.highlight.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    record.highlight,
                    style: textTheme.headlineMedium,
                  ),
                ],
                if (canConfirm) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.werkaDetail,
                        arguments: record,
                      ),
                      child: const Text('Qabul qilishga o‘tish'),
                    ),
                  ),
                ],
                if (canRespondWerkaUnannounced) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _sending
                              ? null
                              : () => _respondWerkaUnannounced(false),
                          child: const Text('Rad etaman'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _sending
                              ? null
                              : () => _respondWerkaUnannounced(true),
                          child: Text(
                            _sending ? 'Yuborilmoqda...' : 'Tasdiqlayman',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (canAcknowledge) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _sending
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Tasdiqlash'),
                                    content: const Text(
                                      'Haqiqatan ham shu holatni tasdiqlaysizmi?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Yo‘q'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Ha'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (confirmed != true) {
                                return;
                              }
                              setState(() => _sending = true);
                              try {
                                final updated =
                                    await MobileApi.instance.addNotificationComment(
                                  receiptID: widget.receiptID,
                                  message:
                                      'Tasdiqlayman, shu holat bo‘lganini ko‘rdim.',
                                );
                                if (!mounted) {
                                  return;
                                }
                                setState(() {
                                  _future = Future<NotificationDetail>.value(
                                    updated,
                                  );
                                });
                              } catch (error) {
                                if (!mounted) {
                                  return;
                                }
                                final text = '$error';
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      text.contains('forbidden')
                                          ? 'Bu receipt sizga tegishli emas.'
                                          : 'Tasdiqlash yuborilmadi: $error',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _sending = false);
                                }
                              }
                            },
                      child: Text(
                        _sending ? 'Yuborilmoqda...' : 'Tasdiqlayman',
                      ),
                    ),
                  ),
                ],
                if (canWriteIssueComment) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Izohlar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (detail.comments.isEmpty)
                    const SoftCard(
                      child: Text('Hozircha izoh yo‘q.'),
                    )
                  else
                    ...detail.comments.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.authorLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.body,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.createdLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Izoh yozing',
                    ),
                  ),
                  if (_hasCommentText) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _sendComment,
                        child: Text(
                          _sending ? 'Yuborilmoqda...' : 'Comment yuborish',
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _statusLabel(DispatchStatus status) {
  switch (status) {
    case DispatchStatus.pending:
      return 'Kutilmoqda';
    case DispatchStatus.accepted:
      return 'Qabul qilindi';
    case DispatchStatus.partial:
      return 'Qisman qabul';
    case DispatchStatus.rejected:
      return 'Rad etildi';
    case DispatchStatus.cancelled:
      return 'Bekor qilindi';
    case DispatchStatus.draft:
      return 'Draft';
  }
}
