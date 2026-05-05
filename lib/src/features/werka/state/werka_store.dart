import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/store/werka_runtime_store.dart';
import '../../../core/session/session.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class WerkaStore extends ChangeNotifier {
  WerkaStore._() {
    WerkaRuntimeStore.instance.addListener(_forwardRuntimeChange);
  }

  static final WerkaStore instance = WerkaStore._();

  bool _loadingHome = false;
  bool _loadingPending = false;
  bool _loadingHistory = false;
  bool _loadedHome = false;
  bool _loadedPending = false;
  bool _loadedHistory = false;
  Object? _homeError;
  Object? _pendingError;
  Object? _historyError;
  final Map<WerkaStatusKind, bool> _loadingBreakdown = {};
  final Map<WerkaStatusKind, Object?> _breakdownErrors = {};
  final Map<WerkaStatusKind, List<WerkaStatusBreakdownEntry>> _breakdownItems =
      {};
  final Map<String, bool> _loadingDetail = {};
  final Map<String, Object?> _detailErrors = {};
  final Map<String, List<DispatchRecord>> _detailItems = {};

  WerkaHomeSummary _summary = const WerkaHomeSummary(
    pendingCount: 0,
    confirmedCount: 0,
    returnedCount: 0,
  );
  List<DispatchRecord> _pendingItems = const <DispatchRecord>[];
  List<DispatchRecord> _fullPendingItems = const <DispatchRecord>[];
  List<DispatchRecord> _historyItems = const <DispatchRecord>[];

  /// Home «Jarayondagi mahsulotlar» bo‘limi ochiq/yopiq — sahifadan chiqib kirguncha xotirada.
  bool _homePendingListExpanded = true;

  bool get loadingHome => _loadingHome;
  bool get loadingPending => _loadingPending;
  bool get loadingHistory => _loadingHistory;
  bool get loadedHome => _loadedHome;
  bool get loadedPending => _loadedPending;
  bool get loadedHistory => _loadedHistory;
  Object? get homeError => _homeError;
  Object? get pendingError => _pendingError;
  Object? get historyError => _historyError;
  WerkaHomeSummary get summary {
    final adjusted = WerkaRuntimeStore.instance.applySummary(_summary);
    return WerkaHomeSummary(
      pendingCount: adjusted.pendingCount,
      confirmedCount: adjusted.confirmedCount,
      returnedCount: adjusted.returnedCount,
    );
  }

  List<DispatchRecord> get pendingItems =>
      WerkaRuntimeStore.instance.applyPendingItems(_pendingItems);

  List<DispatchRecord> get fullPendingItems =>
      WerkaRuntimeStore.instance.applyPendingItems(
        _loadedPending ? _fullPendingItems : _pendingItems,
      );

  bool get homePendingListExpanded => _homePendingListExpanded;

  void setHomePendingListExpanded(bool value) {
    _homePendingListExpanded = value;
  }

  List<DispatchRecord> get historyItems => _historyItems;
  List<WerkaStatusBreakdownEntry> breakdownItems(WerkaStatusKind kind) =>
      kind == WerkaStatusKind.pending
          ? _pendingBreakdownItems()
          : _breakdownItems[kind] ?? const <WerkaStatusBreakdownEntry>[];
  bool loadingBreakdown(WerkaStatusKind kind) => kind == WerkaStatusKind.pending
      ? _loadingPending
      : _loadingBreakdown[kind] == true;
  Object? breakdownError(WerkaStatusKind kind) =>
      kind == WerkaStatusKind.pending ? _pendingError : _breakdownErrors[kind];
  List<DispatchRecord> detailItems(WerkaStatusKind kind, String supplierRef) =>
      kind == WerkaStatusKind.pending
          ? _pendingDetailItems(supplierRef)
          : _detailItems[_detailKey(kind, supplierRef)] ??
              const <DispatchRecord>[];
  bool loadingDetail(WerkaStatusKind kind, String supplierRef) =>
      kind == WerkaStatusKind.pending
          ? _loadingPending
          : _loadingDetail[_detailKey(kind, supplierRef)] == true;
  Object? detailError(WerkaStatusKind kind, String supplierRef) =>
      kind == WerkaStatusKind.pending
          ? _pendingError
          : _detailErrors[_detailKey(kind, supplierRef)];

  Future<void> bootstrapHome({bool force = false}) async {
    if (_loadingHome) return;
    if (_loadedHome && !force) return;
    final bootstrap =
        force ? null : AppSession.instance.consumeWerkaHomeBootstrap();
    if (bootstrap != null) {
      _summary = bootstrap.summary;
      _pendingItems = bootstrap.pendingItems;
      _loadedHome = true;
      _homeError = null;
      notifyListeners();
      return;
    }
    await refreshHome();
  }

  Future<void> bootstrapHistory({bool force = false}) async {
    if (_loadingHistory) return;
    if (_loadedHistory && !force) return;
    await refreshHistory();
  }

  Future<void> refreshHome() async {
    if (_loadingHome) return;
    _loadingHome = true;
    _homeError = null;
    notifyListeners();
    try {
      final home = await MobileApi.instance.werkaHome();
      _summary = home.summary;
      _pendingItems = home.pendingItems;
      WerkaRuntimeStore.instance.reconcileWithServer(
        pendingItems: _loadedPending ? _fullPendingItems : _pendingItems,
        historyItems: _historyItems,
      );
      _loadedHome = true;
    } catch (error) {
      _homeError = error;
    } finally {
      _loadingHome = false;
      notifyListeners();
    }
  }

  Future<void> refreshHistory() async {
    if (_loadingHistory) return;
    _loadingHistory = true;
    _historyError = null;
    notifyListeners();
    try {
      _historyItems = await MobileApi.instance.werkaHistory();
      WerkaRuntimeStore.instance.reconcileWithServer(
        pendingItems: _loadedPending ? _fullPendingItems : _pendingItems,
        historyItems: _historyItems,
      );
      _loadedHistory = true;
    } catch (error) {
      _historyError = error;
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> bootstrapPending({bool force = false}) async {
    if (_loadingPending) return;
    if (_loadedPending && !force) return;
    await refreshPending();
  }

  Future<void> refreshPending() async {
    if (_loadingPending) return;
    _loadingPending = true;
    _pendingError = null;
    notifyListeners();
    try {
      final items = await MobileApi.instance.werkaPending();
      _fullPendingItems = items;
      _summary = WerkaHomeSummary(
        pendingCount: items.length,
        confirmedCount: _summary.confirmedCount,
        returnedCount: _summary.returnedCount,
      );
      WerkaRuntimeStore.instance.reconcileWithServer(
        pendingItems: _fullPendingItems,
        historyItems: _historyItems,
      );
      _loadedPending = true;
    } catch (error) {
      _pendingError = error;
    } finally {
      _loadingPending = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshHome(),
      refreshPending(),
      refreshHistory(),
    ]);
  }

  Future<void> bootstrapBreakdown(WerkaStatusKind kind,
      {bool force = false}) async {
    if (kind == WerkaStatusKind.pending) {
      await bootstrapPending(force: force);
      return;
    }
    if (loadingBreakdown(kind)) return;
    if (_breakdownItems.containsKey(kind) && !force) return;
    await refreshBreakdown(kind);
  }

  Future<void> refreshBreakdown(WerkaStatusKind kind) async {
    if (kind == WerkaStatusKind.pending) {
      await refreshPending();
      return;
    }
    if (loadingBreakdown(kind)) return;
    _loadingBreakdown[kind] = true;
    _breakdownErrors[kind] = null;
    notifyListeners();
    try {
      _breakdownItems[kind] =
          await MobileApi.instance.werkaStatusBreakdown(kind);
    } catch (error) {
      _breakdownErrors[kind] = error;
    } finally {
      _loadingBreakdown[kind] = false;
      notifyListeners();
    }
  }

  Future<void> bootstrapDetail(WerkaStatusKind kind, String supplierRef,
      {bool force = false}) async {
    if (kind == WerkaStatusKind.pending) {
      await bootstrapPending(force: force);
      return;
    }
    final key = _detailKey(kind, supplierRef);
    if (_loadingDetail[key] == true) return;
    if (_detailItems.containsKey(key) && !force) return;
    await refreshDetail(kind, supplierRef);
  }

  Future<void> refreshDetail(WerkaStatusKind kind, String supplierRef) async {
    if (kind == WerkaStatusKind.pending) {
      await refreshPending();
      return;
    }
    final key = _detailKey(kind, supplierRef);
    if (_loadingDetail[key] == true) return;
    _loadingDetail[key] = true;
    _detailErrors[key] = null;
    notifyListeners();
    try {
      _detailItems[key] = await MobileApi.instance.werkaStatusDetails(
        kind: kind,
        supplierRef: supplierRef,
      );
    } catch (error) {
      _detailErrors[key] = error;
    } finally {
      _loadingDetail[key] = false;
      notifyListeners();
    }
  }

  void recordCreatedPending(DispatchRecord record) {
    WerkaRuntimeStore.instance.recordCreatedPending(record);
  }

  void recordTransition({
    required DispatchRecord before,
    required DispatchRecord after,
  }) {
    WerkaRuntimeStore.instance.recordTransition(before: before, after: after);
  }

  void _forwardRuntimeChange() {
    notifyListeners();
  }

  List<WerkaStatusBreakdownEntry> _pendingBreakdownItems() {
    final grouped = <String, _PendingSupplierAggregate>{};
    for (final item in fullPendingItems) {
      final supplierRef = item.supplierRef.trim();
      final key = supplierRef.isEmpty ? item.supplierName.trim() : supplierRef;
      final current = grouped[key];
      if (current == null) {
        grouped[key] = _PendingSupplierAggregate(
          supplierRef: item.supplierRef,
          supplierName: item.supplierName,
          uom: item.uom,
          receiptCount: 1,
          totalSentQty: item.sentQty,
          latestCreatedLabel: item.createdLabel,
        );
        continue;
      }
      current.receiptCount += 1;
      current.totalSentQty += item.sentQty;
      if (createdLabelIsAfter(item.createdLabel, current.latestCreatedLabel)) {
        current.latestCreatedLabel = item.createdLabel;
      }
      if (current.supplierName.trim().isEmpty &&
          item.supplierName.trim().isNotEmpty) {
        current.supplierName = item.supplierName;
      }
      if (current.uom.trim().isEmpty && item.uom.trim().isNotEmpty) {
        current.uom = item.uom;
      }
    }

    final items = grouped.values.toList()
      ..sort((a, b) =>
          compareCreatedLabelsDesc(a.latestCreatedLabel, b.latestCreatedLabel));
    return items
        .map(
          (item) => WerkaStatusBreakdownEntry(
            supplierRef: item.supplierRef,
            supplierName: item.supplierName,
            receiptCount: item.receiptCount,
            totalSentQty: item.totalSentQty,
            totalAcceptedQty: 0,
            totalReturnedQty: 0,
            uom: item.uom,
          ),
        )
        .toList();
  }

  List<DispatchRecord> _pendingDetailItems(String supplierRef) {
    final expectedRef = supplierRef.trim();
    return fullPendingItems
        .where((item) => item.supplierRef.trim() == expectedRef)
        .toList();
  }

  String _detailKey(WerkaStatusKind kind, String supplierRef) =>
      '${kind.name}:${supplierRef.trim()}';

  void clear() {
    _loadingHome = false;
    _loadingPending = false;
    _loadingHistory = false;
    _loadedHome = false;
    _loadedPending = false;
    _loadedHistory = false;
    _homeError = null;
    _pendingError = null;
    _historyError = null;
    _loadingBreakdown.clear();
    _breakdownErrors.clear();
    _breakdownItems.clear();
    _loadingDetail.clear();
    _detailErrors.clear();
    _detailItems.clear();
    _summary = const WerkaHomeSummary(
      pendingCount: 0,
      confirmedCount: 0,
      returnedCount: 0,
    );
    _pendingItems = const <DispatchRecord>[];
    _fullPendingItems = const <DispatchRecord>[];
    _historyItems = const <DispatchRecord>[];
    notifyListeners();
  }
}

class _PendingSupplierAggregate {
  _PendingSupplierAggregate({
    required this.supplierRef,
    required this.supplierName,
    required this.uom,
    required this.receiptCount,
    required this.totalSentQty,
    required this.latestCreatedLabel,
  });

  final String supplierRef;
  String supplierName;
  String uom;
  int receiptCount;
  double totalSentQty;
  String latestCreatedLabel;
}
