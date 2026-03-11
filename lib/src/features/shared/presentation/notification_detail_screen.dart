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

  @override
  void initState() {
    super.initState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment yuborilmadi: $error')),
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
          final canConfirm = role == UserRole.werka && record.status == DispatchStatus.pending;
          final canComment = record.note.trim().isNotEmpty ||
              record.status == DispatchStatus.partial ||
              record.status == DispatchStatus.rejected ||
              record.status == DispatchStatus.cancelled;

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Text('Supplier: ${record.supplierName}'),
                const SizedBox(height: 8),
                Text('Mahsulot: ${record.itemCode} • ${record.itemName}'),
                const SizedBox(height: 8),
                Text('Jo‘natilgan: ${record.sentQty.toStringAsFixed(2)} ${record.uom}'),
                const SizedBox(height: 8),
                Text('Qabul qilingan: ${record.acceptedQty.toStringAsFixed(2)} ${record.uom}'),
                const SizedBox(height: 8),
                Text('Status: ${_statusLabel(record.status)}'),
                if (record.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SoftCard(
                    child: Text(record.note),
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
                if (canComment) ...[
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
