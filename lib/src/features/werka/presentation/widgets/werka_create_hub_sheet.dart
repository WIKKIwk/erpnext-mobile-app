import 'dart:async';
import 'dart:math' as math;

import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/navigation/app_navigation_bar.dart';
import '../../../../core/widgets/navigation/dock_gesture_overlay.dart';
import '../../../../core/widgets/navigation/dock_system_bottom_inset.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> werkaCreateHubMenuOpen = ValueNotifier<bool>(false);
const double _werkaHubMenuItemHeight = 56.0;
const double _werkaHubActionPaddingStart = 14.0;
const double _werkaHubActionPaddingEnd = 14.0;
const double _werkaHubActionIconGap = 10.0;

OverlayEntry? _werkaCreateHubOverlayEntry;
final GlobalKey<_WerkaCreateHubOverlayState> _werkaCreateHubOverlayKey =
    GlobalKey<_WerkaCreateHubOverlayState>();

void showWerkaCreateHubSheet(BuildContext context) {
  if (_werkaCreateHubOverlayEntry != null) {
    _werkaCreateHubOverlayKey.currentState?.setOpen(true);
    return;
  }

  final overlay = Overlay.of(context, rootOverlay: true);
  final navigator = Navigator.of(context);
  late final OverlayEntry entry;

  void closeMenuNow() {
    werkaCreateHubMenuOpen.value = false;
    if (entry.mounted) {
      entry.remove();
    }
    if (_werkaCreateHubOverlayEntry == entry) {
      _werkaCreateHubOverlayEntry = null;
    }
  }

  void requestCloseMenu() {
    final currentState = _werkaCreateHubOverlayKey.currentState;
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
      return _WerkaCreateHubOverlay(
        key: _werkaCreateHubOverlayKey,
        onClose: closeMenuNow,
        onOpenRoute: openRoute,
      );
    },
  );

  _werkaCreateHubOverlayEntry = entry;
  werkaCreateHubMenuOpen.value = true;
  overlay.insert(entry);
}

class _WerkaCreateHubOverlay extends StatefulWidget {
  const _WerkaCreateHubOverlay({
    super.key,
    required this.onClose,
    required this.onOpenRoute,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onOpenRoute;

  @override
  State<_WerkaCreateHubOverlay> createState() => _WerkaCreateHubOverlayState();
}

class _WerkaCreateHubOverlayState extends State<_WerkaCreateHubOverlay>
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

  /// FAB circle ↔ rounded rect: slightly under-damped for settle bounce.
  static final SpringDescription _fabMorphSpring =
      SpringDescription.withDampingRatio(
    mass: 0.55,
    stiffness: 2350.0,
    ratio: 0.72,
  );
  static final SpringDescription _fabMorphSpringClose = _fabMorphSpring;
  static const Duration _openDuration = Duration(milliseconds: 1080);
  static const Duration _closeDuration = Duration(milliseconds: 1080);

  /// Wider than [0,1] so [SpringSimulation] can overshoot (M3 Expressive spatial).
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
    _werkaCreateHubOverlayEntry = null;
    werkaCreateHubMenuOpen.value = false;
    _spatialController.dispose();
    _fabMorphController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    _targetOpen = open;
    if (open) {
      werkaCreateHubMenuOpen.value = true;
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

  List<_WerkaHubAction> _actions(BuildContext context) {
    final l10n = context.l10n;
    const n = 3;
    return [
      _WerkaHubAction(
        key: const ValueKey('werka-hub-unannounced'),
        title: l10n.unannouncedTitle,
        icon: Icons.inventory_2_outlined,
        routeName: AppRoutes.werkaUnannouncedSupplier,
        row: 0,
        staggerOrder: n - 1 - 0,
      ),
      _WerkaHubAction(
        key: const ValueKey('werka-hub-customer-issue'),
        title: l10n.customerIssueTitle,
        icon: Icons.send_outlined,
        routeName: AppRoutes.werkaCustomerIssueCustomer,
        row: 1,
        staggerOrder: n - 1 - 1,
      ),
      _WerkaHubAction(
        key: const ValueKey('werka-hub-batch-dispatch'),
        title: l10n.batchDispatchTitle,
        icon: Icons.playlist_add_check_rounded,
        routeName: AppRoutes.werkaBatchDispatch,
        row: 2,
        staggerOrder: n - 1 - 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Qorong‘i temada kuchliroq qora scrim; yorug‘ temada orqani «oqartirib» yuvish (oqboshli scrim).
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
                  _WerkaHubActionPill(
                    key: actions[index].key,
                    action: actions[index],
                    spatial: _spatialController,
                    effectsAnimation: _buildEffectsStagger(
                      actions[index],
                      _effectsController,
                    ),
                    motionKey:
                        ValueKey('werka-hub-reveal-${actions[index].row}'),
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
                child: _WerkaMorphFabButton(
                  key: const ValueKey('werka-hub-toggle-button'),
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

  /// Opacity only: no overshoot (M3 fast effects).
  Animation<double> _buildEffectsStagger(
    _WerkaHubAction action,
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

class _WerkaHubAction {
  const _WerkaHubAction({
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

  /// 0 = first in the reveal sequence (FAB-proximal / bottom in the column).
  final int staggerOrder;
}

class _WerkaHubActionPill extends StatelessWidget {
  const _WerkaHubActionPill({
    super.key,
    required this.action,
    required this.spatial,
    required this.effectsAnimation,
    this.motionKey,
    required this.onTap,
  });

  final _WerkaHubAction action;
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
      _werkaHubMenuItemHeight,
      _werkaHubActionPaddingStart +
          24 +
          _werkaHubActionIconGap +
          titlePainter.width +
          _werkaHubActionPaddingEnd,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([spatial, effectsAnimation]),
      builder: (context, _) {
        final double widthT =
            _hubStaggerSpatialT(spatial.value, action.staggerOrder);
        final double opacity = effectsAnimation.value.clamp(0.0, 1.0);
        final double currentWidth = _lerpDouble(
          _werkaHubMenuItemHeight,
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
                height: _werkaHubMenuItemHeight,
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
                          height: _werkaHubMenuItemHeight,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: _werkaHubActionPaddingStart,
                              end: _werkaHubActionPaddingEnd,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  action.icon,
                                  size: 24,
                                  color: scheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: _werkaHubActionIconGap),
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

class _WerkaMorphFabButton extends StatelessWidget {
  const _WerkaMorphFabButton({
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
        // Shape must track the same morph as size (clamp to 1): no t² / sync lag
        // or corners keep animating after the button already looks circular.
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

/// Spring value may exceed 0–1; clamp for expressive overshoot (hub width + FAB size).
double _m3SpatialLerpT(double v) => v.clamp(-0.06, 1.18);

/// Same stagger windows as [_buildEffectsStagger], driven by raw spatial [v].
///
/// Grow is linear for most of the window; the last segment is a short sine hump so
/// each row gets a visible overshoot when *that* row finishes, not only the last.
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
