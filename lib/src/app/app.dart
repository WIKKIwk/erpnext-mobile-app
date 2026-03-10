import '../core/theme/app_theme.dart';
import '../core/app_preview.dart';
import '../core/security/app_lock_gate.dart';
import '../core/session/app_session.dart';
import '../core/theme/theme_controller.dart';
import 'app_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

class ErpnextStockMobileApp extends StatelessWidget {
  const ErpnextStockMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Accord',
          debugShowCheckedModeBanner: false,
          locale: AppPreview.enabled ? DevicePreview.locale(context) : null,
          builder: (context, child) {
            Widget current = child ?? const SizedBox.shrink();
            if (AppPreview.enabled) {
              current = DevicePreview.appBuilder(context, current);
            }
            return AppLockGate(child: current);
          },
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeController.instance.themeMode,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
            overscroll: false,
          ),
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppSession.instance.initialRoute,
        );
      },
    );
  }
}
