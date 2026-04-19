import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_retry_state.dart';
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
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      title: context.l10n.werkaRoleName,
      subtitle: '',
      nativeTopBar: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              minimumSize: const Size.square(32),
              fixedSize: const Size.square(32),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.profile,
            ),
            icon: const Icon(Icons.person_outline_rounded, size: 26),
          ),
        ),
      ],
      bottom: const WerkaDock(activeTab: WerkaDockTab.home),
      contentPadding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: WerkaStore.instance,
              builder: (context, _) {
                final store = WerkaStore.instance;
                if (store.loadingHome && !store.loadedHome) {
                  return const Center(child: AppLoadingIndicator());
                }
                if (store.homeError != null && !store.loadedHome) {
                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    allowRefreshOnShortContent: true,
                    child: ListView(
                      physics: const TopRefreshScrollPhysics(),
                      children: [
                        AppRetryState(onRetry: _reload),
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
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    children: [
                      const SizedBox(height: 4),
                      _WerkaSummaryList(summary: currentSummary),
                      if (previewItems.isNotEmpty) const SizedBox(height: 16),
                      if (previewItems.isNotEmpty)
                        _WerkaPendingSection(items: previewItems),
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

class _WerkaSummaryList extends StatelessWidget {
  const _WerkaSummaryList({
    required this.summary,
  });

  final WerkaHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SmoothAppear(
      child: Column(
        children: [
          _WerkaSummaryListTile(
            label: context.l10n.pendingStatus,
            value: summary.pendingCount.toString(),
            highlighted: true,
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaStatusBreakdown,
              arguments: WerkaStatusKind.pending,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          _WerkaSummaryListTile(
            label: context.l10n.confirmedStatus,
            value: summary.confirmedCount.toString(),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaStatusBreakdown,
              arguments: WerkaStatusKind.confirmed,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
          _WerkaSummaryListTile(
            label: context.l10n.returnedStatus,
            value: summary.returnedCount.toString(),
            onTap: () => Navigator.of(context).pushNamed(
              AppRoutes.werkaStatusBreakdown,
              arguments: WerkaStatusKind.returned,
            ),
          ),
        ],
      ),
    );
  }
}

class _WerkaSummaryListTile extends StatelessWidget {
  const _WerkaSummaryListTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          child: Row(
            children: [
              if (highlighted) ...[
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return SmoothAppear(
      delay: const Duration(milliseconds: 90),
      offset: const Offset(0, 18),
      child: Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.l10n.inProgressItemsTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 14),
              Card.filled(
                margin: EdgeInsets.zero,
                color:
                    isDark ? const Color(0xFF2A2931) : scheme.surfaceContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    for (int index = 0; index < items.length; index++) ...[
                      _WerkaPendingRow(
                        record: items[index],
                        isFirst: index == 0,
                        isLast: index == items.length - 1,
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
        ),
      ),
    );
  }
}

class _WerkaPendingRow extends StatelessWidget {
  const _WerkaPendingRow({
    required this.record,
    required this.isFirst,
    required this.isLast,
  });

  final DispatchRecord record;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PressableScale(
      onTap: () => Navigator.of(context).pushNamed(
        record.isDeliveryNote
            ? AppRoutes.werkaCustomerDeliveryDetail
            : AppRoutes.werkaDetail,
        arguments: record,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isFirst ? 24 : 0),
              topRight: Radius.circular(isFirst ? 24 : 0),
              bottomLeft: Radius.circular(isLast ? 24 : 0),
              bottomRight: Radius.circular(isLast ? 24 : 0),
            ),
            onTap: () => Navigator.of(context).pushNamed(
              record.isDeliveryNote
                  ? AppRoutes.werkaCustomerDeliveryDetail
                  : AppRoutes.werkaDetail,
              arguments: record,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          record.supplierName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
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
      ),
    );
  }
}
