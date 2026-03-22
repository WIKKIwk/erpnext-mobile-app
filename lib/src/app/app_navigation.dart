import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppRouteTracker extends NavigatorObserver with ChangeNotifier {
  AppRouteTracker._();

  static final AppRouteTracker instance = AppRouteTracker._();

  String? _currentRouteName;

  String? get currentRouteName => _currentRouteName;

  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (_currentRouteName == name) {
      return;
    }
    _currentRouteName = name;
    notifyListeners();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _update(previousRoute);
  }
}
