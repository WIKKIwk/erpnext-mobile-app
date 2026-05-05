import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/feedback/m3_confirm_dialog.dart';
import 'widgets/customer_dock.dart';
import '../../shared/models/app_models.dart';
import '../state/customer_store.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class CustomerDeliveryDetailScreen extends StatefulWidget {
  const CustomerDeliveryDetailScreen({
    super.key,
    required this.deliveryNoteID,
  });

  final String deliveryNoteID;

  @override
  State<CustomerDeliveryDetailScreen> createState() =>
      _CustomerDeliveryDetailScreenState();
}

class _CustomerDeliveryDetailScreenState
    extends State<CustomerDeliveryDetailScreen> {
  late Future<CustomerDeliveryDetail> _future;
  bool _submitting = false;
  static const int _minRejectCommentLength = 3;

  List<String> _rejectReasons(AppLocalizations l10n) => <String>[
        l10n.rejectReasonDefective,
        l10n.rejectReasonWrongItem,
        l10n.rejectReasonQtyMismatch,
      ];

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.customerDeliveryDetail(widget.deliveryNoteID);
  }

  Future<void> _reload() async {
    final future =
        MobileApi.instance.customerDeliveryDetail(widget.deliveryNoteID);
    setState(() => _future = future);
    await future;
  }

  Future<void> _openDiscussion() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.notificationDetail,
      arguments: customerDeliveryResultEventId(widget.deliveryNoteID),
    );
    if (!mounted) return;
    await _reload();
  }

  Future<void> _sendResponse({
    bool? approve,
    CustomerDeliveryResponseMode? mode,
    double? acceptedQty,
    double? returnedQty,
    String reason = '',
    String comment = '',
  }) async {
    final current = await _future;
    setState(() => _submitting = true);
    try {
      final updated = await MobileApi.instance.customerRespondDelivery(
        deliveryNoteID: widget.deliveryNoteID,
        approve: approve,
        mode: mode,
        acceptedQty: acceptedQty,
        returnedQty: returnedQty,
        reason: reason,
        comment: comment,
      );
      if (!mounted) return;
      setState(() {
        _future = Future<CustomerDeliveryDetail>.value(updated);
      });
      CustomerStore.instance.applyDetailTransition(
        before: current.record,
        after: updated.record,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RefreshHub.instance.emit('customer');
      });
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.responseSendFailed(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<_CustomerReturnInput?> _showReturnDialog({
    required String title,
    required double sentQty,
    required String uom,
    required bool allowFullReturn,
    required bool requireQtyEntry,
    String? qtyLabel,
  }) async {
    final l10n = context.l10n;
    final qtyController = TextEditingController();
    final commentController = TextEditingController();
    String? selectedReason;
    return showDialog<_CustomerReturnInput>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) {
        final reasons = _rejectReasons(l10n);
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final trimmedComment = commentController.text.trim();
            final hasReason = (selectedReason ?? '').trim().isNotEmpty;
            final hasLongEnoughComment =
                trimmedComment.runes.length >= _minRejectCommentLength;
            final parsedReturnedQty = _parseQty(qtyController.text);
            final validQty = !requireQtyEntry ||
                (parsedReturnedQty != null &&
                    parsedReturnedQty > 0 &&
                    (allowFullReturn
                        ? parsedReturnedQty <= sentQty
                        : parsedReturnedQty < sentQty));
            final canConfirm = validQty && (hasReason || hasLongEnoughComment);
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Dialog(
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
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      if (requireQtyEntry) ...[
                        TextField(
                          controller: qtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setLocalState(() {}),
                          decoration: InputDecoration(
                            labelText: qtyLabel ?? l10n.returnedQtyLabel,
                            hintText: '${sentQty.toStringAsFixed(2)} $uom',
                            suffixText: uom,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.reasonLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...reasons.map(
                        (item) => InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setLocalState(() {
                              selectedReason =
                                  selectedReason == item ? null : item;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  selectedReason == item
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        minLines: 2,
                        maxLines: 4,
                        onChanged: (_) => setLocalState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.extraCommentLabel,
                          hintText: l10n.optionalReasonHint,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: Text(l10n.no),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: canConfirm
                                  ? () {
                                      Navigator.of(context).pop(
                                        _CustomerReturnInput(
                                          returnedQty: requireQtyEntry
                                              ? (parsedReturnedQty ?? sentQty)
                                              : sentQty,
                                          reason: (selectedReason ?? '').trim(),
                                          comment: trimmedComment,
                                        ),
                                      );
                                    }
                                  : null,
                              child: Text(l10n.yes),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double? _parseQty(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  Future<void> _approveAll() async {
    final l10n = context.l10n;
    final bool? confirmed = await showM3ConfirmDialog(
      context: context,
      title: l10n.confirmTitle,
      message: l10n.confirmQuestion,
      cancelLabel: l10n.no,
      confirmLabel: l10n.yes,
    );
    if (confirmed != true) {
      return;
    }
    await _sendResponse(
      approve: true,
      mode: CustomerDeliveryResponseMode.acceptAll,
    );
  }

  Future<void> _rejectAll() async {
    final l10n = context.l10n;
    final detail = await _future;
    final input = await _showReturnDialog(
      title: l10n.rejectTitle,
      sentQty: detail.record.sentQty,
      uom: detail.record.uom,
      allowFullReturn: true,
      requireQtyEntry: false,
    );
    if (input == null) {
      return;
    }
    await _sendResponse(
      approve: false,
      mode: CustomerDeliveryResponseMode.rejectAll,
      returnedQty: detail.record.sentQty,
      reason: input.reason,
      comment: input.comment,
    );
  }

  Future<void> _acceptPartial() async {
    final l10n = context.l10n;
    final detail = await _future;
    final input = await _showReturnDialog(
      title: l10n.partialAcceptTitle,
      sentQty: detail.record.sentQty,
      uom: detail.record.uom,
      allowFullReturn: false,
      requireQtyEntry: true,
      qtyLabel: l10n.returningQtyLabel,
    );
    if (input == null) {
      return;
    }
    final acceptedQty = detail.record.sentQty - input.returnedQty;
    await _sendResponse(
      mode: CustomerDeliveryResponseMode.acceptPartial,
      acceptedQty: acceptedQty,
      returnedQty: input.returnedQty,
      reason: input.reason,
      comment: input.comment,
    );
  }

  Future<void> _reportClaim() async {
    final l10n = context.l10n;
    final detail = await _future;
    final input = await _showReturnDialog(
      title: l10n.reportIssueTitle,
      sentQty: detail.record.sentQty,
      uom: detail.record.uom,
      allowFullReturn: true,
      requireQtyEntry: true,
    );
    if (input == null) {
      return;
    }
    await _sendResponse(
      mode: CustomerDeliveryResponseMode.claimAfterAccept,
      returnedQty: input.returnedQty,
      reason: input.reason,
      comment: input.comment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: context.l10n.detailsTitle,
      subtitle: '',
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      bottom: const CustomerDock(activeTab: null),
      child: FutureBuilder<CustomerDeliveryDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: AppLoadingIndicator());
          }
          if (snapshot.hasError) {
            return AppRetryState(onRetry: _reload);
          }
          final detail = snapshot.data!;
          final record = detail.record;
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Card.filled(
                  margin: EdgeInsets.zero,
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CustomerDetailSectionHeader(
                        label: context.l10n.shipmentInfoTitle,
                        topRounded: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailLine(
                                label: context.l10n.customerLabel,
                                value: record.supplierName),
                            const SizedBox(height: 12),
                            _DetailLine(
                              label: context.l10n.itemLabel,
                              value: '${record.itemCode} • ${record.itemName}',
                            ),
                            const SizedBox(height: 12),
                            _DetailLine(
                              label: context.l10n.pendingStatus,
                              value:
                                  '${record.sentQty.toStringAsFixed(2)} ${record.uom}',
                            ),
                            if (record.acceptedQty > 0) ...[
                              const SizedBox(height: 12),
                              _DetailLine(
                                label: context.l10n.acceptedFromQtyPrefix,
                                value:
                                    '${record.acceptedQty.toStringAsFixed(2)} ${record.uom}',
                              ),
                            ],
                            const SizedBox(height: 12),
                            _DetailLine(
                              label: context.l10n.statusLabel,
                              value: _statusLabel(record.status),
                            ),
                          ],
                        ),
                      ),
                      if (record.note.trim().isNotEmpty) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 18,
                          endIndent: 18,
                          color: scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                        _CustomerDetailSectionHeader(
                          label: context.l10n.noteTitle,
                          topRounded: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            record.note,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      if (record.status == DispatchStatus.accepted ||
                          record.status == DispatchStatus.partial ||
                          record.status == DispatchStatus.rejected) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 18,
                          endIndent: 18,
                          color: scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                        _CustomerDetailSectionHeader(
                          label: context.l10n.commentsTitle,
                          topRounded: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _openDiscussion,
                              child: Text(context.l10n.openDiscussionAction),
                            ),
                          ),
                        ),
                      ],
                      if (detail.canApprove ||
                          detail.canReject ||
                          detail.canPartiallyAccept ||
                          detail.canReportClaim) ...[
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 18,
                          endIndent: 18,
                          color: scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                        _CustomerDetailSectionHeader(
                          label: context.l10n.responseTitle,
                          topRounded: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              if (detail.canApprove)
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _submitting ? null : _approveAll,
                                    child: Text(
                                      _submitting
                                          ? context.l10n.sending
                                          : context.l10n.approveAction,
                                    ),
                                  ),
                                ),
                              if (detail.canApprove &&
                                  (detail.canPartiallyAccept ||
                                      detail.canReject))
                                const SizedBox(height: 12),
                              if (detail.canPartiallyAccept)
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed:
                                        _submitting ? null : _acceptPartial,
                                    child: Text(
                                      context.l10n.partialAcceptAction,
                                    ),
                                  ),
                                ),
                              if (detail.canPartiallyAccept && detail.canReject)
                                const SizedBox(height: 12),
                              if (detail.canReject)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _submitting ? null : _rejectAll,
                                    child: Text(context.l10n.rejectAction),
                                  ),
                                ),
                              if (detail.canReportClaim) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonal(
                                    onPressed:
                                        _submitting ? null : _reportClaim,
                                    child: Text(
                                      context.l10n.reportIssueAction,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.accepted:
        return AppLocalizations.of(context).approvedLabel;
      case DispatchStatus.partial:
        return AppLocalizations.of(context).partiallyCompleted;
      case DispatchStatus.rejected:
        return AppLocalizations.of(context).rejectedStatusLabel;
      default:
        return AppLocalizations.of(context).pendingLabel;
    }
  }
}

class _CustomerReturnInput {
  const _CustomerReturnInput({
    required this.returnedQty,
    required this.reason,
    required this.comment,
  });

  final double returnedQty;
  final String reason;
  final String comment;
}

class _CustomerDetailSectionHeader extends StatelessWidget {
  const _CustomerDetailSectionHeader({
    required this.label,
    required this.topRounded,
  });

  final String label;
  final bool topRounded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color:
            isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerHigh,
        borderRadius: topRounded
            ? const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              )
            : BorderRadius.zero,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  bool get _isStatus => label == 'Status';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        _isStatus
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ],
    );
  }
}
