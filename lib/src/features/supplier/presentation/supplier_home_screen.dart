import '../../../app/app_router.dart';
import '../../../core/notifications/notification_unread_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({super.key});

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen>
    with WidgetsBindingObserver {
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupplierStore.instance.bootstrapSummary();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'supplier') {
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
    await SupplierStore.instance.refreshSummary();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Supplier',
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
                    AppRoutes.supplierNotifications,
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
      bottom: const SupplierDock(activeTab: SupplierDockTab.home),
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      child: AnimatedBuilder(
        animation: SupplierStore.instance,
        builder: (context, _) {
          final store = SupplierStore.instance;
          if (store.loadingSummary && !store.loadedSummary) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.summaryError != null && !store.loadedSummary) {
            final scheme = Theme.of(context).colorScheme;
            return RefreshIndicator.adaptive(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 120),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Home yuklanmadi',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            '${store.summaryError}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _reload,
                              child: const Text('Qayta urinish'),
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
          final current = store.summary;

          return RefreshIndicator.adaptive(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _SupplierSummaryCard(summary: current),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SupplierSummaryCard extends StatelessWidget {
  const _SupplierSummaryCard({
    required this.summary,
  });

  final SupplierHomeSummary summary;

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
            _SupplierSummaryRow(
              label: 'Jarayonda',
              value: summary.pendingCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.pending,
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _SupplierSummaryRow(
              label: 'Submit',
              value: summary.submittedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.submitted,
              ),
            ),
            const Divider(height: 1, thickness: 1),
            _SupplierSummaryRow(
              label: 'Qaytarilgan',
              value: summary.returnedCount.toString(),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.supplierStatusBreakdown,
                arguments: SupplierStatusKind.returned,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierSummaryRow extends StatelessWidget {
  const _SupplierSummaryRow({
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
      borderRadius: 28,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
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
