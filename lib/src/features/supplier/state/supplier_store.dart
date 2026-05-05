import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/store/supplier_runtime_store.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class SupplierStore extends ChangeNotifier {
  SupplierStore._() {
    SupplierRuntimeStore.instance.addListener(_forwardRuntimeChange);
  }

  static final SupplierStore instance = SupplierStore._();

  bool _loadingSummary = false;
  bool _loadingHistory = false;
  bool _loadedSummary = false;
  bool _loadedHistory = false;
  Object? _summaryError;
  Object? _historyError;
  final Map<SupplierStatusKind, bool> _loadingBreakdown = {};
  final Map<SupplierStatusKind, Object?> _breakdownErrors = {};
  final Map<SupplierStatusKind, List<SupplierStatusBreakdownEntry>>
      _breakdownItems = {};
  final Map<String, bool> _loadingDetail = {};
  final Map<String, Object?> _detailErrors = {};
  final Map<String, List<DispatchRecord>> _detailItems = {};

  SupplierHomeSummary _summary = const SupplierHomeSummary(
    pendingCount: 0,
    submittedCount: 0,
    returnedCount: 0,
  );
  List<DispatchRecord> _historyItems = const <DispatchRecord>[];

  bool get loadingSummary => _loadingSummary;
  bool get loadingHistory => _loadingHistory;
  bool get loadedSummary => _loadedSummary;
  bool get loadedHistory => _loadedHistory;
  Object? get summaryError => _summaryError;
  Object? get historyError => _historyError;

  SupplierHomeSummary get summary {
    if (_loadedSummary) {
      return SupplierRuntimeStore.instance.applySummary(_summary);
    }
    if (loadedHistory) {
      var pending = 0;
      var submitted = 0;
      var returned = 0;
      for (final item in _historyItems) {
        switch (item.status) {
          case DispatchStatus.pending:
          case DispatchStatus.draft:
            pending += 1;
          case DispatchStatus.accepted:
            submitted += 1;
          case DispatchStatus.partial:
          case DispatchStatus.rejected:
          case DispatchStatus.cancelled:
            returned += 1;
        }
      }
      return SupplierRuntimeStore.instance.applySummary(
        SupplierHomeSummary(
          pendingCount: pending,
          submittedCount: submitted,
          returnedCount: returned,
        ),
      );
    }
    return SupplierRuntimeStore.instance.applySummary(_summary);
  }

  List<DispatchRecord> get historyItems => _historyItems;
  List<SupplierStatusBreakdownEntry> breakdownItems(SupplierStatusKind kind) =>
      _breakdownItems[kind] ?? const <SupplierStatusBreakdownEntry>[];
  bool loadingBreakdown(SupplierStatusKind kind) =>
      _loadingBreakdown[kind] == true;
  Object? breakdownError(SupplierStatusKind kind) => _breakdownErrors[kind];
  List<DispatchRecord> detailItems(SupplierStatusKind kind, String itemCode) =>
      _detailItems[_detailKey(kind, itemCode)] ?? const <DispatchRecord>[];
  bool loadingDetail(SupplierStatusKind kind, String itemCode) =>
      _loadingDetail[_detailKey(kind, itemCode)] == true;
  Object? detailError(SupplierStatusKind kind, String itemCode) =>
      _detailErrors[_detailKey(kind, itemCode)];

  Future<void> bootstrapSummary({bool force = false}) async {
    if (_loadingSummary) return;
    if (_loadedSummary && !force) return;
    await refreshSummary();
  }

  Future<void> bootstrapHistory({bool force = false}) async {
    if (_loadingHistory) return;
    if (_loadedHistory && !force) return;
    await refreshHistory();
  }

  Future<void> refreshSummary() async {
    if (_loadingSummary) return;
    _loadingSummary = true;
    _summaryError = null;
    notifyListeners();
    try {
      _summary = await MobileApi.instance.supplierSummary();
      _loadedSummary = true;
    } catch (error) {
      _summaryError = error;
    } finally {
      _loadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> refreshHistory() async {
    if (_loadingHistory) return;
    _loadingHistory = true;
    _historyError = null;
    notifyListeners();
    try {
      _historyItems = await MobileApi.instance.supplierHistory();
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
      refreshSummary(),
      refreshHistory(),
    ]);
  }

  Future<void> bootstrapBreakdown(SupplierStatusKind kind,
      {bool force = false}) async {
    if (loadingBreakdown(kind)) return;
    if (_breakdownItems.containsKey(kind) && !force) return;
    await refreshBreakdown(kind);
  }

  Future<void> refreshBreakdown(SupplierStatusKind kind) async {
    if (loadingBreakdown(kind)) return;
    _loadingBreakdown[kind] = true;
    _breakdownErrors[kind] = null;
    try {
      _breakdownItems[kind] =
          await MobileApi.instance.supplierStatusBreakdown(kind);
    } catch (error) {
      _breakdownErrors[kind] = error;
    } finally {
      _loadingBreakdown[kind] = false;
      notifyListeners();
    }
  }

  Future<void> bootstrapDetail(SupplierStatusKind kind, String itemCode,
      {bool force = false}) async {
    final key = _detailKey(kind, itemCode);
    if (_loadingDetail[key] == true) return;
    if (_detailItems.containsKey(key) && !force) return;
    await refreshDetail(kind, itemCode);
  }

  Future<void> refreshDetail(SupplierStatusKind kind, String itemCode) async {
    final key = _detailKey(kind, itemCode);
    if (_loadingDetail[key] == true) return;
    _loadingDetail[key] = true;
    _detailErrors[key] = null;
    notifyListeners();
    try {
      _detailItems[key] = await MobileApi.instance.supplierStatusDetails(
        kind: kind,
        itemCode: itemCode,
      );
    } catch (error) {
      _detailErrors[key] = error;
    } finally {
      _loadingDetail[key] = false;
      notifyListeners();
    }
  }

  void recordCreatedPending() {
    SupplierRuntimeStore.instance.recordCreatedPending();
  }

  void recordUnannouncedDecision({
    required DispatchStatus fromStatus,
    required DispatchStatus toStatus,
  }) {
    SupplierRuntimeStore.instance.recordUnannouncedDecision(
      fromStatus: fromStatus,
      toStatus: toStatus,
    );
  }

  void _forwardRuntimeChange() {
    notifyListeners();
  }

  String _detailKey(SupplierStatusKind kind, String itemCode) =>
      '${kind.name}:${itemCode.trim()}';

  void clear() {
    _loadingSummary = false;
    _loadingHistory = false;
    _loadedSummary = false;
    _loadedHistory = false;
    _summaryError = null;
    _historyError = null;
    _loadingBreakdown.clear();
    _breakdownErrors.clear();
    _breakdownItems.clear();
    _loadingDetail.clear();
    _detailErrors.clear();
    _detailItems.clear();
    _summary = const SupplierHomeSummary(
      pendingCount: 0,
      submittedCount: 0,
      returnedCount: 0,
    );
    _historyItems = const <DispatchRecord>[];
    notifyListeners();
  }
}
