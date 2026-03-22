import '../core/theme/app_theme.dart';
import '../core/app_preview.dart';
import 'app_navigation.dart';
import '../core/localization/app_localizations.dart';
import '../core/localization/locale_controller.dart';
import '../core/network/network_requirement_runtime.dart';
import '../core/notifications/notification_runtime.dart';
import '../core/security/app_lock_gate.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/ios_dock_runtime.dart';
import 'app_router.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
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
          navigatorKey: appNavigatorKey,
          navigatorObservers: [AppRouteTracker.instance],
          title: AppLocalizations(LocaleController.instance.locale).appTitle,
          debugShowCheckedModeBanner: false,
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
            final wrapped = NetworkRequirementRuntime(
              child: NotificationRuntime(
                child: AppLockGate(
                  child: IOSDockRuntime(child: current),
                ),
              ),
            );
            return Localizations.override(
              context: context,
              locale: LocaleController.instance.locale,
              child: wrapped,
            );
          },
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeController.instance.themeMode,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: false,
            overscroll: false,
          ),
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRoutes.login,
        );
      },
    );
  }
}
