import '../core/widgets/navigation/dock_gesture_overlay.dart';
import '../core/theme/app_theme.dart';
import '../core/app_preview.dart';
import '../core/localization/app_localizations.dart';
import '../core/localization/locale_controller.dart';
import '../core/native_back_button_bridge.dart';
import '../core/native_dock_bridge.dart';
import '../core/navigation/profile_route_overlay_notifier.dart';
import '../core/network/network_requirement_runtime.dart';
import '../core/notifications/runtime/notification_runtime.dart';
import '../core/security/gate/app_lock_gate.dart';
import '../core/theme/theme_controller.dart';
import 'app_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ErpnextStockMobileApp extends StatelessWidget {
  const ErpnextStockMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          title: AppLocalizations(LocaleController.instance.locale).appTitle,
          debugShowCheckedModeBanner: false,
          navigatorKey: NativeBackButtonBridge.instance.navigatorKey,
          navigatorObservers: [
            NativeBackButtonBridge.instance,
            NativeDockBridge.instance,
            ProfileRouteOverlayObserver.instance,
          ],
          locale: AppPreview.enabled
              ? DevicePreview.locale(context)
              : LocaleController.instance.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          builder: (context, child) {
            Widget current = child ?? const SizedBox.shrink();
            if (AppPreview.enabled) {
              current = DevicePreview.appBuilder(context, current);
            }
            final brightness = Theme.of(context).brightness;
            final overlayStyle = brightness == Brightness.dark
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    systemNavigationBarContrastEnforced: false,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    systemNavigationBarContrastEnforced: false,
                  );
            current = AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: current,
            );
            final wrapped = DockGestureOverlay(
              child: NetworkRequirementRuntime(
                child: NotificationRuntime(
                  child: AppLockGate(child: current),
                ),
              ),
            );
            return Localizations.override(
              context: context,
              locale: LocaleController.instance.locale,
              child: wrapped,
            );
          },
          theme: AppTheme.light(ThemeController.instance.variant),
          darkTheme: AppTheme.dark(ThemeController.instance.variant),
          themeMode: ThemeController.instance.themeMode,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
            overscroll: false,
          ),
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppPreview.startDirectPreviewRoute &&
                  AppPreview.initialRouteOverride != null
              ? AppPreview.initialRouteOverride!
              : AppRoutes.login,
        );
      },
    );
  }
}
