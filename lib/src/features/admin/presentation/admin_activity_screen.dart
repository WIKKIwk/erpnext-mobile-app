import '../../../app/app_router.dart';
import '../../../core/notifications/store/notification_hidden_store.dart';
import '../../../core/notifications/hub/refresh_hub.dart';
import '../../../core/session/session.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/feedback/m3_confirm_dialog.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../shared/models/app_models.dart';
import '../state/admin_store.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_summary_card.dart';
import 'package:flutter/material.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    AdminStore.instance.bootstrapActivity();
    NotificationHiddenStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  Future<void> _clearAll() async {
    final confirmed = await showM3ConfirmDialog(
      context: context,
      title: context.l10n.clearTitle,
      message: context.l10n.clearAllNotificationsPrompt,
      cancelLabel: context.l10n.no,
      confirmLabel: context.l10n.yes,
    );
    if (confirmed != true) {
      return;
    }
    final current = AdminStore.instance.activityItems;
    await NotificationHiddenStore.instance.hideAll(
      profile: AppSession.instance.profile,
      ids: current.map((item) => item.id),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'admin') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  Future<void> _reload() async {
    await AdminStore.instance.refreshActivity();
  }

  void _goHomeOrPop() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    nav.pushNamedAndRemoveUntil(
      AppRoutes.adminHome,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: _goHomeOrPop,
      ),
      title: context.l10n.adminActivityTitle,
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      contentPadding: EdgeInsets.zero,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            onPressed: _clearAll,
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ),
      ],
      bottom: const AdminDock(activeTab: AdminDockTab.activity),
      child: AnimatedBuilder(
        animation: AdminStore.instance,
        builder: (context, snapshot) {
          final store = AdminStore.instance;
          final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
            AppSession.instance.profile,
          );
          final items = (store.activityItems)
              .where((item) => !hidden.contains(item.id))
              .toList();
          if (store.loadingActivity && !store.loadedActivity && items.isEmpty) {
            return const Center(child: AppLoadingIndicator());
          }
          if (store.activityError != null &&
              !store.loadedActivity &&
              items.isEmpty) {
            return AppRetryState(onRetry: _reload);
          }

          if (items.isEmpty) {
            return Center(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Text(
                  context.l10n.adminNoActivity,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          return AppRefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.only(top: 4),
              children: [
                _AdminActivitySection(items: items),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminActivitySection extends StatelessWidget {
  const _AdminActivitySection({
    required this.items,
  });

  final List<DispatchRecord> items;

  @override
  Widget build(BuildContext context) {
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        for (int index = 0; index < items.length; index++)
          _AdminActivityCard(
            slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
              index,
              items.length,
            ),
            item: items[index],
          ),
      ],
    );
  }
}

class _AdminActivityCard extends StatelessWidget {
  const _AdminActivityCard({
    required this.slot,
    required this.item,
  });

  final M3SegmentVerticalSlot slot;
  final DispatchRecord item;

  String _metricLine() {
    final sent = '${item.sentQty.toStringAsFixed(0)} ${item.uom} jo‘natildi';
    if (item.acceptedQty > 0) {
      return '$sent • ${item.acceptedQty.toStringAsFixed(0)} ${item.uom} qabul';
    }
    return sent;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AdminSummaryCard(
      slot: slot,
      cornerRadius: M3SegmentedListGeometry.cornerRadiusForSlot(slot),
      title: item.supplierName,
      value: item.createdLabel,
      titleStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
            height: 1.15,
          ),
      subtitleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
            height: 1.2,
          ),
      valueStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11.5,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
      subtitle: _metricLine(),
      leading: _ActivityStatusBadge(status: item.status),
      showChevron: false,
      backgroundColor: scheme.surfaceContainerLow,
    );
  }
}

class _ActivityStatusBadge extends StatelessWidget {
  const _ActivityStatusBadge({
    required this.status,
  });

  final DispatchStatus status;

  IconData get icon {
    switch (status) {
      case DispatchStatus.draft:
        return Icons.schedule_rounded;
      case DispatchStatus.pending:
        return Icons.schedule_outlined;
      case DispatchStatus.accepted:
        return Icons.done_all_rounded;
      case DispatchStatus.partial:
        return Icons.check_rounded;
      case DispatchStatus.rejected:
        return Icons.close_rounded;
      case DispatchStatus.cancelled:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
