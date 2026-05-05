import '../../../core/api/mobile_api.dart';
import '../../../core/notifications/store/customer_delivery_runtime_store.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class CustomerStore extends ChangeNotifier {
  CustomerStore._() {
    CustomerDeliveryRuntimeStore.instance.addListener(_forwardRuntimeChange);
  }

  static final CustomerStore instance = CustomerStore._();

  bool _loading = false;
  bool _loaded = false;
  Object? _error;
  CustomerHomeSummary _summary = const CustomerHomeSummary(
    pendingCount: 0,
    confirmedCount: 0,
    rejectedCount: 0,
  );

  List<DispatchRecord> _pendingItems = const <DispatchRecord>[];
  List<DispatchRecord> _confirmedItems = const <DispatchRecord>[];
  List<DispatchRecord> _rejectedItems = const <DispatchRecord>[];
  List<DispatchRecord> _historyItems = const <DispatchRecord>[];

  bool get loading => _loading;
  bool get loaded => _loaded;
  Object? get error => _error;

  List<DispatchRecord> get pendingItems =>
      CustomerDeliveryRuntimeStore.instance.applyStatusList(
        CustomerStatusKind.pending,
        _pendingItems,
      );

  List<DispatchRecord> get confirmedItems =>
      CustomerDeliveryRuntimeStore.instance.applyStatusList(
        CustomerStatusKind.confirmed,
        _confirmedItems,
      );

  List<DispatchRecord> get rejectedItems =>
      CustomerDeliveryRuntimeStore.instance.applyStatusList(
        CustomerStatusKind.rejected,
        _rejectedItems,
      );

  List<DispatchRecord> get historyItems =>
      CustomerDeliveryRuntimeStore.instance.applyHistory(_historyItems);

  List<DispatchRecord> itemsForKind(CustomerStatusKind kind) {
    return switch (kind) {
      CustomerStatusKind.pending => pendingItems,
      CustomerStatusKind.confirmed => confirmedItems,
      CustomerStatusKind.rejected => rejectedItems,
    };
  }

  CustomerHomeSummary get summary =>
      CustomerDeliveryRuntimeStore.instance.applySummary(_summary);

  Future<void> bootstrap({bool force = false}) async {
    if (_loading) {
      return;
    }
    if (_loaded && !force) {
      return;
    }
    return refresh();
  }

  Future<void> refresh() async {
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        MobileApi.instance.customerSummary(),
        MobileApi.instance.customerStatusDetails(CustomerStatusKind.pending),
        MobileApi.instance.customerStatusDetails(CustomerStatusKind.confirmed),
        MobileApi.instance.customerStatusDetails(CustomerStatusKind.rejected),
      ]);
      _summary = results[0] as CustomerHomeSummary;
      _pendingItems = results[1] as List<DispatchRecord>;
      _confirmedItems = results[2] as List<DispatchRecord>;
      _rejectedItems = results[3] as List<DispatchRecord>;
      _historyItems = _mergeHistoryItems(
        _pendingItems,
        _confirmedItems,
        _rejectedItems,
      );
      _loaded = true;
      CustomerDeliveryRuntimeStore.instance.reconcileStatusLists(
        pendingItems: _pendingItems,
        confirmedItems: _confirmedItems,
        rejectedItems: _rejectedItems,
      );
      CustomerDeliveryRuntimeStore.instance.setStatusSnapshot(
        CustomerStatusKind.pending,
        _pendingItems,
      );
      CustomerDeliveryRuntimeStore.instance.setStatusSnapshot(
        CustomerStatusKind.confirmed,
        _confirmedItems,
      );
      CustomerDeliveryRuntimeStore.instance.setStatusSnapshot(
        CustomerStatusKind.rejected,
        _rejectedItems,
      );
    } catch (error) {
      _error = error;
      if (!_loaded) {
        _pendingItems = const <DispatchRecord>[];
        _confirmedItems = const <DispatchRecord>[];
        _rejectedItems = const <DispatchRecord>[];
        _historyItems = const <DispatchRecord>[];
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void applyDetailTransition({
    required DispatchRecord before,
    required DispatchRecord after,
  }) {
    CustomerDeliveryRuntimeStore.instance.recordTransition(
      before: before,
      after: after,
    );
  }

  void applyIncomingRecord(DispatchRecord record) {
    CustomerDeliveryRuntimeStore.instance.recordIncoming(record);
  }

  void _forwardRuntimeChange() {
    notifyListeners();
  }

  List<DispatchRecord> _mergeHistoryItems(
    List<DispatchRecord> pendingItems,
    List<DispatchRecord> confirmedItems,
    List<DispatchRecord> rejectedItems,
  ) {
    final byId = <String, DispatchRecord>{
      for (final item in pendingItems) item.id: item,
      for (final item in confirmedItems) item.id: item,
      for (final item in rejectedItems) item.id: item,
    };
    final result = byId.values.toList()
      ..sort(
          (a, b) => compareCreatedLabelsDesc(a.createdLabel, b.createdLabel));
    return result;
  }

  void clear() {
    _loading = false;
    _loaded = false;
    _error = null;
    _summary = const CustomerHomeSummary(
      pendingCount: 0,
      confirmedCount: 0,
      rejectedCount: 0,
    );
    _pendingItems = const <DispatchRecord>[];
    _confirmedItems = const <DispatchRecord>[];
    _rejectedItems = const <DispatchRecord>[];
    _historyItems = const <DispatchRecord>[];
    notifyListeners();
  }
}
