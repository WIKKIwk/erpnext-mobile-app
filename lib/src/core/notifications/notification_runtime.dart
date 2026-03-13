import '../api/mobile_api.dart';
import 'refresh_hub.dart';
import 'notification_unread_store.dart';
import '../session/app_session.dart';
import '../../features/shared/models/app_models.dart';
import 'local_notification_service.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationRuntime extends StatefulWidget {
  const NotificationRuntime({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<NotificationRuntime> createState() => _NotificationRuntimeState();
}

class _NotificationRuntimeState extends State<NotificationRuntime>
    with WidgetsBindingObserver {
  static const String _snapshotPrefix = 'notification_snapshot_v1';
  Timer? _timer;
  bool _polling = false;
  String _lastUserKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _poll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _poll();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      _poll();
    });
  }

  Future<void> _poll() async {
    if (_polling) {
      return;
    }
    final profile = AppSession.instance.profile;
    if (profile == null ||
        (profile.role != UserRole.supplier && profile.role != UserRole.werka)) {
      return;
    }

    _polling = true;
    try {
      final userKey = '${profile.role.name}:${profile.ref}';
      if (_lastUserKey.isNotEmpty && _lastUserKey != userKey) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_snapshotPrefix:$_lastUserKey');
      }
      _lastUserKey = userKey;

      final records = profile.role == UserRole.supplier
          ? await MobileApi.instance.supplierHistory()
          : await MobileApi.instance.werkaHistory();

      await NotificationUnreadStore.instance.retainForProfile(
        profile: profile,
        ids: records.map((item) => item.id),
      );

      final current = <String, String>{
        for (final item in records) item.id: _signature(item),
      };

      final prefs = await SharedPreferences.getInstance();
      final storageKey = '$_snapshotPrefix:$userKey';
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) {
        await prefs.setString(storageKey, jsonEncode(current));
        return;
      }

      final previous = (jsonDecode(raw) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      );

      for (final record in records) {
        final next = _signature(record);
        final old = previous[record.id];
        if ((old == null || old != next) &&
            _shouldSurfaceForCurrentProfile(profile, record, hadPrevious: old != null)) {
          await NotificationUnreadStore.instance.markUnread(
            profile: profile,
            ids: [record.id],
          );
          RefreshHub.instance.emit(
            profile.role == UserRole.supplier ? 'supplier' : 'werka',
          );
          RefreshHub.instance.emit('admin');
          await LocalNotificationService.instance.showDispatchNotification(
            role: profile.role,
            record: record,
          );
        }
      }

      await prefs.setString(storageKey, jsonEncode(current));
    } catch (_) {
      // Best-effort runtime notifications.
    } finally {
      _polling = false;
    }
  }

  String _signature(DispatchRecord record) {
    return [
      record.status.name,
      record.note,
      record.sentQty.toStringAsFixed(4),
      record.acceptedQty.toStringAsFixed(4),
    ].join('|');
  }

  bool _shouldSurfaceForCurrentProfile(
    SessionProfile profile,
    DispatchRecord record, {
    required bool hadPrevious,
  }) {
    if (profile.role == UserRole.supplier) {
      if (record.eventType == 'werka_unannounced_pending') {
        return true;
      }
      if (!hadPrevious &&
          (record.status == DispatchStatus.pending ||
              record.status == DispatchStatus.draft)) {
        return false;
      }
      return true;
    }

    if (profile.role == UserRole.werka) {
      if (record.eventType == 'supplier_ack') {
        return true;
      }
      if (!hadPrevious &&
          record.eventType == 'werka_unannounced_pending') {
        return false;
      }
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
