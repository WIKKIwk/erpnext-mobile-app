import '../../../app/app_router.dart';
import '../../../core/notifications/notification_hidden_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/session/app_session.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/m3_confirm_dialog.dart';
import '../../shared/models/app_models.dart';
import '../state/admin_store.dart';
import 'widgets/admin_dock.dart';
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
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
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
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _AdminActivityRow(
              item: items[index],
              isFirst: index == 0,
              isLast: index == items.length - 1,
            ),
            if (index != items.length - 1)
              const Divider(height: 1, thickness: 1),
          ],
        ],
      ),
    );
  }
}

class _AdminActivityRow extends StatelessWidget {
  const _AdminActivityRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final DispatchRecord item;
  final bool isFirst;
  final bool isLast;

  String _metricLine() {
    final sent = '${item.sentQty.toStringAsFixed(0)} ${item.uom} jo‘natildi';
    if (item.acceptedQty > 0) {
      return '$sent • ${item.acceptedQty.toStringAsFixed(0)} ${item.uom} qabul';
    }
    return sent;
  }

  String _secondary() => '${item.supplierName} • ${item.itemName}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.supplierName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              _ActivityStatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _secondary(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  _metricLine(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.createdLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
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
