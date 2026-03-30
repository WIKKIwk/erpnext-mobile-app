import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/werka_runtime_store.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class WerkaStore extends ChangeNotifier {
  WerkaStore._() {
    WerkaRuntimeStore.instance.addListener(_forwardRuntimeChange);
  }

  static final WerkaStore instance = WerkaStore._();

  bool _loadingHome = false;
  bool _loadingHistory = false;
  bool _loadedHome = false;
  bool _loadedHistory = false;
  Object? _homeError;
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
  List<DispatchRecord> _historyItems = const <DispatchRecord>[];

  bool get loadingHome => _loadingHome;
  bool get loadingHistory => _loadingHistory;
  bool get loadedHome => _loadedHome;
  bool get loadedHistory => _loadedHistory;
  Object? get homeError => _homeError;
  Object? get historyError => _historyError;
  WerkaHomeSummary get summary {
    if (_loadedHome && _loadedHistory) {
      var confirmed = 0;
      var returned = 0;
      for (final item in _historyItems) {
        if (!_countsTowardWerkaSummary(item)) {
          continue;
        }
        switch (item.status) {
          case DispatchStatus.accepted:
            confirmed += 1;
          case DispatchStatus.partial:
          case DispatchStatus.rejected:
          case DispatchStatus.cancelled:
            returned += 1;
          case DispatchStatus.pending:
          case DispatchStatus.draft:
            break;
        }
      }
      final adjusted = WerkaRuntimeStore.instance.applySummary(
        WerkaHomeSummary(
          pendingCount: pendingItems.length,
          confirmedCount: confirmed,
          returnedCount: returned,
        ),
      );
      return WerkaHomeSummary(
        pendingCount: adjusted.pendingCount,
        confirmedCount: adjusted.confirmedCount,
        returnedCount: adjusted.returnedCount,
      );
    }
    final adjusted = WerkaRuntimeStore.instance.applySummary(_summary);
    return WerkaHomeSummary(
      pendingCount: adjusted.pendingCount,
      confirmedCount: adjusted.confirmedCount,
      returnedCount: adjusted.returnedCount,
    );
  }

  List<DispatchRecord> get pendingItems =>
      WerkaRuntimeStore.instance.applyPendingItems(_pendingItems);
  List<DispatchRecord> get historyItems => _historyItems;
  List<WerkaStatusBreakdownEntry> breakdownItems(WerkaStatusKind kind) =>
      kind == WerkaStatusKind.pending
          ? _pendingBreakdownItems()
          : _breakdownItems[kind] ?? const <WerkaStatusBreakdownEntry>[];
  bool loadingBreakdown(WerkaStatusKind kind) => kind == WerkaStatusKind.pending
      ? _loadingHome
      : _loadingBreakdown[kind] == true;
  Object? breakdownError(WerkaStatusKind kind) =>
      kind == WerkaStatusKind.pending ? _homeError : _breakdownErrors[kind];
  List<DispatchRecord> detailItems(WerkaStatusKind kind, String supplierRef) =>
      kind == WerkaStatusKind.pending
          ? _pendingDetailItems(supplierRef)
          : _detailItems[_detailKey(kind, supplierRef)] ??
              const <DispatchRecord>[];
  bool loadingDetail(WerkaStatusKind kind, String supplierRef) =>
      kind == WerkaStatusKind.pending
          ? _loadingHome
          : _loadingDetail[_detailKey(kind, supplierRef)] == true;
  Object? detailError(WerkaStatusKind kind, String supplierRef) =>
      kind == WerkaStatusKind.pending
          ? _homeError
          : _detailErrors[_detailKey(kind, supplierRef)];

  Future<void> bootstrapHome({bool force = false}) async {
    if (_loadingHome) return;
    if (_loadedHome && !force) return;
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
        pendingItems: _pendingItems,
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
      _loadedHistory = true;
    } catch (error) {
      _historyError = error;
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshHome(),
      refreshHistory(),
    ]);
  }

  Future<void> bootstrapBreakdown(WerkaStatusKind kind,
      {bool force = false}) async {
    if (kind == WerkaStatusKind.pending) {
      await bootstrapHome(force: force);
      return;
    }
    if (loadingBreakdown(kind)) return;
    if (_breakdownItems.containsKey(kind) && !force) return;
    await refreshBreakdown(kind);
  }

  Future<void> refreshBreakdown(WerkaStatusKind kind) async {
    if (kind == WerkaStatusKind.pending) {
      await refreshHome();
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
      await bootstrapHome(force: force);
      return;
    }
    final key = _detailKey(kind, supplierRef);
    if (_loadingDetail[key] == true) return;
    if (_detailItems.containsKey(key) && !force) return;
    await refreshDetail(kind, supplierRef);
  }

  Future<void> refreshDetail(WerkaStatusKind kind, String supplierRef) async {
    if (kind == WerkaStatusKind.pending) {
      await refreshHome();
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

  bool _countsTowardWerkaSummary(DispatchRecord record) {
    return record.eventType.isEmpty ||
        record.eventType.startsWith('customer_delivery_');
  }

  List<WerkaStatusBreakdownEntry> _pendingBreakdownItems() {
    final grouped = <String, _PendingSupplierAggregate>{};
    for (final item in pendingItems) {
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
    return pendingItems
        .where((item) => item.supplierRef.trim() == expectedRef)
        .toList();
  }

  String _detailKey(WerkaStatusKind kind, String supplierRef) =>
      '${kind.name}:${supplierRef.trim()}';

  void clear() {
    _loadingHome = false;
    _loadingHistory = false;
    _loadedHome = false;
    _loadedHistory = false;
    _homeError = null;
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
