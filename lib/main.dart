import 'package:device_preview/device_preview.dart';
import 'src/app/app.dart';
import 'src/core/app_preview.dart';
import 'src/core/localization/locale_controller.dart';
import 'src/core/native_back_button_bridge.dart';
import 'src/core/native_dock_bridge.dart';
import 'src/core/notifications/local_notification_service.dart';
import 'src/core/notifications/push_messaging_service.dart';
import 'src/core/notifications/notification_unread_store.dart';
import 'src/core/security/security_controller.dart';
import 'src/core/session/app_session.dart';
import 'src/core/theme/theme_controller.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await _runStartupStep('native back button bridge', () async {
    await NativeBackButtonBridge.instance.initialize();
  });
  await _runStartupStep('native dock bridge', () async {
    await NativeDockBridge.instance.initialize();
  });
  await _runStartupStep(
    'local notifications',
    LocalNotificationService.instance.initialize,
  );
  await _runStartupStep('session', AppSession.instance.load);
  await _runStartupStep(
      'notification unread store', NotificationUnreadStore.instance.load);
  await _runStartupStep('security', SecurityController.instance.load);
  await _runStartupStep('theme', ThemeController.instance.load);
  await _runStartupStep('locale', LocaleController.instance.load);
  await _runStartupStep('platform helper', PlatformHelper.load);
  runApp(
    DevicePreview(
      enabled: AppPreview.enabled,
      builder: (_) => const ErpnextStockMobileApp(),
    ),
  );
  if (!kIsWeb) {
    unawaited(PushMessagingService.instance.initialize());
  }
}

Future<void> _runStartupStep(
  String label,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error, stackTrace) {
    debugPrint('startup step failed: $label -> $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
