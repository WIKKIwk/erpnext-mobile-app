import '../../session/session.dart';
import '../../../features/shared/models/app_models.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationUnreadStore extends ChangeNotifier {
  NotificationUnreadStore._();

  static final NotificationUnreadStore instance = NotificationUnreadStore._();
  static const String _prefsKey = 'notification_unread_v1';

  final Map<String, Set<String>> _unreadByUser = {};
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
        _unreadByUser[entry.key] = list.toSet();
      }
    }
    _loaded = true;
  }

  Set<String> unreadIdsForProfile(SessionProfile? profile) {
    final key = _userKey(profile);
    if (key == null) {
      return <String>{};
    }
    return Set<String>.from(_unreadByUser[key] ?? const <String>{});
  }

  bool hasUnreadForProfile(SessionProfile? profile) {
    final key = _userKey(profile);
    if (key == null) {
      return false;
    }
    return (_unreadByUser[key] ?? const <String>{}).isNotEmpty;
  }

  Future<void> markUnread({
    required SessionProfile? profile,
    required Iterable<String> ids,
  }) async {
    final key = _userKey(profile);
    if (key == null) {
      return;
    }
    await load();
    final set = _unreadByUser.putIfAbsent(key, () => <String>{});
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

  Future<void> markSeen({
    required SessionProfile? profile,
    required Iterable<String> ids,
  }) async {
    final key = _userKey(profile);
    if (key == null) {
      return;
    }
    await load();
    final set = _unreadByUser[key];
    if (set == null || set.isEmpty) {
      return;
    }
    var changed = false;
    for (final id in ids) {
      changed = set.remove(id.trim()) || changed;
    }
    if (!changed) {
      return;
    }
    if (set.isEmpty) {
      _unreadByUser.remove(key);
    }
    await _persist();
    notifyListeners();
  }

  Future<Set<String>> consumeUnread({
    required SessionProfile? profile,
    required Iterable<String> ids,
  }) async {
    final key = _userKey(profile);
    if (key == null) {
      return <String>{};
    }
    await load();
    final set = _unreadByUser[key];
    if (set == null || set.isEmpty) {
      return <String>{};
    }
    final requested =
        ids.map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
    final highlighted = set.intersection(requested);
    if (highlighted.isEmpty) {
      return <String>{};
    }
    set.removeAll(highlighted);
    if (set.isEmpty) {
      _unreadByUser.remove(key);
    }
    await _persist();
    notifyListeners();
    return highlighted;
  }

  Future<void> retainForProfile({
    required SessionProfile? profile,
    required Iterable<String> ids,
  }) async {
    final key = _userKey(profile);
    if (key == null) {
      return;
    }
    await load();
    final set = _unreadByUser[key];
    if (set == null || set.isEmpty) {
      return;
    }
    final allowed =
        ids.map((item) => item.trim()).where((item) => item.isNotEmpty).toSet();
    final filtered = set.intersection(allowed);
    if (set.length == filtered.length) {
      return;
    }
    if (filtered.isEmpty) {
      _unreadByUser.remove(key);
    } else {
      _unreadByUser[key] = filtered;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _unreadByUser.clear();
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    notifyListeners();
  }

  String? _userKey(SessionProfile? profile) {
    final current = profile ?? AppSession.instance.profile;
    if (current == null) {
      return null;
    }
    return '${current.role.name}:${current.ref}';
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, List<String>>{};
    for (final entry in _unreadByUser.entries) {
      payload[entry.key] = entry.value.toList()..sort();
    }
    await prefs.setString(_prefsKey, jsonEncode(payload));
  }
}
