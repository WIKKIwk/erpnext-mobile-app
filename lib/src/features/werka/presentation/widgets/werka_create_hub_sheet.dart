import 'dart:async';
import 'dart:math' as math;

import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/widgets/app_navigation_bar.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> werkaCreateHubMenuOpen = ValueNotifier<bool>(false);
const double _werkaHubMenuItemHeight = 56.0;
const double _werkaHubActionPaddingStart = 8.0;
const double _werkaHubActionPaddingEnd = 10.0;
const double _werkaHubActionIconGap = 8.0;

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
      AppMotion.m3ExpressiveFastSpatial;
  static final SpringDescription _effectsSpring =
      AppMotion.m3ExpressiveFastEffects;
  static const Duration _openDuration = Duration(milliseconds: 280);
  static const Duration _closeDuration = Duration(milliseconds: 210);

  /// Wider than [0,1] so [SpringSimulation] can overshoot (M3 Expressive spatial).
  static const double _spatialLower = -0.08;
  static const double _spatialUpper = 1.22;

  late final AnimationController _spatialController = AnimationController(
    vsync: this,
    duration: _openDuration,
    reverseDuration: _closeDuration,
    lowerBound: _spatialLower,
    upperBound: _spatialUpper,
  );
  late final AnimationController _effectsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );
  late final ShapeBorderTween _fabShapeTween = ShapeBorderTween(
    begin: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
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
        (_effectsController.value - target).abs() < 0.001) {
      if (!open) {
        widget.onClose();
      }
      return;
    }

    final spatialFuture = _animateWithSpring(
      controller: _spatialController,
      spring: _spatialSpring,
      target: target,
    );
    final effectsFuture = _animateWithSpring(
      controller: _effectsController,
      spring: _effectsSpring,
      target: target,
    );

    if (!open) {
      unawaited(
        () async {
          try {
            await Future.wait<void>([
              spatialFuture.orCancel,
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
    return [
      _WerkaHubAction(
        key: const ValueKey('werka-hub-unannounced'),
        title: l10n.unannouncedTitle,
        icon: Icons.inventory_2_outlined,
        routeName: AppRoutes.werkaUnannouncedSupplier,
        row: 0,
      ),
      _WerkaHubAction(
        key: const ValueKey('werka-hub-customer-issue'),
        title: l10n.customerIssueTitle,
        icon: Icons.send_outlined,
        routeName: AppRoutes.werkaCustomerIssueCustomer,
        row: 1,
      ),
      _WerkaHubAction(
        key: const ValueKey('werka-hub-batch-dispatch'),
        title: l10n.batchDispatchTitle,
        icon: Icons.playlist_add_check_rounded,
        routeName: AppRoutes.werkaBatchDispatch,
        row: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color targetBackdropColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.50)
        : Colors.black.withValues(alpha: 0.34);

    final viewMetrics = MediaQueryData.fromView(View.of(context));
    final double systemBottomInset = math.max(
      viewMetrics.viewPadding.bottom,
      viewMetrics.systemGestureInsets.bottom,
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
                  final double backdropOpacity = progress * 0.96;
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
                    motionKey: ValueKey('werka-hub-reveal-${actions[index].row}'),
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
                Listenable.merge([_spatialController, _effectsController]),
            builder: (context, _) {
              final double progress =
                  _m3SpatialLerpT(_spatialController.value);
              final double currentButtonSize =
                  _lerpDouble(_fabClosedSize, _fabOpenSize, progress);
              final double anchoredBottom =
                  toggleBottom + _fabClosedSize - currentButtonSize;
              return PositionedDirectional(
                end: _menuTrailingInset,
                bottom: anchoredBottom,
                child: _WerkaMorphFabButton(
                  key: const ValueKey('werka-hub-toggle-button'),
                  spatialAnimation: _spatialController,
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
    final int row = action.row;
    final double start = (row * 0.12).clamp(0.0, 0.78);
    final double end = (start + 0.58).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: parent,
      curve: Interval(start, end, curve: Curves.linear),
      reverseCurve: Interval(start, end, curve: Curves.linear),
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
  });

  final Key key;
  final String title;
  final IconData icon;
  final String routeName;
  final int row;
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
            _hubStaggerSpatialT(spatial.value, action.row);
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
    required this.spatialAnimation,
    required this.effectsAnimation,
    required this.onTap,
    required this.closedSize,
    required this.openSize,
    required this.shapeTween,
  });

  final Animation<double> spatialAnimation;
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
      animation: Listenable.merge([spatialAnimation, effectsAnimation]),
      builder: (context, child) {
        final double raw = spatialAnimation.value;
        final double morphT = _m3SpatialLerpT(raw);
        final double iconT = effectsAnimation.value.clamp(0.0, 1.0);
        final double shapeAndColorT = raw.clamp(0.0, 1.0);
        final double buttonSize = _lerpDouble(closedSize, openSize, morphT);
        final ShapeBorder shape = shapeTween.lerp(shapeAndColorT)!;
        final Color containerColor = Color.lerp(
          scheme.primaryContainer,
          scheme.primary,
          shapeAndColorT,
        )!;
        final Color foregroundColor = Color.lerp(
          scheme.onPrimaryContainer,
          scheme.onPrimary,
          shapeAndColorT,
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

/// Spatial spring may exceed 0–1; allow extrapolation for size (Expressive overshoot).
double _m3SpatialLerpT(double v) => v.clamp(-0.06, 1.18);

/// Same stagger windows as before [Interval], but driven by raw spatial spring value.
double _hubStaggerSpatialT(double v, int row) {
  final double start = (row * 0.12).clamp(0.0, 0.78);
  final double end = (start + 0.58).clamp(0.0, 1.0);
  if (v <= start) {
    return 0.0;
  }
  final double span = end - start;
  if (span <= 0) {
    return 1.0;
  }
  return ((v - start) / span).clamp(0.0, 1.22);
}
