import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Gesture navigatsiya aniqlanganda pastki «tizim» qatoriga beriladigan qattiq balandlik (dp≈px).
/// Boshqa qiymat kerak bo‘lsa (masalan 5) shu konstantani o‘zgartirish kifoya.
const double appDockGestureNavigationBottomInset = 15.0;

/// [AppNavigationBar] dagi tugmali rejim: to‘liq media inset (ikki turdan kattasi).
double dockMediaBottomInset(MediaQueryData data) {
  return math.max(data.viewPadding.bottom, data.systemGestureInsets.bottom);
}

/// [thinGestureBottom] — [DockGestureOverlayScope] ([DockGestureOverlay]) dan.
double dockLayoutBottomInset(
  MediaQueryData data, {
  required bool thinGestureBottom,
}) {
  if (thinGestureBottom) return appDockGestureNavigationBottomInset;
  return dockMediaBottomInset(data);
}

/// Pastki dock / [NavigationBar] uchun tizim bo‘shlig‘i.
///
/// [MediaQueryData.viewPadding] odatda navigatsiya paneli (3 tugma yoki gesture)
/// balandligini beradi. Baʼzi qurilmalarda [systemGestureInsets] qo‘shimcha va
/// `max()` ikkalasini qo‘shib yuboradi — 3-tugmali rejimda ortiqcha bo‘shliq.
/// Shuning uchun `viewPadding.bottom > 0` bo‘lsa, faqat u ishlatiladi.
///
/// Yangi dock layout uchun [dockLayoutBottomInset] afzal.
double dockSystemBottomInset(MediaQueryData data) {
  final double vp = data.viewPadding.bottom;
  if (vp > 0) {
    return vp;
  }
  return math.max(vp, data.systemGestureInsets.bottom);
}
