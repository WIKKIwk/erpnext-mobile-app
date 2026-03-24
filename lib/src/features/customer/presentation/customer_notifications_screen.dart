import '../../../core/cache/json_cache_store.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/notification_hidden_store.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/m3_confirm_dialog.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/customer_store.dart';
import 'widgets/customer_dock.dart';
import 'package:flutter/material.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({
    super.key,
    this.showShell = true,
    this.onClearActionChanged,
  });

  final bool showShell;
  final ValueChanged<VoidCallback?>? onClearActionChanged;

  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  static const String _cacheKey = 'cache_customer_notifications';
  List<DispatchRecord>? _cachedItems;
  Set<String> _highlightedUnreadIds = <String>{};
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    CustomerStore.instance.bootstrap();
    NotificationHiddenStore.instance.load().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    _loadCache();
    CustomerStore.instance.addListener(_handleStoreChanged);
    RefreshHub.instance.addListener(_handlePushRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onClearActionChanged?.call(_clearAll);
    });
  }

  @override
  void dispose() {
    CustomerStore.instance.removeListener(_handleStoreChanged);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomerNotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onClearActionChanged != oldWidget.onClearActionChanged) {
      widget.onClearActionChanged?.call(_clearAll);
    }
  }

  Future<void> _loadCache() async {
    final raw = await JsonCacheStore.instance.readList(_cacheKey);
    if (raw == null || !mounted) {
      return;
    }
    setState(() {
      _cachedItems = raw.map((item) => DispatchRecord.fromJson(item)).toList();
    });
  }

  Future<void> _reload() async {
    await CustomerStore.instance.refresh();
    await _syncFromStore();
  }

  Future<void> _openDetail(String deliveryNoteID) async {
    await NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: [deliveryNoteID],
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedUnreadIds.remove(deliveryNoteID);
    });
    await Navigator.of(context).pushNamed(
      '/customer-detail',
      arguments: deliveryNoteID,
    );
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
    final current = CustomerStore.instance.historyItems;
    await NotificationHiddenStore.instance.hideAll(
      profile: AppSession.instance.profile,
      ids: current.map((item) => item.id),
    );
    await NotificationUnreadStore.instance.markSeen(
      profile: AppSession.instance.profile,
      ids: current.map((item) => item.id),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedUnreadIds.clear();
    });
  }

  Future<void> _syncFromStore() async {
    final items = CustomerStore.instance.historyItems;
    final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
      AppSession.instance.profile,
    );
    if (hidden.isNotEmpty) {
      await NotificationUnreadStore.instance.markSeen(
        profile: AppSession.instance.profile,
        ids: hidden,
      );
    }
    await NotificationUnreadStore.instance.retainForProfile(
      profile: AppSession.instance.profile,
      ids: items.map((item) => item.id),
    );
    final unread = NotificationUnreadStore.instance.unreadIdsForProfile(
      AppSession.instance.profile,
    );
    final highlighted =
        items.map((item) => item.id).where((id) => unread.contains(id)).toSet();
    if (mounted) {
      setState(() {
        _highlightedUnreadIds = highlighted;
      });
    }
    await JsonCacheStore.instance.writeList(
      _cacheKey,
      items.map((item) => item.toJson()).toList(),
    );
    _cachedItems = items;
  }

  void _handleStoreChanged() {
    if (!mounted) {
      return;
    }
    _syncFromStore();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'customer') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    final content = AnimatedBuilder(
      animation: CustomerStore.instance,
      builder: (context, _) {
        final store = CustomerStore.instance;
        final hidden = NotificationHiddenStore.instance.hiddenIdsForProfile(
          AppSession.instance.profile,
        );
        final items = ((store.loaded ? store.historyItems : (_cachedItems ?? <DispatchRecord>[])))
            .where((item) => !hidden.contains(item.id))
            .toList();
        final orderedItems = [
          ...items.where((item) => _highlightedUnreadIds.contains(item.id)),
          ...items.where((item) => !_highlightedUnreadIds.contains(item.id)),
        ];

        if (store.loading && !store.loaded && items.isEmpty) {
          return const Center(child: AppLoadingIndicator());
        }
        if (store.error != null && !store.loaded && items.isEmpty) {
          return AppRefreshIndicator(
            onRefresh: _reload,
            allowRefreshOnShortContent: true,
            child: ListView(
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
              children: [
                AppRetryState(onRetry: _reload),
              ],
            ),
          );
        }
        if (items.isEmpty) {
          return AppRefreshIndicator(
            onRefresh: _reload,
            allowRefreshOnShortContent: true,
            child: ListView(
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
              children: [
                _NotificationPanel(
                  child: Text(context.l10n.noRecordsYet),
                ),
              ],
            ),
          );
        }

        return AppRefreshIndicator(
          onRefresh: _reload,
          allowRefreshOnShortContent: true,
          child: ListView(
            physics: const TopRefreshScrollPhysics(),
            padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
            children: [
              SmoothAppear(
                delay: const Duration(milliseconds: 20),
                child: _NotificationSection(
                  items: orderedItems,
                  highlightedUnreadIds: _highlightedUnreadIds,
                  onTapRecord: _openDetail,
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!widget.showShell) {
      return content;
    }

    return AppShell(
      title: context.l10n.notificationsTitle,
      subtitle: '',
      animateOnEnter: false,
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      actions: [
        IconButton.filledTonal(
          onPressed: _clearAll,
          icon: const Icon(Icons.clear_all_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
      bottom: const CustomerDock(activeTab: CustomerDockTab.notifications),
      child: content,
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isDark ? const Color(0xFF25242B) : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.items,
    required this.highlightedUnreadIds,
    required this.onTapRecord,
  });

  final List<DispatchRecord> items;
  final Set<String> highlightedUnreadIds;
  final ValueChanged<String> onTapRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return _NotificationPanel(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.shipmentsFlowTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 14),
          Card.filled(
            margin: EdgeInsets.zero,
            color: isDark ? const Color(0xFF2A2931) : scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                for (int index = 0; index < items.length; index++) ...[
                  SoftReveal(
                    delay: Duration(milliseconds: 20 + (index * 40)),
                    child: _CustomerFeedRow(
                      record: items[index],
                      isFirst: index == 0,
                      isLast: index == items.length - 1,
                      highlighted:
                          highlightedUnreadIds.contains(items[index].id),
                      onTap: () => onTapRecord(items[index].id),
                    ),
                  ),
                  if (index != items.length - 1)
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
    );
  }
}

class _CustomerFeedRow extends StatelessWidget {
  const _CustomerFeedRow({
    required this.record,
    required this.isFirst,
    required this.isLast,
    required this.highlighted,
    required this.onTap,
  });

  final DispatchRecord record;
  final bool isFirst;
  final bool isLast;
  final bool highlighted;
  final VoidCallback onTap;

  IconData get _icon {
    switch (record.status) {
      case DispatchStatus.accepted:
        return Icons.done_rounded;
      case DispatchStatus.rejected:
        return Icons.close_rounded;
      default:
        return Icons.schedule_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 24 : 0),
      topRight: Radius.circular(isFirst ? 24 : 0),
      bottomLeft: Radius.circular(isLast ? 24 : 0),
      bottomRight: Radius.circular(isLast ? 24 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.smooth,
          color: highlighted ? scheme.secondaryContainer : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.smooth,
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? scheme.secondaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _icon,
                    size: 20,
                    color: highlighted
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.itemName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.itemCode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record.note.trim().isNotEmpty
                            ? record.note
                            : '${record.sentQty.toStringAsFixed(0)} ${record.uom} jo‘natildi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      record.createdLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
  }
}
