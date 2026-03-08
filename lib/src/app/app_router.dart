import '../features/auth/presentation/login_screen.dart';
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
}

class AppRouter {
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
        final ProfileArgs args = settings.arguments as ProfileArgs;
        return _buildRoute(
          settings,
          ProfileScreen(
            role: args.role,
            name: args.name,
            subtitle: args.subtitle,
          ),
        );
      default:
        return _buildRoute(settings, const LoginScreen());
    }
  }

  static PageRoute<dynamic> _buildRoute(RouteSettings settings, Widget child) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.settle,
          reverseCurve: AppMotion.emphasized,
        );
        final Animation<Offset> offset = Tween<Offset>(
          begin: const Offset(0.045, 0),
          end: Offset.zero,
        ).animate(curved);
        final Animation<double> scale = Tween<double>(
          begin: 0.992,
          end: 1,
        ).animate(curved);

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: offset,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ProfileArgs {
  const ProfileArgs({
    required this.role,
    required this.name,
    required this.subtitle,
  });

  final UserRole role;
  final String name;
  final String subtitle;
}
