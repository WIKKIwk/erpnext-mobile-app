import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/m3_segmented_list.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_navigation_drawer.dart';
import 'widgets/admin_supplier_list_module.dart';
import 'widgets/admin_summary_card.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  static const int _pageSize = 20;
  static const double _prefetchExtentAfterFactor = 2.5;
  static _AdminSuppliersCache? _cache;

  final ScrollController _scrollController = ScrollController();
  final List<AdminUserListEntry> _items = [];

  AdminSupplierSummary _summary = const AdminSupplierSummary(
    totalSuppliers: 0,
    activeSuppliers: 0,
    blockedSuppliers: 0,
  );
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _supplierHasMore = true;
  bool _customerHasMore = true;
  int _supplierOffset = 0;
  int _customerOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await _bootstrap(forceRefresh: true);
  }

  void _openDrawerRoute(String routeName) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _initialLoading ||
        _loadingMore ||
        (!_supplierHasMore && !_customerHasMore)) {
      return;
    }
    final viewport = _scrollController.position.viewportDimension;
    final prefetchExtentAfter = viewport * _prefetchExtentAfterFactor;
    if (_scrollController.position.extentAfter < prefetchExtentAfter) {
      unawaited(_loadMore());
    }
  }

  Future<void> _bootstrap({bool forceRefresh = false}) async {
    if (!forceRefresh && _restoreCache()) {
      return;
    }

    if (mounted) {
      setState(() {
        _initialLoading = true;
        _loadingMore = false;
        _supplierHasMore = true;
        _customerHasMore = true;
        _supplierOffset = 0;
        _customerOffset = 0;
        _items.clear();
      });
    }

    final results = await Future.wait([
      _safeLoadAdminSupplierSummary(),
      _safeLoadAdminSettings(),
      _safeLoadAdminSuppliers(limit: _pageSize, offset: 0),
    ]);

    final summary = results[0] as AdminSupplierSummary;
    final settings = results[1] as AdminSettings;
    final suppliers = results[2] as List<AdminSupplier>;

    final items = <AdminUserListEntry>[
      ..._werkaItem(settings),
      ..._mapSuppliers(suppliers),
    ];
    final supplierHasMore = suppliers.length == _pageSize;
    final supplierOffset = suppliers.length;
    var customerHasMore = true;
    var customerOffset = 0;

    if (!supplierHasMore) {
      final customers =
          await _safeLoadAdminCustomers(limit: _pageSize, offset: 0);
      items.addAll(_mapCustomers(customers));
      customerOffset = customers.length;
      customerHasMore = customers.length == _pageSize;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _summary = summary;
      _items
        ..clear()
        ..addAll(items);
      _supplierHasMore = supplierHasMore;
      _customerHasMore = customerHasMore;
      _supplierOffset = supplierOffset;
      _customerOffset = customerOffset;
      _initialLoading = false;
      _loadingMore = false;
    });
    _cache = _AdminSuppliersCache(
      summary: summary,
      items: List<AdminUserListEntry>.unmodifiable(items),
      supplierHasMore: supplierHasMore,
      customerHasMore: customerHasMore,
      supplierOffset: supplierOffset,
      customerOffset: customerOffset,
    );
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _initialLoading) {
      return;
    }
    if (!_supplierHasMore && !_customerHasMore) {
      return;
    }

    if (mounted) {
      setState(() => _loadingMore = true);
    }

    try {
      if (_supplierHasMore) {
        final suppliers = await _safeLoadAdminSuppliers(
          limit: _pageSize,
          offset: _supplierOffset,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _items.addAll(_mapSuppliers(suppliers));
          _supplierOffset += suppliers.length;
          if (suppliers.length < _pageSize) {
            _supplierHasMore = false;
          }
        });
      }

      if (!_supplierHasMore && _customerHasMore) {
        final customers = await _safeLoadAdminCustomers(
          limit: _pageSize,
          offset: _customerOffset,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _items.addAll(_mapCustomers(customers));
          _customerOffset += customers.length;
          if (customers.length < _pageSize) {
            _customerHasMore = false;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<AdminSupplierSummary> _safeLoadAdminSupplierSummary() async {
    try {
      return await MobileApi.instance.adminSupplierSummary();
    } catch (error) {
      debugPrint('admin supplier summary failed: $error');
      return const AdminSupplierSummary(
        totalSuppliers: 0,
        activeSuppliers: 0,
        blockedSuppliers: 0,
      );
    }
  }

  Future<List<AdminSupplier>> _safeLoadAdminSuppliers({
    required int limit,
    required int offset,
  }) async {
    try {
      return await MobileApi.instance.adminSuppliers(
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      debugPrint('admin suppliers page failed: $error');
      return const <AdminSupplier>[];
    }
  }

  Future<List<CustomerDirectoryEntry>> _safeLoadAdminCustomers({
    required int limit,
    required int offset,
  }) async {
    try {
      return await MobileApi.instance.adminCustomers(
        limit: limit,
        offset: offset,
      );
    } catch (error) {
      debugPrint('admin customers page failed: $error');
      return const <CustomerDirectoryEntry>[];
    }
  }

  Future<AdminSettings> _safeLoadAdminSettings() async {
    try {
      return await MobileApi.instance.adminSettings();
    } catch (error) {
      debugPrint('admin settings failed: $error');
      return const AdminSettings(
        erpUrl: '',
        erpApiKey: '',
        erpApiSecret: '',
        defaultTargetWarehouse: '',
        defaultUom: '',
        werkaPhone: '',
        werkaName: '',
        werkaCode: '',
        werkaCodeLocked: false,
        werkaCodeRetryAfterSec: 0,
        adminPhone: '',
        adminName: '',
      );
    }
  }

  List<AdminUserListEntry> _werkaItem(AdminSettings settings) {
    if (settings.werkaName.trim().isEmpty &&
        settings.werkaPhone.trim().isEmpty) {
      return const <AdminUserListEntry>[];
    }
    return [
      AdminUserListEntry(
        id: 'werka',
        name: settings.werkaName.trim().isEmpty
            ? 'Werka'
            : settings.werkaName.trim(),
        phone: settings.werkaPhone.trim(),
        kind: AdminUserKind.werka,
      ),
    ];
  }

  List<AdminUserListEntry> _mapSuppliers(List<AdminSupplier> suppliers) {
    return suppliers
        .map(
          (item) => AdminUserListEntry(
            id: item.ref,
            name: item.name,
            phone: item.phone,
            kind: AdminUserKind.supplier,
            blocked: item.blocked,
          ),
        )
        .toList();
  }

  List<AdminUserListEntry> _mapCustomers(
      List<CustomerDirectoryEntry> customers) {
    return customers
        .map(
          (item) => AdminUserListEntry(
            id: item.ref,
            name: item.name,
            phone: item.phone,
            kind: AdminUserKind.customer,
          ),
        )
        .toList();
  }

  Future<void> _openUser(AdminUserListEntry item) async {
    bool changed = false;
    if (item.kind == AdminUserKind.werka) {
      final result =
          await Navigator.of(context).pushNamed(AppRoutes.adminWerka);
      changed = result == true;
    } else if (item.kind == AdminUserKind.customer) {
      final result = await Navigator.of(context).pushNamed(
        AppRoutes.adminCustomerDetail,
        arguments: item.id,
      );
      changed = result == true;
    } else {
      final result = await Navigator.of(context).pushNamed(
        AppRoutes.adminSupplierDetail,
        arguments: item.id,
      );
      changed = result == true;
    }
    if (changed && mounted) {
      await _bootstrap(forceRefresh: true);
    }
  }

  bool _restoreCache() {
    final cache = _cache;
    if (cache == null) {
      return false;
    }
    if (mounted) {
      setState(() {
        _summary = cache.summary;
        _items
          ..clear()
          ..addAll(cache.items);
        _supplierHasMore = cache.supplierHasMore;
        _customerHasMore = cache.customerHasMore;
        _supplierOffset = cache.supplierOffset;
        _customerOffset = cache.customerOffset;
        _initialLoading = false;
        _loadingMore = false;
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final routeAnimation = route?.animation;
    return AppShell(
      drawer: AdminNavigationDrawer(
        selectedIndex: 1,
        onNavigate: _openDrawerRoute,
      ),
      title: 'Users',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      contentPadding: EdgeInsets.zero,
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: _initialLoading
          ? const Center(child: AppLoadingIndicator())
          : AppRefreshIndicator(
              onRefresh: _reload,
              child: AnimatedBuilder(
                animation: routeAnimation ?? const AlwaysStoppedAnimation(1),
                builder: (context, _) {
                  final routeValue = routeAnimation == null
                      ? 1.0
                      : CurvedAnimation(
                          parent: routeAnimation,
                          curve: AppMotion.pageIn,
                          reverseCurve: AppMotion.pageOut,
                        ).value;
                  final summaryFactor = (1 - routeValue).clamp(0.0, 1.0);
                  final listFactor = routeValue.clamp(0.0, 1.0);
                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 116),
                    children: [
                      const SizedBox(height: 4),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: summaryFactor,
                          child: Opacity(
                            opacity: summaryFactor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AdminSuppliersSummarySection(
                                  summary: _summary,
                                  onTapBlocked: () =>
                                      Navigator.of(context).pushNamed(
                                    AppRoutes.adminInactiveSuppliers,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: listFactor,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - listFactor)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AdminSupplierListModule(
                              items: _items,
                              onTapUser: _openUser,
                            ),
                          ),
                        ),
                      ),
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.only(top: 14),
                          child: Center(child: AppLoadingIndicator()),
                        )
                      else if (_supplierHasMore || _customerHasMore)
                        const SizedBox(height: 14),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _AdminSuppliersCache {
  const _AdminSuppliersCache({
    required this.summary,
    required this.items,
    required this.supplierHasMore,
    required this.customerHasMore,
    required this.supplierOffset,
    required this.customerOffset,
  });

  final AdminSupplierSummary summary;
  final List<AdminUserListEntry> items;
  final bool supplierHasMore;
  final bool customerHasMore;
  final int supplierOffset;
  final int customerOffset;
}

class _AdminSuppliersSummarySection extends StatelessWidget {
  const _AdminSuppliersSummarySection({
    required this.summary,
    required this.onTapBlocked,
  });

  final AdminSupplierSummary summary;
  final VoidCallback onTapBlocked;

  @override
  Widget build(BuildContext context) {
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.top,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Jami supplierlar',
          value: summary.totalSuppliers.toString(),
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.middle,
          cornerRadius: M3SegmentedListGeometry.cornerMiddle,
          title: 'Faol supplierlar',
          value: summary.activeSuppliers.toString(),
        ),
        AdminSummaryCard(
          slot: M3SegmentVerticalSlot.bottom,
          cornerRadius: M3SegmentedListGeometry.cornerLarge,
          title: 'Bloklangan supplierlar',
          value: summary.blockedSuppliers.toString(),
          onTap: onTapBlocked,
        ),
      ],
    );
  }
}
