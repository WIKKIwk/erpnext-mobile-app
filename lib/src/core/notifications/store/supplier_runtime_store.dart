import '../../../features/shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class SupplierRuntimeStore extends ChangeNotifier {
  SupplierRuntimeStore._();

  static final SupplierRuntimeStore instance = SupplierRuntimeStore._();

  final List<_SupplierSummaryMutation> _mutations = [];

  void recordCreatedPending() {
    _mutations.add(
      _SupplierSummaryMutation(
        pendingDelta: 1,
        submittedDelta: 0,
        returnedDelta: 0,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void recordUnannouncedDecision({
    required DispatchStatus fromStatus,
    required DispatchStatus toStatus,
  }) {
    if (fromStatus == toStatus) {
      return;
    }
    int pending = 0;
    int submitted = 0;
    int returned = 0;

    switch (fromStatus) {
      case DispatchStatus.pending:
      case DispatchStatus.draft:
        pending -= 1;
      case DispatchStatus.accepted:
        submitted -= 1;
      case DispatchStatus.partial:
      case DispatchStatus.rejected:
      case DispatchStatus.cancelled:
        returned -= 1;
    }

    switch (toStatus) {
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

    _mutations.add(
      _SupplierSummaryMutation(
        pendingDelta: pending,
        submittedDelta: submitted,
        returnedDelta: returned,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  SupplierHomeSummary applySummary(SupplierHomeSummary summary) {
    var pending = summary.pendingCount;
    var submitted = summary.submittedCount;
    var returned = summary.returnedCount;
    for (final mutation in _activeMutations()) {
      pending += mutation.pendingDelta;
      submitted += mutation.submittedDelta;
      returned += mutation.returnedDelta;
    }
    return SupplierHomeSummary(
      pendingCount: pending < 0 ? 0 : pending,
      submittedCount: submitted < 0 ? 0 : submitted,
      returnedCount: returned < 0 ? 0 : returned,
    );
  }

  void clear() {
    _mutations.clear();
    notifyListeners();
  }

  Iterable<_SupplierSummaryMutation> _activeMutations() sync* {
    final now = DateTime.now();
    for (final mutation in _mutations) {
      if (now.difference(mutation.createdAt) <= const Duration(seconds: 20)) {
        yield mutation;
      }
    }
  }
}

class _SupplierSummaryMutation {
  const _SupplierSummaryMutation({
    required this.pendingDelta,
    required this.submittedDelta,
    required this.returnedDelta,
    required this.createdAt,
  });

  final int pendingDelta;
  final int submittedDelta;
  final int returnedDelta;
  final DateTime createdAt;
}
