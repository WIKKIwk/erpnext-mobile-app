import '../../notifications/service/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevicePermissionsBootstrap {
  DevicePermissionsBootstrap._();

  static final DevicePermissionsBootstrap instance =
      DevicePermissionsBootstrap._();
  static const String _notificationPromptedKey = 'device_notification_prompted';

  bool _running = false;

  Future<void> runOnce() async {
    if (_running) {
      return;
    }
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool notificationPrompted =
          prefs.getBool(_notificationPromptedKey) ?? false;
      if (!notificationPrompted) {
        await LocalNotificationService.instance.requestPermission();
        await prefs.setBool(_notificationPromptedKey, true);
      }
    } catch (_) {
      // Best-effort startup permissions bootstrap.
    } finally {
      _running = false;
    }
  }
}
