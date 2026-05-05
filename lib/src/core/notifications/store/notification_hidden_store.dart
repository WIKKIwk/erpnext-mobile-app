import '../../session/session.dart';
import '../../../features/shared/models/app_models.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHiddenStore extends ChangeNotifier {
  NotificationHiddenStore._();

  static final NotificationHiddenStore instance = NotificationHiddenStore._();
  static const String _prefsKey = 'notification_hidden_v1';

  final Map<String, Set<String>> _hiddenByUser = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final list = (entry.value as List<dynamic>).cast<String>();
        _hiddenByUser[entry.key] = list.toSet();
      }
    }
    _loaded = true;
  }

  Set<String> hiddenIdsForProfile(SessionProfile? profile) {
    final key = _userKey(profile);
    if (key == null) {
      return <String>{};
    }
    return Set<String>.from(_hiddenByUser[key] ?? const <String>{});
  }

  Future<void> hideAll({
    required SessionProfile? profile,
    required Iterable<String> ids,
  }) async {
    final key = _userKey(profile);
    if (key == null) {
      return;
    }
    await load();
    final set = _hiddenByUser.putIfAbsent(key, () => <String>{});
    var changed = false;
    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      changed = set.add(trimmed) || changed;
    }
    if (!changed) {
      return;
    }
    await _persist();
    notifyListeners();
  }

  String? _userKey(SessionProfile? profile) {
    final current = profile ?? AppSession.instance.profile;
    if (current == null) {
      return null;
    }
    return '${current.role.name}:${current.ref}';
  }

  Future<void> clearAll() async {
    _hiddenByUser.clear();
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, List<String>>{};
    for (final entry in _hiddenByUser.entries) {
      payload[entry.key] = entry.value.toList()..sort();
    }
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }
}
