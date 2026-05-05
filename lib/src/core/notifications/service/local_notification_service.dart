import '../../../features/shared/models/app_models.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'accord_updates',
    'Accord Updates',
    description: 'Supplier va werka holatlari uchun system bildirishnomalar',
    importance: Importance.max,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );
    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    _initialized = true;
  }

  Future<void> requestPermission() async {
    await initialize();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> showDispatchNotification({
    required UserRole role,
    required DispatchRecord record,
  }) async {
    await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
    );

    await _plugin.show(
      record.id.hashCode,
      _title(role, record),
      _body(role, record),
      details,
    );
  }

  String _title(UserRole role, DispatchRecord record) {
    if (role == UserRole.supplier) {
      return record.itemCode;
    }
    if (role == UserRole.customer) {
      return record.itemCode;
    }
    return record.supplierName;
  }

  String _body(UserRole role, DispatchRecord record) {
    final suffix = record.note.trim().isEmpty ? '' : '\n${record.note}';
    if (role == UserRole.supplier) {
      switch (record.status) {
        case DispatchStatus.pending:
        case DispatchStatus.draft:
          return 'Jo‘natildi: ${record.sentQty.toStringAsFixed(0)} ${record.uom}.$suffix';
        case DispatchStatus.accepted:
          return 'Werka ${record.acceptedQty.toStringAsFixed(0)} ${record.uom} oldi.$suffix';
        case DispatchStatus.partial:
          return 'Qisman olindi: ${record.acceptedQty.toStringAsFixed(0)} ${record.uom}.$suffix';
        case DispatchStatus.rejected:
          return 'Rad etildi.$suffix';
        case DispatchStatus.cancelled:
          return 'Bekor qilindi.$suffix';
      }
    }

    if (role == UserRole.customer) {
      switch (record.status) {
        case DispatchStatus.pending:
        case DispatchStatus.draft:
          return '${record.sentQty.toStringAsFixed(0)} ${record.uom} jo‘natildi.$suffix';
        case DispatchStatus.accepted:
          return 'Qabul qilindi: ${record.acceptedQty.toStringAsFixed(0)} ${record.uom}.$suffix';
        case DispatchStatus.rejected:
          return 'Rad etildi.$suffix';
        case DispatchStatus.partial:
        case DispatchStatus.cancelled:
          return suffix.trim().isEmpty ? 'Holat o‘zgardi.' : suffix.trim();
      }
    }

    switch (record.status) {
      case DispatchStatus.pending:
      case DispatchStatus.draft:
        return '${record.itemCode} • ${record.sentQty.toStringAsFixed(0)} ${record.uom} qabul kutmoqda.$suffix';
      case DispatchStatus.accepted:
        return '${record.acceptedQty.toStringAsFixed(0)} ${record.uom} qabul qilindi.$suffix';
      case DispatchStatus.partial:
        return 'Qisman qabul qilindi: ${record.acceptedQty.toStringAsFixed(0)} ${record.uom}.$suffix';
      case DispatchStatus.rejected:
        return 'Qabul rad etildi.$suffix';
      case DispatchStatus.cancelled:
        return 'Jarayon bekor qilindi.$suffix';
    }
  }
}
