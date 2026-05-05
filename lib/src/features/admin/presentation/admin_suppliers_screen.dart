import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_supplier_list_module.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});

  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  static const int _initialPageSize = 100;
  static const int _pageSize = 50;
  static const double _prefetchExtentAfterFactor = 2.5;
  static _AdminSuppliersCache? _cache;

  final ScrollController _scrollController = ScrollController();
  final List<AdminUserListEntry> _items = [];
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
      _safeLoadAdminSettings(),
      _safeLoadAdminSuppliers(limit: _initialPageSize, offset: 0),
    ]);

    final settings = results[0] as AdminSettings;
    final suppliers = results[1] as List<AdminSupplier>;

    final items = <AdminUserListEntry>[
      ..._werkaItem(settings),
      ..._mapSuppliers(suppliers),
    ];
    final supplierHasMore = suppliers.length == _initialPageSize;
    final supplierOffset = suppliers.length;
    var customerHasMore = true;
    var customerOffset = 0;

    if (!supplierHasMore) {
      final customers =
          await _safeLoadAdminCustomers(limit: _initialPageSize, offset: 0);
      items.addAll(_mapCustomers(customers));
      customerOffset = customers.length;
      customerHasMore = customers.length == _initialPageSize;
    }

    if (!mounted) {
      return;
    }
    setState(() {
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
    return AppShell(
      animateOnEnter: false,
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
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 116),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AdminSupplierListModule(
                      items: _items,
                      onTapUser: _openUser,
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
              ),
            ),
    );
  }
}

class _AdminSuppliersCache {
  const _AdminSuppliersCache({
    required this.items,
    required this.supplierHasMore,
    required this.customerHasMore,
    required this.supplierOffset,
    required this.customerOffset,
  });

  final List<AdminUserListEntry> items;
  final bool supplierHasMore;
  final bool customerHasMore;
  final int supplierOffset;
  final int customerOffset;
}
