import '../../app/app_navigation.dart';
import '../../app/app_router.dart';
import '../../features/shared/models/app_models.dart';
import '../notifications/notification_unread_store.dart';
import '../session/app_session.dart';
import 'logout_prompt.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSDockRuntime extends StatefulWidget {
  const IOSDockRuntime({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<IOSDockRuntime> createState() => _IOSDockRuntimeState();
}

class _IOSDockRuntimeState extends State<IOSDockRuntime>
    with WidgetsBindingObserver {
  static const MethodChannel _channel =
      MethodChannel('accord_liquid_dock_runtime');

  _IOSDockConfig? _lastConfig;
  Timer? _retryTimer;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sendDockPayload(_lastConfig);
      _scheduleRetryBurst();
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    final config = _lastConfig;
    if (config == null) {
      return;
    }
    final args = (call.arguments as Map<dynamic, dynamic>? ??
        const <dynamic, dynamic>{});
    final id = '${args['id'] ?? ''}'.trim();
    if (id.isEmpty) {
      return;
    }
    switch (call.method) {
      case 'tap':
        config.handleTap(id);
        return;
      case 'longPress':
        config.handleLongPress(context, id);
        return;
    }
  }

  void _syncDock(_IOSDockConfig? config) {
    _lastConfig = config;
    _sendDockPayload(config);
    _scheduleRetryBurst();
  }

  void _sendDockPayload(_IOSDockConfig? config) {
    final payload = config == null
        ? <String, Object?>{'visible': false}
        : <String, Object?>{
            'visible': true,
            'items': config.items
                .map(
                  (item) => <String, Object>{
                    'id': item.id,
                    'active': item.active,
                    'primary': item.primary,
                    'showBadge': item.showBadge,
                    'allowLongPress': item.allowLongPress,
                  },
                )
                .toList(),
          };
    _channel.invokeMethod<void>('updateDock', payload);
  }

  void _scheduleRetryBurst() {
    _retryTimer?.cancel();
    _retryCount = 0;
    _retryTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _retryCount += 1;
      _sendDockPayload(_lastConfig);
      if (_retryCount >= 8) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        AppRouteTracker.instance,
        NotificationUnreadStore.instance,
        AppSession.instance,
      ]),
      builder: (context, _) {
        final config = _IOSDockConfig.resolve(
          profile: AppSession.instance.profile,
          routeName: AppRouteTracker.instance.currentRouteName ??
              (AppSession.instance.isLoggedIn
                  ? AppSession.instance.homeRoute
                  : null),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncDock(config);
          }
        });
        return widget.child;
      },
    );
  }
}

class _IOSDockItem {
  const _IOSDockItem({
    required this.id,
    required this.active,
    this.primary = false,
    this.showBadge = false,
    this.allowLongPress = false,
  });

  final String id;
  final bool active;
  final bool primary;
  final bool showBadge;
  final bool allowLongPress;
}

class _IOSDockConfig {
  const _IOSDockConfig({
    required this.items,
    required this.handleTap,
    required this.handleLongPress,
  });

  final List<_IOSDockItem> items;
  final ValueChanged<String> handleTap;
  final void Function(BuildContext context, String id) handleLongPress;

  static _IOSDockConfig? resolve({
    required SessionProfile? profile,
    required String? routeName,
  }) {
    if (profile == null || routeName == null || routeName == AppRoutes.login) {
      return null;
    }

    final hasUnread =
        NotificationUnreadStore.instance.hasUnreadForProfile(profile);

    switch (profile.role) {
      case UserRole.customer:
        final active = switch (routeName) {
          AppRoutes.customerHome => 'home',
          AppRoutes.customerNotifications => 'notifications',
          AppRoutes.profile => 'profile',
          _ => '',
        };
        return _IOSDockConfig(
          items: [
            _IOSDockItem(id: 'home', active: active == 'home'),
            _IOSDockItem(
              id: 'notifications',
              active: active == 'notifications',
              showBadge: hasUnread && active != 'notifications',
            ),
            _IOSDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (id) {
            switch (id) {
              case 'home':
                if (active == 'home') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.customerHome,
                  (route) => false,
                );
                return;
              case 'notifications':
                if (active == 'notifications') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.customerNotifications,
                  (route) => false,
                );
                return;
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
                return;
            }
          },
          handleLongPress: (context, id) {
            if (id == 'profile' && active == 'profile') {
              showLogoutPrompt(context);
            }
          },
        );
      case UserRole.supplier:
        final active = switch (routeName) {
          AppRoutes.supplierHome => 'home',
          AppRoutes.supplierNotifications => 'notifications',
          AppRoutes.supplierRecent => 'recent',
          AppRoutes.profile => 'profile',
          AppRoutes.supplierItemPicker ||
          AppRoutes.supplierQty ||
          AppRoutes.supplierConfirm ||
          AppRoutes.supplierSuccess =>
            'create',
          _ => '',
        };
        return _IOSDockConfig(
          items: [
            _IOSDockItem(id: 'home', active: active == 'home'),
            _IOSDockItem(
              id: 'notifications',
              active: active == 'notifications',
              showBadge: hasUnread && active != 'notifications',
            ),
            _IOSDockItem(
              id: 'create',
              active: active == 'create',
              primary: true,
            ),
            _IOSDockItem(id: 'recent', active: active == 'recent'),
            _IOSDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (id) {
            switch (id) {
              case 'home':
                if (active == 'home') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierHome,
                  (route) => false,
                );
                return;
              case 'notifications':
                if (active == 'notifications') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierNotifications,
                  (route) => false,
                );
                return;
              case 'create':
                if (active == 'create') return;
                appNavigatorKey.currentState?.pushNamed(
                  AppRoutes.supplierItemPicker,
                );
                return;
              case 'recent':
                if (active == 'recent') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.supplierRecent,
                  (route) => false,
                );
                return;
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
                return;
            }
          },
          handleLongPress: (context, id) {
            if (id == 'profile' && active == 'profile') {
              showLogoutPrompt(context);
            }
          },
        );
      case UserRole.werka:
        final active = switch (routeName) {
          AppRoutes.werkaHome => 'home',
          AppRoutes.werkaNotifications => 'notifications',
          AppRoutes.werkaRecent => 'recent',
          AppRoutes.profile => 'profile',
          AppRoutes.werkaCreateHub ||
          AppRoutes.werkaCustomerIssueCustomer ||
          AppRoutes.werkaUnannouncedSupplier ||
          AppRoutes.werkaSuccess =>
            'create',
          _ => '',
        };
        return _IOSDockConfig(
          items: [
            _IOSDockItem(id: 'home', active: active == 'home'),
            _IOSDockItem(
              id: 'notifications',
              active: active == 'notifications',
              showBadge: hasUnread && active != 'notifications',
            ),
            _IOSDockItem(
              id: 'create',
              active: active == 'create',
              primary: true,
            ),
            _IOSDockItem(id: 'recent', active: active == 'recent'),
            _IOSDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (id) {
            switch (id) {
              case 'home':
                if (active == 'home') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.werkaHome,
                  (route) => false,
                );
                return;
              case 'notifications':
                if (active == 'notifications') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.werkaNotifications,
                  (route) => false,
                );
                return;
              case 'create':
                if (active == 'create') return;
                appNavigatorKey.currentState?.pushNamed(
                  AppRoutes.werkaCreateHub,
                );
                return;
              case 'recent':
                if (active == 'recent') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.werkaRecent,
                  (route) => false,
                );
                return;
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
                return;
            }
          },
          handleLongPress: (context, id) {
            if (id == 'profile' && active == 'profile') {
              showLogoutPrompt(context);
            }
          },
        );
      case UserRole.admin:
        final active = switch (routeName) {
          AppRoutes.adminHome => 'home',
          AppRoutes.adminActivity => 'activity',
          AppRoutes.profile => 'profile',
          AppRoutes.adminCreateHub ||
          AppRoutes.adminSettings ||
          AppRoutes.adminCustomerCreate ||
          AppRoutes.adminItemCreate ||
          AppRoutes.adminWerka =>
            'create',
          AppRoutes.adminSuppliers ||
          AppRoutes.adminSupplierCreate ||
          AppRoutes.adminSupplierDetail ||
          AppRoutes.adminSupplierItemsView ||
          AppRoutes.adminSupplierItemsAdd ||
          AppRoutes.adminInactiveSuppliers =>
            'suppliers',
          _ => '',
        };
        return _IOSDockConfig(
          items: [
            _IOSDockItem(id: 'home', active: active == 'home'),
            _IOSDockItem(id: 'suppliers', active: active == 'suppliers'),
            _IOSDockItem(
              id: 'create',
              active: active == 'create',
              primary: true,
            ),
            _IOSDockItem(id: 'activity', active: active == 'activity'),
            _IOSDockItem(
              id: 'profile',
              active: active == 'profile',
              allowLongPress: active == 'profile',
            ),
          ],
          handleTap: (id) {
            switch (id) {
              case 'home':
                if (active == 'home') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminHome,
                  (route) => false,
                );
                return;
              case 'suppliers':
                if (active == 'suppliers') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminSuppliers,
                  (route) => false,
                );
                return;
              case 'create':
                if (active == 'create') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminCreateHub,
                  (route) => false,
                );
                return;
              case 'activity':
                if (active == 'activity') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.adminActivity,
                  (route) => false,
                );
                return;
              case 'profile':
                if (active == 'profile') return;
                appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
                  AppRoutes.profile,
                  (route) => false,
                );
                return;
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
}
