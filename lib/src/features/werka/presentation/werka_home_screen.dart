import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaHomeScreen extends StatefulWidget {
  const WerkaHomeScreen({super.key});

  @override
  State<WerkaHomeScreen> createState() => _WerkaHomeScreenState();
}

class _WerkaHomeScreenState extends State<WerkaHomeScreen>
    with WidgetsBindingObserver {
  static const String _summaryCacheKey = 'cache_werka_home_summary';
  static const String _pendingCacheKey = 'cache_werka_home_pending';
  late Future<_WerkaHomeData> _homeFuture;
  WerkaHomeSummary? _cachedSummary;
  List<DispatchRecord>? _cachedPending;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeFuture = _loadHomeData();
    _loadCache();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  Future<void> _loadCache() async {
    final results = await Future.wait([
      JsonCacheStore.instance.readMap(_summaryCacheKey),
      JsonCacheStore.instance.readList(_pendingCacheKey),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      final summaryRaw = results[0] as Map<String, dynamic>?;
      final pendingRaw = results[1] as List<Map<String, dynamic>>?;
      _cachedSummary =
          summaryRaw == null ? null : WerkaHomeSummary.fromJson(summaryRaw);
      _cachedPending =
          pendingRaw?.map((item) => DispatchRecord.fromJson(item)).toList();
    });
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
    final future = _loadHomeData();
    setState(() {
      _homeFuture = future;
    });
    final data = await future;
    await JsonCacheStore.instance.writeMap(
      _summaryCacheKey,
      data.summary.toJson(),
    );
    await JsonCacheStore.instance.writeList(
      _pendingCacheKey,
      data.pendingItems.map((item) => item.toJson()).toList(),
    );
  }

  Future<_WerkaHomeData> _loadHomeData() async {
    final results = await Future.wait<dynamic>([
      MobileApi.instance.werkaSummary(),
      MobileApi.instance.werkaPending(),
    ]);
    return _WerkaHomeData(
      summary: results[0] as WerkaHomeSummary,
      pendingItems: results[1] as List<DispatchRecord>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Werka',
      subtitle: '',
      actions: [
        AppShellIconAction(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.werkaNotifications,
          ),
        ),
      ],
      bottom: const WerkaDock(activeTab: WerkaDockTab.home),
      contentPadding: const EdgeInsets.fromLTRB(14, 0, 16, 0),
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<_WerkaHomeData>(
              future: _homeFuture,
              builder: (context, snapshot) {
                final summary = snapshot.data?.summary ?? _cachedSummary;
                final pendingItems = snapshot.data?.pendingItems ??
                    _cachedPending ??
                    <DispatchRecord>[];
                if (snapshot.connectionState != ConnectionState.done &&
                    summary == null &&
                    pendingItems.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError &&
                    summary == null &&
                    pendingItems.isEmpty) {
                  return RefreshIndicator.adaptive(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending list yuklanmadi',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
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
                      ],
                    ),
                  );
                }
                final currentSummary = summary ??
                    const WerkaHomeSummary(
                      pendingCount: 0,
                      confirmedCount: 0,
                      returnedCount: 0,
                    );
                final previewItems = pendingItems.length > 3
                    ? pendingItems.take(3).toList()
                    : pendingItems;

                return RefreshIndicator.adaptive(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _WerkaStatCard(
                        label: 'Jarayonda',
                        value: currentSummary.pendingCount.toString(),
                        borderWidth: 1.55,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.werkaStatusBreakdown,
                          arguments: WerkaStatusKind.pending,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WerkaStatCard(
                        label: 'Tasdiqlangan',
                        value: currentSummary.confirmedCount.toString(),
                        borderWidth: 1.55,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.werkaStatusBreakdown,
                          arguments: WerkaStatusKind.confirmed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _WerkaStatCard(
                        label: 'Qaytarilgan',
                        value: currentSummary.returnedCount.toString(),
                        borderWidth: 1.55,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.werkaStatusBreakdown,
                          arguments: WerkaStatusKind.returned,
                        ),
                      ),
                      if (previewItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Jarayondagi mahsulotlar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                      ...previewItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final DispatchRecord record = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == previewItems.length - 1 ? 0 : 12,
                          ),
                          child: SmoothAppear(
                            delay: Duration(milliseconds: 70 + (index * 80)),
                            offset: const Offset(0, 18),
                            child: PressableScale(
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.werkaDetail,
                                arguments: record,
                              ),
                              child: SoftCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                borderWidth: 1.55,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.itemName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                record.supplierName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${record.sentQty.toStringAsFixed(0)} ${record.uom}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              record.createdLabel,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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

class _WerkaStatCard extends StatelessWidget {
  const _WerkaStatCard({
    required this.label,
    required this.value,
    this.onTap,
    this.borderWidth,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    return SmoothAppear(
      child: PressableScale(
        onTap: onTap,
        child: SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          borderWidth: borderWidth,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 34,
                      color: AppTheme.isDark(context)
                          ? Colors.white
                          : const Color(0xFF1F1A17),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WerkaHomeData {
  const _WerkaHomeData({
    required this.summary,
    required this.pendingItems,
  });

  final WerkaHomeSummary summary;
  final List<DispatchRecord> pendingItems;
}
