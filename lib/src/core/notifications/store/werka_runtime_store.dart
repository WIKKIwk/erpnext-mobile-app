import '../../../features/shared/models/app_models.dart';
import 'package:flutter/foundation.dart';

class WerkaRuntimeStore extends ChangeNotifier {
  WerkaRuntimeStore._();

  static final WerkaRuntimeStore instance = WerkaRuntimeStore._();

  final Map<String, _WerkaMutation> _mutations = {};

  void recordCreatedPending(DispatchRecord record) {
    final id = record.id.trim();
    if (id.isEmpty) {
      return;
    }
    _mutations[id] = _WerkaMutation(
      before: null,
      after: record,
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
    _mutations[id] = _WerkaMutation(
      before: before,
      after: after,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void reconcileWithServer({
    required List<DispatchRecord> pendingItems,
    required List<DispatchRecord> historyItems,
  }) {
    final serverById = <String, DispatchRecord>{
      for (final item in pendingItems) item.id: item,
      for (final item in historyItems) item.id: item,
    };
    _mutations.removeWhere((id, mutation) {
      final server = serverById[id];
      if (server == null) {
        return false;
      }
      return _signature(server) == _signature(mutation.after);
    });
  }

  WerkaHomeSummary applySummary(WerkaHomeSummary summary) {
    var pending = summary.pendingCount;
    var confirmed = summary.confirmedCount;
    var returned = summary.returnedCount;
    for (final mutation in _activeMutations()) {
      final before = mutation.before;
      final after = mutation.after;

      if (before != null) {
        switch (_bucket(before.status)) {
          case _WerkaBucket.pending:
            pending -= 1;
          case _WerkaBucket.confirmed:
            confirmed -= 1;
          case _WerkaBucket.returned:
            returned -= 1;
          case _WerkaBucket.other:
            break;
        }
      }

      switch (_bucket(after.status)) {
        case _WerkaBucket.pending:
          pending += 1;
        case _WerkaBucket.confirmed:
          confirmed += 1;
        case _WerkaBucket.returned:
          returned += 1;
        case _WerkaBucket.other:
          break;
      }
    }
    return WerkaHomeSummary(
      pendingCount: pending < 0 ? 0 : pending,
      confirmedCount: confirmed < 0 ? 0 : confirmed,
      returnedCount: returned < 0 ? 0 : returned,
    );
  }

  List<DispatchRecord> applyPendingItems(List<DispatchRecord> items) {
    final byId = <String, DispatchRecord>{
      for (final item in items) item.id: item,
    };
    for (final mutation in _activeMutations()) {
      final after = mutation.after;
      if (_bucket(after.status) == _WerkaBucket.pending) {
        byId[after.id] = after;
      } else {
        byId.remove(after.id);
      }
    }
    final result = byId.values.toList();
    result.sort(
        (a, b) => compareCreatedLabelsDesc(a.createdLabel, b.createdLabel));
    return result;
  }

  void clear() {
    _mutations.clear();
    notifyListeners();
  }

  Iterable<_WerkaMutation> _activeMutations() sync* {
    final now = DateTime.now();
    for (final mutation in _mutations.values) {
      if (now.difference(mutation.createdAt) <= const Duration(seconds: 20)) {
        yield mutation;
      }
    }
  }

  _WerkaBucket _bucket(DispatchStatus status) {
    switch (status) {
      case DispatchStatus.pending:
      case DispatchStatus.draft:
        return _WerkaBucket.pending;
      case DispatchStatus.accepted:
        return _WerkaBucket.confirmed;
      case DispatchStatus.partial:
      case DispatchStatus.rejected:
      case DispatchStatus.cancelled:
        return _WerkaBucket.returned;
    }
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
}

class _WerkaMutation {
  const _WerkaMutation({
    required this.before,
    required this.after,
    required this.createdAt,
  });

  final DispatchRecord? before;
  final DispatchRecord after;
  final DateTime createdAt;
}

enum _WerkaBucket {
  pending,
  confirmed,
  returned,
  other,
}
