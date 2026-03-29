import '../api/mobile_api.dart';
import '../../features/admin/state/admin_store.dart';
import '../../features/customer/state/customer_store.dart';
import '../../features/shared/data/profile_avatar_cache.dart';
import '../../features/shared/models/app_models.dart';
import '../../features/supplier/state/supplier_store.dart';
import '../../features/werka/state/werka_store.dart';
import '../notifications/customer_delivery_runtime_store.dart';
import '../notifications/notification_hidden_store.dart';
import '../notifications/notification_unread_store.dart';
import '../notifications/supplier_runtime_store.dart';
import '../notifications/werka_runtime_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRuntimeReset {
  AppRuntimeReset._();

  static final AppRuntimeReset instance = AppRuntimeReset._();

  Future<void> resetSessionScopedState({
    required SessionProfile? previousProfile,
  }) async {
    CustomerStore.instance.clear();
    SupplierStore.instance.clear();
    WerkaStore.instance.clear();
    AdminStore.instance.clear();
    CustomerDeliveryRuntimeStore.instance.clear();
    SupplierRuntimeStore.instance.clear();
    WerkaRuntimeStore.instance.clear();
    MobileApi.instance.clearSessionCaches();
    await NotificationUnreadStore.instance.clearAll();
    await NotificationHiddenStore.instance.clearAll();
    if (previousProfile != null) {
      await ProfileAvatarCache.clearForProfile(previousProfile);
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('notification_snapshot_v1:') ||
          key == 'cache_customer_notifications' ||
          key == 'cache_werka_notifications' ||
          key == 'last_login_phone' ||
          key == 'last_login_code') {
        await prefs.remove(key);
      }
    }
  }
}
