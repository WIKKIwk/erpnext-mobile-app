import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaHomeScreen extends StatefulWidget {
  const WerkaHomeScreen({super.key});

  @override
  State<WerkaHomeScreen> createState() => _WerkaHomeScreenState();
}

class _WerkaHomeScreenState extends State<WerkaHomeScreen>
    with WidgetsBindingObserver {
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WerkaStore.instance.bootstrapHome();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'werka') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    await WerkaStore.instance.refreshHome();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: context.l10n.werkaRoleName,
      subtitle: '',
      actions: [
        AnimatedBuilder(
          animation: NotificationUnreadStore.instance,
          builder: (context, _) {
            final showBadge =
                NotificationUnreadStore.instance.hasUnreadForProfile(
              AppSession.instance.profile,
            );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.werkaNotifications,
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                if (showBadge)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      height: 9,
                      width: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
      bottom: const WerkaDock(activeTab: WerkaDockTab.home),
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: WerkaStore.instance,
              builder: (context, _) {
                final store = WerkaStore.instance;
                if (store.loadingHome && !store.loadedHome) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (store.homeError != null && !store.loadedHome) {
                  final l10n = context.l10n;
                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    allowRefreshOnShortContent: true,
                    child: ListView(
                      physics: const TopRefreshScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Card.filled(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.recordsLoadFailed,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${store.homeError}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: _reload,
                                    child: Text(l10n.retry),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final currentSummary = store.summary;
                final effectivePending = store.pendingItems;
                final previewItems = effectivePending.length > 3
                    ? effectivePending.take(3).toList()
                    : effectivePending;

                return AppRefreshIndicator(
                  onRefresh: _reload,
                  allowRefreshOnShortContent: true,
                  child: ListView(
                    physics: const TopRefreshScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _WerkaSummaryCard(summary: currentSummary),
                      ),
                      if (previewItems.isNotEmpty) const SizedBox(height: 16),
                      if (previewItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _WerkaPendingSection(items: previewItems),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WerkaSummaryCard extends StatelessWidget {
  const _WerkaSummaryCard({
    required this.summary,
  });

  final WerkaHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SmoothAppear(
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppTheme.cardBorder(context).withValues(alpha: 0.75),
          ),
        ),
        child: Column(
          children: [
            _WerkaSummaryRow(
              label: context.l10n.pendingStatus,
              value: summary.pendingCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.werkaStatusBreakdown,
                arguments: WerkaStatusKind.pending,
              ),
            ),
            const _WerkaSummaryDivider(),
            _WerkaSummaryRow(
              label: context.l10n.confirmedStatus,
              value: summary.confirmedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.werkaStatusBreakdown,
                arguments: WerkaStatusKind.confirmed,
              ),
            ),
            const _WerkaSummaryDivider(),
            _WerkaSummaryRow(
              label: context.l10n.returnedStatus,
              value: summary.returnedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.werkaStatusBreakdown,
                arguments: WerkaStatusKind.returned,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WerkaSummaryRow extends StatelessWidget {
  const _WerkaSummaryRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 58),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WerkaSummaryDivider extends StatelessWidget {
  const _WerkaSummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 18,
      endIndent: 18,
      color: AppTheme.cardBorder(context).withValues(alpha: 0.7),
    );
  }
}

class _WerkaPendingSection extends StatelessWidget {
  const _WerkaPendingSection({
    required this.items,
  });

  final List<DispatchRecord> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SmoothAppear(
      delay: const Duration(milliseconds: 90),
      offset: const Offset(0, 18),
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: AppTheme.cardBorder(context).withValues(alpha: 0.75),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.inProgressItemsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            for (int index = 0; index < items.length; index++)
              _WerkaPendingRow(
                record: items[index],
                hasBottomBorder: index != items.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _WerkaPendingRow extends StatelessWidget {
  const _WerkaPendingRow({
    required this.record,
    required this.hasBottomBorder,
  });

  final DispatchRecord record;
  final bool hasBottomBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: () => Navigator.of(context).pushNamed(
        record.isDeliveryNote
            ? AppRoutes.werkaCustomerDeliveryDetail
            : AppRoutes.werkaDetail,
        arguments: record,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            border: hasBottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: AppTheme.cardBorder(context),
                      width: 1,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.itemName,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.supplierName,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.createdLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
