import '../../api/mobile_api.dart';
import '../store/customer_delivery_runtime_store.dart';
import '../hub/refresh_hub.dart';
import '../store/notification_unread_store.dart';
import '../../session/session.dart';
import '../../../features/shared/models/app_models.dart';
import 'local_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  await Firebase.initializeApp();
}

class PushMessagingService {
  PushMessagingService._();

  static final PushMessagingService instance = PushMessagingService._();
  bool _initialized = false;

  bool get _supportsRemotePush =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  bool get _shouldInitializePushOnThisDevice =>
      defaultTargetPlatform == TargetPlatform.android ||
      (defaultTargetPlatform == TargetPlatform.iOS &&
          !PlatformHelper.isIOSSimulator);

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return defaultTargetPlatform.name;
    }
  }

  Future<void> initialize() async {
    if (_initialized ||
        !_supportsRemotePush ||
        !_shouldInitializePushOnThisDevice) {
      return;
    }

    debugPrint('push initialize start platform=$_platformName');
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      final apnsToken = await messaging.getAPNSToken();
      debugPrint(
        'push initialize apns token=${maskPushToken(apnsToken ?? '')}',
      );
    }

    await syncCurrentToken();

    messaging.onTokenRefresh.listen((token) async {
      debugPrint(
        'push token refresh platform=$_platformName token=${maskPushToken(token)}',
      );
      if (AppSession.instance.isLoggedIn) {
        await MobileApi.instance.registerPushToken(
          tokenValue: token,
          platform: _platformName,
        );
      }
    });

    FirebaseMessaging.onMessage.listen((message) async {
      final data = message.data;
      final profile = AppSession.instance.profile;
      final targetRole = (data['target_role'] ?? '').trim();
      final targetRef = (data['target_ref'] ?? '').trim();
      if (profile == null) {
        return;
      }
      if (targetRole.isNotEmpty && targetRole != profile.role.name) {
        return;
      }
      if (targetRef.isNotEmpty && targetRef != profile.ref) {
        return;
      }
      final record = DispatchRecord(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        recordType: data['record_type'] ?? '',
        supplierRef: data['supplier_ref'] ?? '',
        supplierName: data['supplier_name'] ?? '',
        itemCode: data['item_code'] ?? '',
        itemName: data['item_name'] ?? '',
        uom: data['uom'] ?? '',
        sentQty: double.tryParse('${data['sent_qty'] ?? 0}') ?? 0,
        acceptedQty: double.tryParse('${data['accepted_qty'] ?? 0}') ?? 0,
        amount: double.tryParse('${data['amount'] ?? 0}') ?? 0,
        currency: data['currency'] ?? '',
        note: data['note'] ?? '',
        eventType: data['event_type'] ?? '',
        highlight: data['highlight'] ?? '',
        status: parseDispatchStatus(data['status'] ?? 'pending'),
        createdLabel: data['created_label'] ?? '',
      );
      await NotificationUnreadStore.instance.markUnread(
        profile: profile,
        ids: [record.id],
      );
      if (profile.role == UserRole.customer &&
          record.status == DispatchStatus.pending) {
        CustomerDeliveryRuntimeStore.instance.recordIncoming(record);
      }
      RefreshHub.instance.emit(profile.role.name);
      await LocalNotificationService.instance.showDispatchNotification(
        role: profile.role,
        record: record,
      );
    });

    _initialized = true;
    debugPrint('push initialize complete platform=$_platformName');
  }

  Future<void> syncCurrentToken() async {
    final profile = AppSession.instance.profile;
    debugPrint(
      'push sync start logged_in=${AppSession.instance.isLoggedIn} '
      'platform=$_platformName '
      'role=${profile?.role.name ?? 'none'} '
      'ref=${profile?.ref ?? ''}',
    );
    if (!_supportsRemotePush ||
        !_shouldInitializePushOnThisDevice ||
        !AppSession.instance.isLoggedIn) {
      debugPrint(
        'push sync skipped: unsupported platform, simulator, or not logged in',
      );
      return;
    }
    if (Firebase.apps.isEmpty) {
      debugPrint('push sync skipped: Firebase is not initialized');
      return;
    }
    final messaging = FirebaseMessaging.instance;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await messaging.getAPNSToken();
      debugPrint(
        'push sync apns token=${maskPushToken(apnsToken ?? '')}',
      );
    }
    final token = await messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('push sync skipped: Firebase token is empty');
      return;
    }
    debugPrint(
      'push sync obtained platform=$_platformName token=${maskPushToken(token)}',
    );
    await MobileApi.instance.registerPushToken(
      tokenValue: token,
      platform: _platformName,
    );
    debugPrint(
      'push sync stored platform=$_platformName token=${maskPushToken(token)}',
    );
  }

  Future<void> unregisterCurrentToken() async {
    if (!_supportsRemotePush ||
        !_shouldInitializePushOnThisDevice ||
        !AppSession.instance.isLoggedIn) {
      debugPrint(
        'push unregister skipped: unsupported platform, simulator, or not logged in',
      );
      return;
    }
    if (Firebase.apps.isEmpty) {
      debugPrint('push unregister skipped: Firebase is not initialized');
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('push unregister skipped: Firebase token is empty');
      return;
    }
    debugPrint(
      'push unregister platform=$_platformName token=${maskPushToken(token)}',
    );
    await MobileApi.instance.unregisterPushToken(token);
  }
}

class PlatformHelper {
  const PlatformHelper._();

  static bool get isIOSSimulator {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    return _isIOSSimulator;
  }

  static bool _isIOSSimulator = false;

  static Future<void> load() async {
    if (defaultTargetPlatform != TargetPlatform.iOS || kIsWeb) {
      _isIOSSimulator = false;
      return;
    }
    const channel = MethodChannel('accord/device_info');
    try {
      _isIOSSimulator =
          (await channel.invokeMethod<bool>('isIOSSimulator')) ?? false;
    } catch (_) {
      _isIOSSimulator = false;
    }
  }
}
