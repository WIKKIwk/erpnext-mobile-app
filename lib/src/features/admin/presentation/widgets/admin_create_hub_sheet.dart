import 'dart:async';
import 'dart:math' as math;

import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/navigation/app_navigation_bar.dart';
import '../../../../core/widgets/navigation/dock_gesture_overlay.dart';
import '../../../../core/widgets/navigation/dock_system_bottom_inset.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> adminCreateHubMenuOpen = ValueNotifier<bool>(false);
const double _adminHubMenuItemHeight = 56.0;
const double _adminHubActionPaddingStart = 14.0;
const double _adminHubActionPaddingEnd = 14.0;
const double _adminHubActionIconGap = 10.0;

OverlayEntry? _adminCreateHubOverlayEntry;
final GlobalKey<_AdminCreateHubOverlayState> _adminCreateHubOverlayKey =
    GlobalKey<_AdminCreateHubOverlayState>();

void showAdminCreateHubSheet(BuildContext context) {
  if (_adminCreateHubOverlayEntry != null) {
    _adminCreateHubOverlayKey.currentState?.setOpen(true);
    return;
  }

  final overlay = Overlay.of(context, rootOverlay: true);
  final navigator = Navigator.of(context);
  late final OverlayEntry entry;

  void closeMenuNow() {
    adminCreateHubMenuOpen.value = false;
    if (entry.mounted) {
      entry.remove();
    }
    if (_adminCreateHubOverlayEntry == entry) {
      _adminCreateHubOverlayEntry = null;
    }
  }

  void requestCloseMenu() {
    final currentState = _adminCreateHubOverlayKey.currentState;
    if (currentState != null) {
      currentState.setOpen(false);
      return;
    }
    closeMenuNow();
  }

  void openRoute(String routeName) {
    requestCloseMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.pushNamed(routeName);
    });
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      return _AdminCreateHubOverlay(
        key: _adminCreateHubOverlayKey,
        onClose: closeMenuNow,
        onOpenRoute: openRoute,
      );
    },
  );

  _adminCreateHubOverlayEntry = entry;
  adminCreateHubMenuOpen.value = true;
  overlay.insert(entry);
}

class _AdminCreateHubOverlay extends StatefulWidget {
  const _AdminCreateHubOverlay({
    super.key,
    required this.onClose,
    required this.onOpenRoute,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onOpenRoute;

  @override
  State<_AdminCreateHubOverlay> createState() => _AdminCreateHubOverlayState();
}

class _AdminCreateHubOverlayState extends State<_AdminCreateHubOverlay>
    with TickerProviderStateMixin {
  static const double _fabClosedSize = 80.0;
  static const double _fabOpenSize = 56.0;
  static const double _menuItemGap = 4.0;
  static const double _groupButtonGap = 10.0;
  static const double _menuTrailingInset = 16.0;
  static const double _stackTrailingInset = 16.0;
  static final SpringDescription _spatialSpring =
      SpringDescription.withDampingRatio(
    mass: 1.18,
    stiffness: 230.0,
    ratio: 0.88,
  );
  static final SpringDescription _effectsSpring =
      SpringDescription.withDampingRatio(
    mass: 1.12,
    stiffness: 500.0,
    ratio: 1.0,
  );
  static final SpringDescription _spatialSpringClose =
      SpringDescription.withDampingRatio(
    mass: 1.2,
    stiffness: 400.0,
    ratio: 0.82,
  );
  static final SpringDescription _effectsSpringClose =
      SpringDescription.withDampingRatio(
    mass: 1.08,
    stiffness: 700.0,
    ratio: 1.0,
  );

  /// FAB circle -> rounded rect: slightly under-damped for settle bounce.
  static final SpringDescription _fabMorphSpring =
      SpringDescription.withDampingRatio(
    mass: 0.55,
    stiffness: 2350.0,
    ratio: 0.72,
  );
  static final SpringDescription _fabMorphSpringClose = _fabMorphSpring;
  static const Duration _openDuration = Duration(milliseconds: 1080);
  static const Duration _closeDuration = Duration(milliseconds: 1080);

  static const double _spatialLower = -0.08;
  static const double _spatialUpper = 1.22;
  static const double _fabMorphLower = -0.05;
  static const double _fabMorphUpper = 1.14;

  /// Drives hub pill width + stagger only.
  late final AnimationController _spatialController = AnimationController(
    vsync: this,
    duration: _openDuration,
    reverseDuration: _closeDuration,
    lowerBound: _spatialLower,
    upperBound: _spatialUpper,
  );

  /// Drives FAB shape/size/color independently from [_spatialController].
  late final AnimationController _fabMorphController = AnimationController(
    vsync: this,
    duration: _openDuration,
    reverseDuration: _closeDuration,
    lowerBound: _fabMorphLower,
    upperBound: _fabMorphUpper,
  );

  late final AnimationController _effectsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 860),
    reverseDuration: const Duration(milliseconds: 860),
  );

  late final ShapeBorderTween _fabShapeTween = ShapeBorderTween(
    begin: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        appNavigationBarPrimaryButtonBorderRadius,
      ),
    ),
    end: const CircleBorder(),
  );

  bool _targetOpen = false;

  @override
  void initState() {
    super.initState();
    _setOpen(true);
  }

  void setOpen(bool open) {
    _setOpen(open);
  }

  @override
  void dispose() {
    _adminCreateHubOverlayEntry = null;
    adminCreateHubMenuOpen.value = false;
    _spatialController.dispose();
    _fabMorphController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    _targetOpen = open;
    if (open) {
      adminCreateHubMenuOpen.value = true;
    }

    final double target = open ? 1.0 : 0.0;
    if ((_spatialController.value - target).abs() < 0.001 &&
        (_fabMorphController.value - target).abs() < 0.001 &&
        (_effectsController.value - target).abs() < 0.001) {
      if (!open) {
        widget.onClose();
      }
      return;
    }

    final SpringDescription spatialSpring =
        open ? _spatialSpring : _spatialSpringClose;
    final SpringDescription effectsSpring =
        open ? _effectsSpring : _effectsSpringClose;
    final SpringDescription fabMorphSpring =
        open ? _fabMorphSpring : _fabMorphSpringClose;

    final spatialFuture = _animateWithSpring(
      controller: _spatialController,
      spring: spatialSpring,
      target: target,
    );
    final fabMorphFuture = _animateWithSpring(
      controller: _fabMorphController,
      spring: fabMorphSpring,
      target: target,
    );
    final effectsFuture = _animateWithSpring(
      controller: _effectsController,
      spring: effectsSpring,
      target: target,
    );

    if (!open) {
      unawaited(
        () async {
          try {
            await Future.wait<void>([
              spatialFuture.orCancel,
              fabMorphFuture.orCancel,
              effectsFuture.orCancel,
            ]);
          } on TickerCanceled {
            return;
          }

          if (!mounted || _targetOpen) {
            return;
          }
          widget.onClose();
        }(),
      );
    }
  }

  TickerFuture _animateWithSpring({
    required AnimationController controller,
    required SpringDescription spring,
    required double target,
  }) {
    final simulation = SpringSimulation(
      spring,
      controller.value,
      target,
      controller.velocity,
    )..tolerance = const Tolerance(distance: 0.001, velocity: 0.001);
    return controller.animateWith(simulation);
  }

  List<_AdminHubAction> _actions(BuildContext context) {
    final l10n = context.l10n;
    const n = 6;
    return [
      _AdminHubAction(
        key: const ValueKey('admin-hub-supplier-create'),
        title: l10n.adminCreateSupplierTitle,
        icon: Icons.local_shipping_outlined,
        routeName: AppRoutes.adminSupplierCreate,
        row: 0,
        staggerOrder: n - 1 - 0,
      ),
      _AdminHubAction(
        key: const ValueKey('admin-hub-customer-create'),
        title: l10n.adminCreateCustomerTitle,
        icon: Icons.person_add_alt_1_outlined,
        routeName: AppRoutes.adminCustomerCreate,
        row: 1,
        staggerOrder: n - 1 - 1,
      ),
      _AdminHubAction(
        key: const ValueKey('admin-hub-werka-create'),
        title: l10n.adminCreateWerkaTitle,
        icon: Icons.badge_outlined,
        routeName: AppRoutes.adminWerka,
        row: 2,
        staggerOrder: n - 1 - 2,
      ),
      _AdminHubAction(
        key: const ValueKey('admin-hub-settings'),
        title: l10n.adminErpSettingsTitle,
        icon: Icons.settings_outlined,
        routeName: AppRoutes.adminSettings,
        row: 3,
        staggerOrder: n - 1 - 3,
      ),
      _AdminHubAction(
        key: const ValueKey('admin-hub-item-create'),
        title: l10n.adminCreateItemTitle,
        icon: Icons.inventory_2_outlined,
        routeName: AppRoutes.adminItemCreate,
        row: 4,
        staggerOrder: n - 1 - 4,
      ),
      const _AdminHubAction(
        key: ValueKey('admin-hub-item-bulk-move'),
        title: 'Mahsulotlar',
        icon: Icons.grid_view_rounded,
        routeName: AppRoutes.adminItemBulkMove,
        row: 5,
        staggerOrder: n - 1 - 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color targetBackdropColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.68);

    final viewMetrics = MediaQueryData.fromView(View.of(context));
    final double systemBottomInset = dockLayoutBottomInset(
      viewMetrics,
      thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
    );
    const double dockHeight = 60.0;
    final double toggleBottom = appNavigationBarPrimaryButtonBottom(
      dockHeight: dockHeight + systemBottomInset,
    );
    final actions = _actions(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setOpen(false),
              child: AnimatedBuilder(
                animation: _effectsController,
                builder: (context, _) {
                  final double progress =
                      _effectsController.value.clamp(0.0, 1.0);
                  final double backdropOpacity = progress;
                  return Container(
                    color: Color.lerp(
                      Colors.transparent,
                      targetBackdropColor,
                      backdropOpacity,
                    ),
                  );
                },
              ),
            ),
          ),
          PositionedDirectional(
            end: _stackTrailingInset,
            bottom: toggleBottom + _fabClosedSize + _groupButtonGap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int index = 0; index < actions.length; index++) ...[
                  _AdminHubActionPill(
                    key: actions[index].key,
                    action: actions[index],
                    spatial: _spatialController,
                    effectsAnimation: _buildEffectsStagger(
                      actions[index],
                      _effectsController,
                    ),
                    motionKey:
                        ValueKey('admin-hub-reveal-${actions[index].row}'),
                    onTap: () => widget.onOpenRoute(actions[index].routeName),
                  ),
                  if (index != actions.length - 1)
                    const SizedBox(height: _menuItemGap),
                ],
              ],
            ),
          ),
          AnimatedBuilder(
            animation:
                Listenable.merge([_fabMorphController, _effectsController]),
            builder: (context, _) {
              final double progress =
                  _m3SpatialLerpT(_fabMorphController.value);
              final double currentButtonSize =
                  _lerpDouble(_fabClosedSize, _fabOpenSize, progress);
              final double anchoredBottom =
                  toggleBottom + _fabClosedSize - currentButtonSize;
              return PositionedDirectional(
                end: _menuTrailingInset,
                bottom: anchoredBottom,
                child: _AdminMorphFabButton(
                  key: const ValueKey('admin-hub-toggle-button'),
                  fabMorphAnimation: _fabMorphController,
                  effectsAnimation: _effectsController,
                  onTap: () => _setOpen(!_targetOpen),
                  closedSize: _fabClosedSize,
                  openSize: _fabOpenSize,
                  shapeTween: _fabShapeTween,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Animation<double> _buildEffectsStagger(
    _AdminHubAction action,
    Animation<double> parent,
  ) {
    final int order = action.staggerOrder;
    final double start = (order * 0.20).clamp(0.0, 0.76);
    final double end = (start + 0.56).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: parent,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
      reverseCurve: Interval(start, end, curve: Curves.easeInCubic),
    );
  }
}

class _AdminHubAction {
  const _AdminHubAction({
    required this.key,
    required this.title,
    required this.icon,
    required this.routeName,
    required this.row,
    required this.staggerOrder,
  });

  final Key key;
  final String title;
  final IconData icon;
  final String routeName;
  final int row;
  final int staggerOrder;
}

class _AdminHubActionPill extends StatelessWidget {
  const _AdminHubActionPill({
    super.key,
    required this.action,
    required this.spatial,
    required this.effectsAnimation,
    this.motionKey,
    required this.onTap,
  });

  final _AdminHubAction action;
  final Animation<double> spatial;
  final Animation<double> effectsAnimation;
  final Key? motionKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textDirection = Directionality.of(context);
    final TextStyle titleStyle = theme.textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        );
    final TextPainter titlePainter = TextPainter(
      text: TextSpan(text: action.title, style: titleStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final double targetWidth = math.max(
      _adminHubMenuItemHeight,
      _adminHubActionPaddingStart +
          24 +
          _adminHubActionIconGap +
          titlePainter.width +
          _adminHubActionPaddingEnd,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([spatial, effectsAnimation]),
      builder: (context, _) {
        final double widthT =
            _hubStaggerSpatialT(spatial.value, action.staggerOrder);
        final double opacity = effectsAnimation.value.clamp(0.0, 1.0);
        final double currentWidth = _lerpDouble(
          _adminHubMenuItemHeight,
          targetWidth,
          widthT,
        );

        return IgnorePointer(
          ignoring: opacity <= 0.001,
          child: ExcludeSemantics(
            excluding: opacity <= 0.001,
            child: Opacity(
              opacity: opacity,
              child: SizedBox(
                key: motionKey,
                width: currentWidth,
                height: _adminHubMenuItemHeight,
                child: Semantics(
                  button: true,
                  label: action.title,
                  child: Material(
                    color: scheme.primaryContainer,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onTap,
                      child: OverflowBox(
                        alignment: Alignment.centerRight,
                        minWidth: targetWidth,
                        maxWidth: targetWidth,
                        child: SizedBox(
                          width: targetWidth,
                          height: _adminHubMenuItemHeight,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: _adminHubActionPaddingStart,
                              end: _adminHubActionPaddingEnd,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  action.icon,
                                  size: 24,
                                  color: scheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: _adminHubActionIconGap),
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(
                                    action.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminMorphFabButton extends StatelessWidget {
  const _AdminMorphFabButton({
    super.key,
    required this.fabMorphAnimation,
    required this.effectsAnimation,
    required this.onTap,
    required this.closedSize,
    required this.openSize,
    required this.shapeTween,
  });

  final Animation<double> fabMorphAnimation;
  final Animation<double> effectsAnimation;
  final VoidCallback onTap;
  final double closedSize;
  final double openSize;
  final ShapeBorderTween shapeTween;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([fabMorphAnimation, effectsAnimation]),
      builder: (context, child) {
        final double v = fabMorphAnimation.value;
        final double morphT = _m3SpatialLerpT(v);
        final double iconT = effectsAnimation.value.clamp(0.0, 1.0);
        final double stableT = v.clamp(0.0, 1.0);
        final double colorT = stableT;
        final double shapeT = morphT.clamp(0.0, 1.0);
        final double buttonSize = _lerpDouble(closedSize, openSize, morphT);
        final ShapeBorder shape = shapeTween.lerp(shapeT)!;
        final Color containerColor = Color.lerp(
          scheme.primaryContainer,
          scheme.primary,
          colorT,
        )!;
        final Color foregroundColor = Color.lerp(
          scheme.onPrimaryContainer,
          scheme.onPrimary,
          colorT,
        )!;
        const double iconSize = 24.0;

        return Semantics(
          button: true,
          label: iconT >= 0.5
              ? context.l10n.closeAction
              : context.l10n.createHubTitle,
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Material(
              color: containerColor,
              elevation: 6,
              surfaceTintColor: Colors.transparent,
              shadowColor: theme.shadowColor,
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: shape,
                onTap: onTap,
                child: SizedBox.expand(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 1 - iconT,
                        child: Icon(
                          Icons.add_rounded,
                          size: iconSize,
                          color: foregroundColor,
                        ),
                      ),
                      Opacity(
                        opacity: iconT,
                        child: Icon(
                          Icons.close_rounded,
                          size: iconSize,
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

double _lerpDouble(double begin, double end, double t) =>
    begin + ((end - begin) * t);

double _m3SpatialLerpT(double v) => v.clamp(-0.06, 1.18);

double _hubStaggerSpatialT(double v, int staggerOrder) {
  final double start = (staggerOrder * 0.20).clamp(0.0, 0.76);
  final double end = (start + 0.56).clamp(0.0, 1.0);
  if (v <= start) {
    return 0.0;
  }
  final double span = end - start;
  if (span <= 0) {
    return 1.0;
  }
  const double growFraction = 0.86;
  final double spanGrow = span * growFraction;
  final double spanBounce = span - spanGrow;
  if (v < start + spanGrow) {
    final double linearT = ((v - start) / spanGrow).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(linearT);
  }
  if (v <= end && spanBounce > 1e-6) {
    final double u = ((v - start - spanGrow) / spanBounce).clamp(0.0, 1.0);
    const double peak = 0.055;
    return 1.0 + peak * math.sin(math.pi * u);
  }
  return 1.0;
}
