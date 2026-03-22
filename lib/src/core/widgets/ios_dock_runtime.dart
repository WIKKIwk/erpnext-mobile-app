import '../../app/app_navigation.dart';
import '../../app/app_router.dart';
import '../../features/shared/models/app_models.dart';
import '../notifications/notification_unread_store.dart';
import '../session/app_session.dart';
import 'ios_liquid_dock.dart';
import 'logout_prompt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class IOSDockRuntime extends StatelessWidget {
  const IOSDockRuntime({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        AppRouteTracker.instance,
        NotificationUnreadStore.instance,
      ]),
      builder: (context, _) {
        final profile = AppSession.instance.profile;
        final routeName = AppRouteTracker.instance.currentRouteName;
        final config = _IOSDockConfig.resolve(
          profile: profile,
          routeName: routeName,
        );
        if (config == null) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IOSLiquidDock(
                    compact: true,
                    tightToEdges: true,
                    items: config.items,
                    onTap: (id) => config.handleTap(context, id),
                    onLongPress: (id) => config.handleLongPress(context, id),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IOSDockConfig {
  const _IOSDockConfig({
    required this.items,
    required this.handleTap,
    required this.handleLongPress,
  });

  final List<IOSLiquidDockItem> items;
  final void Function(BuildContext context, String id) handleTap;
  final void Function(BuildContext context, String id) handleLongPress;

  static _IOSDockConfig? resolve({
    required SessionProfile? profile,
    required String? routeName,
  }) {
    if (profile == null || routeName == null || routeName == AppRoutes.login) {
      return null;
    }

    final showUnread = NotificationUnreadStore.instance.hasUnreadForProfile(profile);

    switch (profile.role) {
      case UserRole.customer:
        if (!_customerRoutes.contains(routeName)) {
          return null;
        }
        final active = routeName == AppRoutes.customerNotifications
            ? 'notifications'
            : routeName == AppRoutes.profile
                ? 'profile'
                : 'home';
        return _IOSDockConfig(
          items: [
            IOSLiquidDockItem(id: 'home', active: active == 'home'),
            IOSLiquidDockItem(
              id: 'notifications',
              active: active == 'notifications',
              showBadge: showUnread && active != 'notifications',
            ),
            IOSLiquidDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (context, id) {
            switch (id) {
              case 'home':
                if (active == 'home') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.customerHome,
                  (route) => false,
                );
              case 'notifications':
                if (active == 'notifications') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.customerNotifications,
                  (route) => false,
                );
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
            }
          },
          handleLongPress: (context, id) {
            if (id == 'profile' && active == 'profile') {
              showLogoutPrompt(context);
            }
          },
        );
      case UserRole.supplier:
        if (!_supplierRoutes.contains(routeName)) {
          return null;
        }
        final createActive = _supplierCreateRoutes.contains(routeName);
        final active = routeName == AppRoutes.supplierNotifications
            ? 'notifications'
            : routeName == AppRoutes.supplierRecent
                ? 'recent'
                : routeName == AppRoutes.profile
                    ? 'profile'
                    : 'home';
        return _IOSDockConfig(
          items: [
            IOSLiquidDockItem(id: 'home', active: active == 'home'),
            IOSLiquidDockItem(
              id: 'notifications',
              active: active == 'notifications',
              showBadge: showUnread && active != 'notifications',
            ),
            IOSLiquidDockItem(
              id: 'create',
              active: createActive,
              primary: true,
            ),
            IOSLiquidDockItem(id: 'recent', active: active == 'recent'),
            IOSLiquidDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (context, id) {
            switch (id) {
              case 'home':
                if (active == 'home' && !createActive) return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierHome,
                  (route) => false,
                );
              case 'notifications':
                if (active == 'notifications') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierNotifications,
                  (route) => false,
                );
              case 'create':
                if (createActive) return;
                appNavigatorKey.currentState?.pushNamed(AppRoutes.supplierItemPicker);
              case 'recent':
                if (active == 'recent') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierRecent,
                  (route) => false,
                );
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
            }
          },
          handleLongPress: (context, id) {
            if (id == 'profile' && active == 'profile') {
              showLogoutPrompt(context);
            }
          },
        );
      case UserRole.werka:
        if (!_werkaRoutes.contains(routeName)) {
          return null;
        }
        final createActive = _werkaCreateRoutes.contains(routeName);
        final active = routeName == AppRoutes.werkaNotifications
            ? 'notifications'
            : routeName == AppRoutes.werkaRecent
                ? 'recent'
                : routeName == AppRoutes.profile
                    ? 'profile'
                    : 'home';
        return _IOSDockConfig(
          items: [
            IOSLiquidDockItem(id: 'home', active: active == 'home'),
            IOSLiquidDockItem(
              id: 'notifications',
              active: active == 'notifications',
              showBadge: showUnread && active != 'notifications',
            ),
            IOSLiquidDockItem(
              id: 'create',
              active: createActive,
              primary: true,
            ),
            IOSLiquidDockItem(id: 'recent', active: active == 'recent'),
            IOSLiquidDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (context, id) {
            switch (id) {
              case 'home':
                if (active == 'home') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.werkaHome,
                  (route) => false,
                );
              case 'notifications':
                if (active == 'notifications') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.werkaNotifications,
                  (route) => false,
                );
              case 'create':
                if (createActive) return;
                appNavigatorKey.currentState?.pushNamed(AppRoutes.werkaCreateHub);
              case 'recent':
                if (active == 'recent') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.werkaRecent,
                  (route) => false,
                );
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
            }
          },
          handleLongPress: (context, id) {
            if (id == 'profile' && active == 'profile') {
              showLogoutPrompt(context);
            }
          },
        );
      case UserRole.admin:
        if (!_adminRoutes.contains(routeName)) {
          return null;
        }
        final active = switch (routeName) {
          AppRoutes.adminSuppliers ||
          AppRoutes.adminSupplierCreate ||
          AppRoutes.adminSupplierDetail ||
          AppRoutes.adminSupplierItemsView ||
          AppRoutes.adminSupplierItemsAdd ||
          AppRoutes.adminInactiveSuppliers => 'suppliers',
          AppRoutes.adminActivity => 'activity',
          AppRoutes.profile => 'profile',
          _ => 'home',
        };
        final createActive = _adminCreateRoutes.contains(routeName);
        return _IOSDockConfig(
          items: [
            IOSLiquidDockItem(id: 'home', active: active == 'home'),
            IOSLiquidDockItem(id: 'suppliers', active: active == 'suppliers'),
            IOSLiquidDockItem(
              id: 'create',
              active: createActive,
              primary: true,
            ),
            IOSLiquidDockItem(id: 'activity', active: active == 'activity'),
            IOSLiquidDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (context, id) {
            switch (id) {
              case 'home':
                if (active == 'home') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminHome,
                  (route) => false,
                );
              case 'suppliers':
                if (active == 'suppliers') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminSuppliers,
                  (route) => false,
                );
              case 'create':
                if (createActive) return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminCreateHub,
                  (route) => false,
                );
              case 'activity':
                if (active == 'activity') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminActivity,
                  (route) => false,
                );
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
            }
          },
          handleLongPress: (context, id) {
            if (id == 'profile' && active == 'profile') {
              showLogoutPrompt(context);
            }
          },
        );
    }
  }

  static const _customerRoutes = <String>{
    AppRoutes.customerHome,
    AppRoutes.customerNotifications,
    AppRoutes.customerStatusDetail,
    AppRoutes.customerDetail,
    AppRoutes.profile,
  };

  static const _supplierRoutes = <String>{
    AppRoutes.supplierHome,
    AppRoutes.supplierNotifications,
    AppRoutes.supplierRecent,
    AppRoutes.notificationDetail,
    AppRoutes.supplierStatusBreakdown,
    AppRoutes.supplierSubmittedCategoryDetail,
    AppRoutes.supplierStatusDetail,
    AppRoutes.supplierItemPicker,
    AppRoutes.supplierQty,
    AppRoutes.supplierConfirm,
    AppRoutes.supplierSuccess,
    AppRoutes.profile,
  };

  static const _supplierCreateRoutes = <String>{
    AppRoutes.supplierItemPicker,
    AppRoutes.supplierQty,
    AppRoutes.supplierConfirm,
    AppRoutes.supplierSuccess,
  };

  static const _werkaRoutes = <String>{
    AppRoutes.werkaHome,
    AppRoutes.werkaNotifications,
    AppRoutes.werkaRecent,
    AppRoutes.notificationDetail,
    AppRoutes.werkaStatusBreakdown,
    AppRoutes.werkaStatusDetail,
    AppRoutes.werkaDetail,
    AppRoutes.werkaCustomerDeliveryDetail,
    AppRoutes.werkaCreateHub,
    AppRoutes.werkaCustomerIssueCustomer,
    AppRoutes.werkaUnannouncedSupplier,
    AppRoutes.werkaSuccess,
    AppRoutes.profile,
  };

  static const _werkaCreateRoutes = <String>{
    AppRoutes.werkaCreateHub,
    AppRoutes.werkaCustomerIssueCustomer,
    AppRoutes.werkaUnannouncedSupplier,
    AppRoutes.werkaSuccess,
  };

  static const _adminRoutes = <String>{
    AppRoutes.adminHome,
    AppRoutes.adminActivity,
    AppRoutes.adminCreateHub,
    AppRoutes.adminSettings,
    AppRoutes.adminSuppliers,
    AppRoutes.adminSupplierCreate,
    AppRoutes.adminCustomerCreate,
    AppRoutes.adminCustomerDetail,
    AppRoutes.adminInactiveSuppliers,
    AppRoutes.adminItemCreate,
    AppRoutes.adminSupplierDetail,
    AppRoutes.adminSupplierItemsView,
    AppRoutes.adminSupplierItemsAdd,
    AppRoutes.adminWerka,
    AppRoutes.profile,
  };

  static const _adminCreateRoutes = <String>{
    AppRoutes.adminCreateHub,
    AppRoutes.adminSettings,
    AppRoutes.adminCustomerCreate,
    AppRoutes.adminItemCreate,
    AppRoutes.adminWerka,
  };
}
