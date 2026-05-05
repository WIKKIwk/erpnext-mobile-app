import 'package:flutter/material.dart';

import 'app_navigation_bar.dart';
import 'app_primary_navigation_fab.dart';
import 'dock_gesture_overlay.dart';
import 'dock_system_bottom_inset.dart';
import 'drive_reference_layout.dart';

/// Pastki tizim chiziqlari (edge-to-edge) ostida joy — **navigatsiya UI emas**.
/// [child] odatda rasmiy [NavigationBar] ([api.flutter.dev NavigationBar],
/// `maintainBottomViewPadding`).
///
/// FAB qatlami loyiha qoidasi bo‘yicha alohida.
/// Nav balandligi: `docs/google_drive_bottom_nav_measurements.md` (Drive fizik 84 px).
class EdgeToEdgeBottomSlot extends StatelessWidget {
  const EdgeToEdgeBottomSlot({
    super.key,
    this.overlayEndBottom,
    this.barHeight,
    required this.child,
  });

  /// Masalan [AppPrimaryNavigationFab].
  final Widget? overlayEndBottom;

  /// Pastki qator balandligi; `null` → [NavigationBar.height] / theme / Drive ref.
  final double? barHeight;

  /// Odatda [NavigationBar].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData viewMetrics =
        MediaQueryData.fromView(View.of(context));
    final double systemBottomInset = dockLayoutBottomInset(
      viewMetrics,
      thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
    );
    final double bh = barHeight ??
        (child is NavigationBar ? (child as NavigationBar).height : null) ??
        NavigationBarTheme.of(context).height ??
        driveReferenceNavBarHeight(context);
    final double dockHeight = bh + systemBottomInset;
    final double hostHeight = dockHeight +
        (overlayEndBottom != null
            ? appNavigationBarPrimaryFabSlotExtensionOf(context)
            : 0);

    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return SizedBox(
            key: const ValueKey('edge-to-edge-bottom-slot-host'),
            width: availableWidth,
            height: hostHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    key: const ValueKey('edge-to-edge-bottom-slot-shell'),
                    width: availableWidth,
                    height: dockHeight,
                    child: MediaQuery(
                      data: viewMetrics.copyWith(
                        padding: EdgeInsets.only(bottom: systemBottomInset),
                      ),
                      child: child,
                    ),
                  ),
                ),
                if (overlayEndBottom != null)
                  PositionedDirectional(
                    end: appNavigationBarPrimaryEndMargin,
                    bottom: appNavigationBarPrimaryButtonBottom(
                      dockHeight: dockHeight,
                    ),
                    child: overlayEndBottom!,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
