import 'package:flutter/widgets.dart';

/// Google Drive UIAutomator + `dumpsys` bilan **Redmi Note 11 (440 dpi)** da olingan
/// fizik piksel qiymatlari. Har qanday qurilmada shu **fizik** o‘lchamlarni
/// `MediaQuery.devicePixelRatio` orqali mantiqiy px ga aylantiradi — Drive bilan
/// bir xil px natija (masalan 84 px nav, 220 px FAB, 44 px bo‘shliq).
///
/// Manba: `docs/google_drive_bottom_nav_measurements.md`
const double driveReferenceBottomNavPhysicalPx = 84;
const double driveReferencePrimaryFabPhysicalPx = 220;
const double driveReferenceFabGapAboveNavPhysicalPx = 44;

double driveReferenceNavBarHeight(BuildContext context) {
  return driveReferenceBottomNavPhysicalPx /
      MediaQuery.devicePixelRatioOf(context);
}

double driveReferencePrimaryFabSize(BuildContext context) {
  return driveReferencePrimaryFabPhysicalPx /
      MediaQuery.devicePixelRatioOf(context);
}

double driveReferenceFabGapAboveNav(BuildContext context) {
  return driveReferenceFabGapAboveNavPhysicalPx /
      MediaQuery.devicePixelRatioOf(context);
}

/// Eski 80×80 mantiqiy tugma uchun radius (22). Drive 220 px tugmada proporsional.
double driveReferencePrimaryFabBorderRadius(BuildContext context) {
  return driveReferencePrimaryFabSize(context) * (22 / 80);
}
