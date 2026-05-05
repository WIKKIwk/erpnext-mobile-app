import '../../../features/shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class CustomerDeliveryRuntimeStore extends ChangeNotifier {
  CustomerDeliveryRuntimeStore._();

  static final CustomerDeliveryRuntimeStore instance =
      CustomerDeliveryRuntimeStore._();

  final Map<String, _CustomerDeliveryMutation> _mutations = {};
  final Map<CustomerStatusKind, List<DispatchRecord>> _latestStatusLists = {};

  void recordIncoming(DispatchRecord record) {
    final id = record.id.trim();
    if (id.isEmpty) {
      return;
    }
    _mutations[id] = _CustomerDeliveryMutation(
      before: null,
      updated: record,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void recordTransition({
    required DispatchRecord before,
    required DispatchRecord after,
  }) {
    final id = after.id.trim();
    if (id.isEmpty) {
      return;
    }
    _mutations[id] = _CustomerDeliveryMutation(
      before: before,
      updated: after,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void reconcileStatusLists({
    required List<DispatchRecord> pendingItems,
    required List<DispatchRecord> confirmedItems,
    required List<DispatchRecord> rejectedItems,
  }) {
    final serverById = <String, DispatchRecord>{
      for (final item in pendingItems) item.id: item,
      for (final item in confirmedItems) item.id: item,
      for (final item in rejectedItems) item.id: item,
    };
    _reconcileWith(serverById);
  }

  void clear() {
    _mutations.clear();
    _latestStatusLists.clear();
    notifyListeners();
  }

  CustomerHomeSummary applySummary(CustomerHomeSummary summary) {
    var pending = _latestStatusLists[CustomerStatusKind.pending]?.length ??
        summary.pendingCount;
    var confirmed = _latestStatusLists[CustomerStatusKind.confirmed]?.length ??
        summary.confirmedCount;
    var rejected = _latestStatusLists[CustomerStatusKind.rejected]?.length ??
        summary.rejectedCount;

    for (final mutation in _activeMutations()) {
      if (mutation.before case final before?) {
        switch (before.status) {
          case DispatchStatus.pending:
            pending -= 1;
          case DispatchStatus.accepted:
            confirmed -= 1;
          case DispatchStatus.partial:
          case DispatchStatus.rejected:
            rejected -= 1;
          default:
            break;
        }
      }

      switch (mutation.updated.status) {
        case DispatchStatus.pending:
          pending += 1;
        case DispatchStatus.accepted:
          confirmed += 1;
        case DispatchStatus.partial:
        case DispatchStatus.rejected:
          rejected += 1;
        default:
          break;
      }
    }

    return CustomerHomeSummary(
      pendingCount: pending < 0 ? 0 : pending,
      confirmedCount: confirmed < 0 ? 0 : confirmed,
      rejectedCount: rejected < 0 ? 0 : rejected,
    );
  }

  void setStatusSnapshot(
    CustomerStatusKind kind,
    List<DispatchRecord> items,
  ) {
    final next = List<DispatchRecord>.unmodifiable(items);
    final previous = _latestStatusLists[kind];
    if (_sameRecords(previous, next)) {
      return;
    }
    _latestStatusLists[kind] = next;
    notifyListeners();
  }

  List<DispatchRecord> applyStatusList(
    CustomerStatusKind kind,
    List<DispatchRecord> items,
  ) {
    final byId = <String, DispatchRecord>{
      for (final item in items) item.id: item,
    };
    for (final mutation in _activeMutations()) {
      final matchesTarget = switch (kind) {
        CustomerStatusKind.pending =>
          mutation.updated.status == DispatchStatus.pending,
        CustomerStatusKind.confirmed =>
          mutation.updated.status == DispatchStatus.accepted,
        CustomerStatusKind.rejected =>
          mutation.updated.status == DispatchStatus.rejected ||
              mutation.updated.status == DispatchStatus.partial,
      };
      if (matchesTarget) {
        byId[mutation.updated.id] = mutation.updated;
      } else {
        byId.remove(mutation.updated.id);
      }
    }
    return _sorted(byId.values);
  }

  List<DispatchRecord> applyHistory(List<DispatchRecord> items) {
    final byId = <String, DispatchRecord>{
      for (final item in items) item.id: item,
    };
    for (final mutation in _activeMutations()) {
      if (byId.containsKey(mutation.updated.id)) {
        byId[mutation.updated.id] = mutation.updated;
      }
    }
    return _sorted(byId.values);
  }

  Iterable<_CustomerDeliveryMutation> _activeMutations() sync* {
    final now = DateTime.now();
    for (final mutation in _mutations.values) {
      if (now.difference(mutation.createdAt) <= const Duration(seconds: 20)) {
        yield mutation;
      }
    }
  }

  List<DispatchRecord> _sorted(Iterable<DispatchRecord> records) {
    final result = records.toList();
    result.sort(
        (a, b) => compareCreatedLabelsDesc(a.createdLabel, b.createdLabel));
    return result;
  }

  void _reconcileWith(Map<String, DispatchRecord> serverById) {
    _mutations.removeWhere((id, mutation) {
      final server = serverById[id];
      if (server == null) {
        return false;
      }
      return _signature(server) == _signature(mutation.updated);
    });
  }

  String _signature(DispatchRecord record) {
    return [
      record.id,
      record.status.name,
      record.sentQty.toStringAsFixed(4),
      record.acceptedQty.toStringAsFixed(4),
      record.note.trim(),
    ].join('|');
  }

  bool _sameRecords(
    List<DispatchRecord>? a,
    List<DispatchRecord> b,
  ) {
    if (a == null || a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (_signature(a[index]) != _signature(b[index])) {
        return false;
      }
    }
    return true;
  }
}

class _CustomerDeliveryMutation {
  const _CustomerDeliveryMutation({
    required this.before,
    required this.updated,
    required this.createdAt,
  });

  final DispatchRecord? before;
  final DispatchRecord updated;
  final DateTime createdAt;
}
