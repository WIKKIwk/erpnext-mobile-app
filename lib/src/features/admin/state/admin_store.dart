import '../../../core/api/mobile_api.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class AdminStore extends ChangeNotifier {
  AdminStore._();

  static final AdminStore instance = AdminStore._();

  bool _loadingSummary = false;
  bool _loadingActivity = false;
  bool _loadedSummary = false;
  bool _loadedActivity = false;
  Object? _summaryError;
  Object? _activityError;

  AdminSupplierSummary _summary = const AdminSupplierSummary(
    totalSuppliers: 0,
    activeSuppliers: 0,
    blockedSuppliers: 0,
  );
  List<DispatchRecord> _activityItems = const <DispatchRecord>[];

  bool get loadingSummary => _loadingSummary;
  bool get loadingActivity => _loadingActivity;
  bool get loadedSummary => _loadedSummary;
  bool get loadedActivity => _loadedActivity;
  Object? get summaryError => _summaryError;
  Object? get activityError => _activityError;
  AdminSupplierSummary get summary => _summary;
  List<DispatchRecord> get activityItems => _activityItems;

  Future<void> bootstrapSummary({bool force = false}) async {
    if (_loadingSummary) return;
    if (_loadedSummary && !force) return;
    await refreshSummary();
  }

  Future<void> bootstrapActivity({bool force = false}) async {
    if (_loadingActivity) return;
    if (_loadedActivity && !force) return;
    await refreshActivity();
  }

  Future<void> refreshSummary() async {
    if (_loadingSummary) return;
    _loadingSummary = true;
    _summaryError = null;
    notifyListeners();
    try {
      _summary = await MobileApi.instance.adminSupplierSummary();
      _loadedSummary = true;
    } catch (error) {
      _summaryError = error;
    } finally {
      _loadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> refreshActivity() async {
    if (_loadingActivity) return;
    _loadingActivity = true;
    _activityError = null;
    notifyListeners();
    try {
      _activityItems = await MobileApi.instance.adminActivity();
      _loadedActivity = true;
    } catch (error) {
      _activityError = error;
    } finally {
      _loadingActivity = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshSummary(),
      refreshActivity(),
    ]);
  }

  void clear() {
    _loadingSummary = false;
    _loadingActivity = false;
    _loadedSummary = false;
    _loadedActivity = false;
    _summaryError = null;
    _activityError = null;
    _summary = const AdminSupplierSummary(
      totalSuppliers: 0,
      activeSuppliers: 0,
      blockedSuppliers: 0,
    );
    _activityItems = const <DispatchRecord>[];
    notifyListeners();
  }
}
