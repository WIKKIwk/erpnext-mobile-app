import 'dart:math' as math;

import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/widgets/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../state/supplier_store.dart';
import 'supplier_qty_screen.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierRecentScreen extends StatefulWidget {
  const SupplierRecentScreen({super.key});

  @override
  State<SupplierRecentScreen> createState() => _SupplierRecentScreenState();
}

class _SupplierRecentScreenState extends State<SupplierRecentScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  int _refreshVersion = 0;
  double _cardStretch = 0.0;
  double _cardPull = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupplierStore.instance.bootstrapHistory();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RefreshHub.instance.removeListener(_handlePushRefresh);
    _scrollController.dispose();
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
    _settleTopEdge();
    await SupplierStore.instance.refreshHistory();
    _settleTopEdge();
  }

  void _settleTopEdge() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.minScrollExtent;
      if ((position.pixels - target).abs() <= 0.5) {
        return;
      }
      _scrollController.jumpTo(target);
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification) {
      final isAtBottom = notification.metrics.extentAfter <= 0.0;
      if (isAtBottom &&
          notification.dragDetails != null &&
          notification.overscroll > 0) {
        _cardPull = (_cardPull + notification.overscroll).clamp(0.0, 280.0);
        final easedPull = 1.0 - math.exp(-_cardPull / 110.0);
        final nextStretch = (easedPull * 0.075).clamp(0.0, 0.075).toDouble();
        if (nextStretch != _cardStretch) {
          setState(() => _cardStretch = nextStretch);
        }
        return false;
      }
    }

    if (notification is ScrollEndNotification) {
      if (_cardStretch != 0.0 || _cardPull != 0.0) {
        setState(() {
          _cardStretch = 0.0;
          _cardPull = 0.0;
        });
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: context.l10n.recentTitle,
      subtitle: context.l10n.recentSubtitle,
      bottom: const SupplierDock(activeTab: SupplierDockTab.recent),
      child: AnimatedBuilder(
        animation: SupplierStore.instance,
        builder: (context, _) {
          final store = SupplierStore.instance;
          final items = store.historyItems;
          if (store.loadingHistory && !store.loadedHistory) {
            return const Center(child: CircularProgressIndicator());
          }
          if (store.historyError != null && !store.loadedHistory) {
            return AppRefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 120),
                  Card.filled(
                    margin: EdgeInsets.zero,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.recentLoadFailed,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${store.historyError}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _reload,
                            child: Text(context.l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (items.isEmpty) {
            return Center(
              child: Card.filled(
                margin: EdgeInsets.zero,
                child: Text(context.l10n.noSupplierShipmentsYet),
              ),
            );
          }

          return AppRefreshIndicator(
            onRefresh: _reload,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 116),
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: 1.0 + _cardStretch,
                    ),
                    duration: const Duration(milliseconds: 110),
                    curve: Curves.easeOutCubic,
                    builder: (context, scaleY, child) {
                      return Transform.scale(
                        scaleY: scaleY,
                        alignment: Alignment.bottomCenter,
                        child: child,
                      );
                    },
                    child: Card.filled(
                      margin: EdgeInsets.zero,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          for (int index = 0; index < items.length; index++) ...[
                            Builder(builder: (context) {
                              final record = items[index];
                              final item = SupplierItem(
                                code: record.itemCode,
                                name: record.itemName,
                                uom: record.uom,
                                warehouse: '',
                              );
                              return InkWell(
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.supplierQty,
                                  arguments: SupplierQtyArgs(
                                    item: item,
                                    initialQty: record.sentQty,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record.itemCode,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            if (record.amount > 0) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '${record.amount.toStringAsFixed(0)} ${record.currency.isEmpty ? "" : record.currency}'
                                                    .trim(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        record.createdLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            if (index != items.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                indent: 18,
                                endIndent: 18,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.55),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
