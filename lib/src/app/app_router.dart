import '../features/auth/presentation/login_screen.dart';
import '../features/admin/presentation/admin_create_hub_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/admin_inactive_suppliers_screen.dart';
import '../features/admin/presentation/admin_item_create_screen.dart';
import '../features/admin/presentation/admin_settings_screen.dart';
import '../features/admin/presentation/admin_supplier_detail_screen.dart';
import '../features/admin/presentation/admin_suppliers_screen.dart';
import '../features/admin/presentation/admin_werka_screen.dart';
import '../features/shared/models/app_models.dart';
import '../features/shared/presentation/profile_screen.dart';
import '../features/supplier/presentation/supplier_confirm_screen.dart';
import '../features/supplier/presentation/supplier_home_screen.dart';
import '../features/supplier/presentation/supplier_item_picker_screen.dart';
import '../features/supplier/presentation/supplier_notifications_screen.dart';
import '../features/supplier/presentation/supplier_qty_screen.dart';
import '../features/supplier/presentation/supplier_recent_screen.dart';
import '../features/supplier/presentation/supplier_success_screen.dart';
import '../features/werka/presentation/werka_detail_screen.dart';
import '../features/werka/presentation/werka_home_screen.dart';
import '../features/werka/presentation/werka_success_screen.dart';
import '../core/theme/app_motion.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/';
  static const String supplierHome = '/supplier-home';
  static const String supplierItemPicker = '/supplier-item-picker';
  static const String supplierQty = '/supplier-qty';
  static const String supplierConfirm = '/supplier-confirm';
  static const String supplierSuccess = '/supplier-success';
  static const String supplierNotifications = '/supplier-notifications';
  static const String supplierRecent = '/supplier-recent';
  static const String werkaHome = '/werka-home';
  static const String werkaDetail = '/werka-detail';
  static const String werkaSuccess = '/werka-success';
  static const String profile = '/profile';
  static const String adminHome = '/admin-home';
  static const String adminCreateHub = '/admin-create-hub';
  static const String adminSettings = '/admin-settings';
  static const String adminSuppliers = '/admin-suppliers';
  static const String adminInactiveSuppliers = '/admin-inactive-suppliers';
  static const String adminItemCreate = '/admin-item-create';
  static const String adminSupplierDetail = '/admin-supplier-detail';
  static const String adminWerka = '/admin-werka';
}

class AppRouter {
  static const Set<String> staticDockRoutes = {
    AppRoutes.supplierHome,
    AppRoutes.supplierNotifications,
    AppRoutes.supplierRecent,
    AppRoutes.werkaHome,
    AppRoutes.adminHome,
    AppRoutes.adminCreateHub,
    AppRoutes.adminSettings,
    AppRoutes.adminSuppliers,
    AppRoutes.adminWerka,
    AppRoutes.profile,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _buildRoute(settings, const LoginScreen());
      case AppRoutes.supplierHome:
        return _buildRoute(settings, const SupplierHomeScreen());
      case AppRoutes.supplierItemPicker:
        return _buildRoute(settings, const SupplierItemPickerScreen());
      case AppRoutes.supplierQty:
        final SupplierItem item = settings.arguments as SupplierItem;
        return _buildRoute(settings, SupplierQtyScreen(item: item));
      case AppRoutes.supplierConfirm:
        final SupplierConfirmArgs args =
            settings.arguments as SupplierConfirmArgs;
        return _buildRoute(settings, SupplierConfirmScreen(args: args));
      case AppRoutes.supplierSuccess:
        final DispatchRecord record = settings.arguments as DispatchRecord;
        return _buildRoute(settings, SupplierSuccessScreen(record: record));
      case AppRoutes.supplierNotifications:
        return _buildRoute(settings, const SupplierNotificationsScreen());
      case AppRoutes.supplierRecent:
        return _buildRoute(settings, const SupplierRecentScreen());
      case AppRoutes.werkaHome:
        return _buildRoute(settings, const WerkaHomeScreen());
      case AppRoutes.werkaDetail:
        final DispatchRecord record = settings.arguments as DispatchRecord;
        return _buildRoute(settings, WerkaDetailScreen(record: record));
      case AppRoutes.werkaSuccess:
        final DispatchRecord record = settings.arguments as DispatchRecord;
        return _buildRoute(settings, WerkaSuccessScreen(record: record));
      case AppRoutes.profile:
        return _buildRoute(settings, const ProfileScreen());
      case AppRoutes.adminHome:
        return _buildRoute(settings, const AdminHomeScreen());
      case AppRoutes.adminCreateHub:
        return _buildRoute(settings, const AdminCreateHubScreen());
      case AppRoutes.adminSettings:
        return _buildRoute(settings, const AdminSettingsScreen());
      case AppRoutes.adminSuppliers:
        return _buildRoute(settings, const AdminSuppliersScreen());
      case AppRoutes.adminInactiveSuppliers:
        return _buildRoute(settings, const AdminInactiveSuppliersScreen());
      case AppRoutes.adminItemCreate:
        return _buildRoute(settings, const AdminItemCreateScreen());
      case AppRoutes.adminSupplierDetail:
        final String supplierRef = settings.arguments as String;
        return _buildRoute(
          settings,
          AdminSupplierDetailScreen(supplierRef: supplierRef),
        );
      case AppRoutes.adminWerka:
        return _buildRoute(settings, const AdminWerkaScreen());
      default:
        return _buildRoute(settings, const LoginScreen());
    }
  }

  static PageRoute<dynamic> _buildRoute(RouteSettings settings, Widget child) {
    if (staticDockRoutes.contains(settings.name)) {
      return PageRouteBuilder<dynamic>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: AppMotion.pageEnter,
      reverseTransitionDuration: AppMotion.pageExit,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final CurvedAnimation primary = CurvedAnimation(
          parent: animation,
          curve: AppMotion.pageIn,
          reverseCurve: AppMotion.pageOut,
        );
        final Animation<double> opacity = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.08, 1, curve: AppMotion.pageIn),
            reverseCurve: const Interval(0, 0.82, curve: AppMotion.pageOut),
          ),
        );
        final Animation<Offset> offset = Tween<Offset>(
          begin: const Offset(0.0, 0.03),
          end: Offset.zero,
        ).animate(primary);
        final Animation<double> scale = Tween<double>(
          begin: 0.988,
          end: 1,
        ).animate(primary);

        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(
            scale: scale,
            child: SlideTransition(
              position: offset,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
