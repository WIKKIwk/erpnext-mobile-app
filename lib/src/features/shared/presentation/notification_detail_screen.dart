import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/store/notification_unread_store.dart';
import '../../../core/session/session.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/navigation/native_back_button.dart';
import '../../supplier/presentation/widgets/supplier_dock.dart';
import '../../supplier/state/supplier_store.dart';
import '../../werka/presentation/widgets/werka_dock.dart';
import '../models/app_models.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

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
    final profile = AppSession.instance.profile;
    if (profile?.role == UserRole.customer &&
        widget.receiptID.startsWith('MAT-DN-')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.customerDetail,
          arguments: widget.receiptID,
        );
      });
      _future = Future<NotificationDetail>.value(
        const NotificationDetail(
          record: DispatchRecord(
            id: '',
            supplierRef: '',
            supplierName: '',
            itemCode: '',
            itemName: '',
            uom: '',
            sentQty: 0,
            acceptedQty: 0,
            amount: 0,
            currency: '',
            note: '',
            eventType: '',
            highlight: '',
            status: DispatchStatus.pending,
            createdLabel: '',
          ),
          comments: <NotificationComment>[],
        ),
      );
      _commentController.addListener(_handleCommentChanged);
      return;
    }
    _future = _loadAfterMarkSeen();
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

  Future<void> _markSeen() {
    return NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: [widget.receiptID],
    );
  }

  Future<NotificationDetail> _loadAfterMarkSeen() async {
    await _markSeen();
    return _load();
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

  Future<bool?> _showActionConfirmDialog({
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            backgroundColor: scheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF111111),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(cancelLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primaryContainer,
                              foregroundColor: scheme.onPrimaryContainer,
                            ),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: Text(confirmLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _reloadForAccountChange() async {
    _accountKey = _currentAccountKey();
    final future = _loadAfterMarkSeen();
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
    final future = _loadAfterMarkSeen();
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
      final bool? confirmed = await _showActionConfirmDialog(
        title: 'Tasdiqlash',
        message: 'Haqiqatan ham tasdiqlaysizmi?',
        cancelLabel: 'Yo‘q',
        confirmLabel: 'Ha',
      );
      if (confirmed != true) {
        return;
      }
    }

    setState(() => _sending = true);
    try {
      final current = await _future;
      final updated = await MobileApi.instance.supplierRespondUnannounced(
        receiptID: widget.receiptID,
        approve: approve,
        reason: reason,
      );
      SupplierStore.instance.recordUnannouncedDecision(
        fromStatus: current.record.status,
        toStatus: updated.record.status,
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
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    if (_accountKey != _currentAccountKey()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadForAccountChange();
      });
      return AppShell(
        leading: const _NotificationBackButton(),
        title: 'Batafsil',
        subtitle: '',
        bottom: role == UserRole.supplier
            ? const SupplierDock(activeTab: null)
            : role == UserRole.werka
                ? const WerkaDock(activeTab: null)
                : null,
        child: const Center(child: AppLoadingIndicator()),
      );
    }
    return AppShell(
      leading: const _NotificationBackButton(),
      title: 'Batafsil',
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: role == UserRole.supplier
          ? const SupplierDock(activeTab: null)
          : role == UserRole.werka
              ? const WerkaDock(activeTab: null)
              : null,
      child: FutureBuilder<NotificationDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return AppRetryState(
              onRetry: () async => _reload(),
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

          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
              children: [
                _NotificationSummaryCard(record: record),
                if (record.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NotificationNoteCard(note: record.note),
                ],
                if (isSupplierAckEvent &&
                    record.highlight.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NotificationNoteCard(
                    note: record.highlight,
                    emphasized: true,
                  ),
                ],
                if (canConfirm) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
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
                              final bool? confirmed =
                                  await _showActionConfirmDialog(
                                title: 'Tasdiqlash',
                                message:
                                    'Haqiqatan ham shu holatni tasdiqlaysizmi?',
                                cancelLabel: 'Yo‘q',
                                confirmLabel: 'Ha',
                              );
                              if (confirmed != true) {
                                return;
                              }
                              setState(() => _sending = true);
                              try {
                                final updated = await MobileApi.instance
                                    .addNotificationComment(
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
                    const Card.filled(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Hozircha izoh yo‘q.'),
                      ),
                    )
                  else
                    ...detail.comments.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.authorLabel,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.body,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.createdLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
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
                      child: FilledButton(
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

class _NotificationBackButton extends StatelessWidget {
  const _NotificationBackButton();

  @override
  Widget build(BuildContext context) {
    return NativeBackButtonSlot(
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

class _NotificationSummaryCard extends StatelessWidget {
  const _NotificationSummaryCard({
    required this.record,
  });

  final DispatchRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detailRows = <({String label, String value})>[
      (label: 'Supplier', value: record.supplierName),
      (label: 'Mahsulot', value: '${record.itemCode} • ${record.itemName}'),
      (
        label: 'Jo‘natilgan',
        value: '${record.sentQty.toStringAsFixed(2)} ${record.uom}',
      ),
      (
        label: 'Qabul qilingan',
        value: '${record.acceptedQty.toStringAsFixed(2)} ${record.uom}',
      ),
    ];
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
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
                    record.supplierName,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                _DetailStatusChip(label: _statusLabel(record.status)),
              ],
            ),
            const SizedBox(height: 18),
            Card.filled(
              margin: EdgeInsets.zero,
              color: scheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  for (int index = 0; index < detailRows.length; index++) ...[
                    _NotificationInfoRow(
                      label: detailRows[index].label,
                      value: detailRows[index].value,
                      isFirst: index == 0,
                      isLast: index == detailRows.length - 1,
                    ),
                    if (index != detailRows.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationNoteCard extends StatelessWidget {
  const _NotificationNoteCard({
    required this.note,
    this.emphasized = false,
  });

  final String note;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color:
          emphasized ? scheme.secondaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          note,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: emphasized ? scheme.onSecondaryContainer : null,
              ),
        ),
      ),
    );
  }
}

class _NotificationInfoRow extends StatelessWidget {
  const _NotificationInfoRow({
    required this.label,
    required this.value,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 24 : 0),
          topRight: Radius.circular(isFirst ? 24 : 0),
          bottomLeft: Radius.circular(isLast ? 24 : 0),
          bottomRight: Radius.circular(isLast ? 24 : 0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({
    required this.label,
  });

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
