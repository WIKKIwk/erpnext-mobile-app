import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppRouteTracker extends NavigatorObserver with ChangeNotifier {
  AppRouteTracker._();

  static final AppRouteTracker instance = AppRouteTracker._();

  String? _currentRouteName;

  String? get currentRouteName => _currentRouteName;

  void _setCurrent(Route<dynamic>? route) {
    final next = route?.settings.name;
    if (next == null || next.isEmpty) {
      return;
    }
    if (_currentRouteName == next) {
      return;
    }
    _currentRouteName = next;
    notifyListeners();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _setCurrent(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _setCurrent(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _setCurrent(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _setCurrent(previousRoute);
  }
}
