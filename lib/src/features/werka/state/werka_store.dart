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

  WerkaHomeSummary get summary => WerkaRuntimeStore.instance.applySummary(_summary);
  List<DispatchRecord> get pendingItems =>
      WerkaRuntimeStore.instance.applyPendingItems(_pendingItems);
  List<DispatchRecord> get historyItems => _historyItems;

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
      final results = await Future.wait<dynamic>([
        MobileApi.instance.werkaSummary(),
        MobileApi.instance.werkaPending(),
      ]);
      _summary = results[0] as WerkaHomeSummary;
      _pendingItems = results[1] as List<DispatchRecord>;
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

  @visibleForTesting
  void clear() {
    _loadingHome = false;
    _loadingHistory = false;
    _loadedHome = false;
    _loadedHistory = false;
    _homeError = null;
    _historyError = null;
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
