import '../../features/shared/models/app_models.dart';
import '../session/session.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchActivityStore {
  SearchActivityStore._();

  static final SearchActivityStore instance = SearchActivityStore._();
  static const String _itemCountsPrefix = 'search_item_activity_v1';
  static const int _maxStoredItems = 200;

  SharedPreferences? _prefs;
  String _loadedScope = '';
  Map<String, int> _itemCounts = <String, int>{};

  Future<void> recordItemSelection(String itemCode) async {
    await recordItemSelections([itemCode]);
  }

  Future<void> recordItemSelections(Iterable<String> itemCodes) async {
    await _ensureLoaded();
    var changed = false;
    for (final itemCode in itemCodes) {
      final key = _normalizeItemCode(itemCode);
      if (key.isEmpty) {
        continue;
      }
      _itemCounts[key] = (_itemCounts[key] ?? 0) + 1;
      changed = true;
    }
    if (!changed) {
      return;
    }
    _trimCounts();
    await _save();
  }

  Future<List<T>> sortByItemCode<T>(
    Iterable<T> items, {
    required String Function(T item) itemCode,
    required int Function(T left, T right) fallback,
  }) async {
    await _ensureLoaded();
    final sorted = items.toList(growable: false);
    sorted.sort((left, right) {
      final rightCount = _itemCounts[_normalizeItemCode(itemCode(right))] ?? 0;
      final leftCount = _itemCounts[_normalizeItemCode(itemCode(left))] ?? 0;
      final activityCompare = rightCount.compareTo(leftCount);
      if (activityCompare != 0) {
        return activityCompare;
      }
      return fallback(left, right);
    });
    return sorted;
  }

  @visibleForTesting
  Future<void> debugReset() async {
    _prefs = null;
    _loadedScope = '';
    _itemCounts = <String, int>{};
  }

  Future<void> _ensureLoaded() async {
    _prefs ??= await SharedPreferences.getInstance();
    final scope = _currentScope();
    if (_loadedScope == scope) {
      return;
    }
    _loadedScope = scope;
    final raw = _prefs!.getString(_prefsKey(scope));
    if (raw == null || raw.trim().isEmpty) {
      _itemCounts = <String, int>{};
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _itemCounts = <String, int>{};
        return;
      }
      _itemCounts = <String, int>{
        for (final entry in decoded.entries)
          _normalizeItemCode(entry.key): (entry.value as num?)?.toInt() ?? 0,
      }..removeWhere((key, value) => key.isEmpty || value <= 0);
    } catch (_) {
      _itemCounts = <String, int>{};
    }
  }

  Future<void> _save() async {
    await _prefs!.setString(_prefsKey(_loadedScope), jsonEncode(_itemCounts));
  }

  void _trimCounts() {
    if (_itemCounts.length <= _maxStoredItems) {
      return;
    }
    final entries = _itemCounts.entries.toList()
      ..sort((left, right) {
        final countCompare = right.value.compareTo(left.value);
        if (countCompare != 0) {
          return countCompare;
        }
        return left.key.compareTo(right.key);
      });
    _itemCounts = Map<String, int>.fromEntries(
      entries.take(_maxStoredItems),
    );
  }

  String _currentScope() {
    final SessionProfile? profile = AppSession.instance.profile;
    if (profile == null) {
      return 'guest';
    }
    return '${profile.role.name}:${profile.ref.trim().toLowerCase()}';
  }

  String _prefsKey(String scope) => '$_itemCountsPrefix:$scope';

  String _normalizeItemCode(String value) => value.trim().toLowerCase();
}
