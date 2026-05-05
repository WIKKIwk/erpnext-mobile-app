import 'package:flutter/material.dart';

import 'dock_gesture_overlay.dart';
import 'dock_system_bottom_inset.dart';
import 'drive_reference_layout.dart';

/// Android [BottomNavigationView] (MainActivity) balandligini Flutter
/// [Scaffold.bottomNavigationBar] orqali layoutga bildirish. FAB native overlayda —
/// bu yerda qo‘shimcha bo‘sh slot kerak emas.
class NativeSystemDockLayoutReserve extends StatelessWidget {
  const NativeSystemDockLayoutReserve({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: nativeSystemDockLayoutReserveHeight(context),
    );
  }
}

/// Temada `height` berilgan bo‘lsa u; aks holda Drive ADB bilan mos **84 fizik px** nav.
double nativeSystemDockBaseHeight(BuildContext context) {
  return NavigationBarTheme.of(context).height ??
      driveReferenceNavBarHeight(context);
}

double nativeSystemDockLayoutReserveHeight(BuildContext context) {
  final MediaQueryData view = MediaQueryData.fromView(View.of(context));
  final double systemBottom = dockLayoutBottomInset(
    view,
    thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
  );
  return nativeSystemDockBaseHeight(context) + systemBottom;
}
