import 'package:flutter/material.dart';

import 'app_navigation_bar.dart'
    show
        appNavigationBarDockHeight,
        appNavigationBarHeight,
        AppNavigationDestination,
        appNavigationBarPrimaryButtonBottom;
import 'dock_gesture_overlay.dart';
import 'dock_system_bottom_inset.dart';
import 'drive_reference_layout.dart';

// Pastki dock «+» / FAB — alohida modul. Navigation bar bilan aralashtirilmasin.
// Qoidalar: .cursor/rules/dock-primary-fab.mdc
// Geometriya: Google Drive ADB o‘lchovi (docs/google_drive_bottom_nav_measurements.md).

/// O‘ng chetdagi margin ([EdgeToEdgeBottomSlot] ichidagi `end`).
const double appNavigationBarPrimaryEndMargin = 16.0;

/// Nav oxirgi band va «+» orasidagi bo‘shliq (rezerva getter uchun).
const double appNavigationBarPrimaryNavGap = 8.0;

double appNavigationBarPrimaryNavTrailingReserveOf(BuildContext context) {
  return driveReferencePrimaryFabSize(context) +
      appNavigationBarPrimaryEndMargin +
      appNavigationBarPrimaryNavGap;
}

/// FAB slot: Drive bo‘shligi + FAB balandligi (nav yuqorisidan).
double appNavigationBarPrimaryFabSlotExtensionOf(BuildContext context) {
  return driveReferenceFabGapAboveNav(context) +
      driveReferencePrimaryFabSize(context);
}

/// [NavigationBar] yo‘q — faqat o‘ng pastdagi asosiy «+».
class AppNavigationPrimaryFabOnly extends StatelessWidget {
  const AppNavigationPrimaryFabOnly({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
    this.visible = true,
  });

  final AppNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final MediaQueryData viewMetrics =
        MediaQueryData.fromView(View.of(context));
    final double systemBottomInset = dockLayoutBottomInset(
      viewMetrics,
      thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
    );
    final double dockHeight = appNavigationBarDockHeight(
      height: appNavigationBarHeight,
      systemBottomInset: systemBottomInset,
    );
    final double hostHeight =
        dockHeight + appNavigationBarPrimaryFabSlotExtensionOf(context);

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return SizedBox(
            key: const ValueKey('app-navigation-primary-fab-only-host'),
            width: availableWidth,
            height: hostHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  end: appNavigationBarPrimaryEndMargin,
                  bottom: appNavigationBarPrimaryButtonBottom(
                    dockHeight: dockHeight,
                  ),
                  child: AppPrimaryNavigationFab(
                    destination: destination,
                    selected: selected,
                    onTap: onTap,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Alohida ko‘tarilgan asosiy tugma — [NavigationBar] bandlari ichiga birlashtirilmasin.
class AppPrimaryNavigationFab extends StatelessWidget {
  const AppPrimaryNavigationFab({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color background =
        selected ? scheme.primary : scheme.primaryContainer;
    final Color foreground =
        selected ? scheme.onPrimary : scheme.onPrimaryContainer;
    final Widget icon = destination.selectedIcon ?? destination.icon;
    final double side = driveReferencePrimaryFabSize(context);
    final double radius = driveReferencePrimaryFabBorderRadius(context);
    final double iconSize = 30 * (side / 80);

    return Semantics(
      key: const ValueKey('app-primary-navigation-button'),
      button: true,
      label: destination.label,
      child: Material(
        color: background,
        elevation: 8,
        shadowColor: scheme.primary.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          onLongPress: destination.onLongPress,
          child: SizedBox(
            width: side,
            height: side,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: foreground,
                  size: iconSize,
                ),
                child: Center(
                  child: SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: icon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
