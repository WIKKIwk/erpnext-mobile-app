import 'package:flutter/material.dart';

import '../../system_navigation_mode.dart';

/// Ilova ildizida joylashtiring — pastki dock uchun «gesture → ingichka inset» maslahati.
///
/// Androidda [SystemNavigationMode] ni bir marta o‘qiydi; tugmali rejimda hech narsani qisqartirmaydi.
class DockGestureOverlayScope extends InheritedWidget {
  const DockGestureOverlayScope({
    required this.thinGestureBottom,
    required super.child,
    super.key,
  });

  /// `true` → pastki dock uchun qattiq ingichka zona ([appDockGestureNavigationBottomInset]).
  final bool thinGestureBottom;

  static DockGestureOverlayScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DockGestureOverlayScope>();
  }

  static bool thinGestureBottomOf(BuildContext context) =>
      maybeOf(context)?.thinGestureBottom ?? false;

  @override
  bool updateShouldNotify(DockGestureOverlayScope oldWidget) {
    return thinGestureBottom != oldWidget.thinGestureBottom;
  }
}

/// Kanalni ishga tushirib, [DockGestureOverlayScope] bilan o‘raydi.
class DockGestureOverlay extends StatefulWidget {
  const DockGestureOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<DockGestureOverlay> createState() => _DockGestureOverlayState();
}

class _DockGestureOverlayState extends State<DockGestureOverlay> {
  bool _resolved = false;
  bool _gesture = false;

  @override
  void initState() {
    super.initState();
    SystemNavigationMode.isGestureNavigation().then((bool value) {
      if (!mounted) return;
      setState(() {
        _gesture = value;
        _resolved = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool thin = _resolved && _gesture;
    return DockGestureOverlayScope(
      thinGestureBottom: thin,
      child: widget.child,
    );
  }
}
