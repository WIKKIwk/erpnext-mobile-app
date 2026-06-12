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
    final candidates = [
      _AdminHubActionCandidate(
        key: const ValueKey('admin-hub-user-create'),
        title: l10n.adminCreateUserTitle,
        icon: Icons.group_add_outlined,
        routeName: AppRoutes.adminUserCreate,
      ),
      _AdminHubActionCandidate(
        key: const ValueKey('admin-hub-item-create'),
        title: l10n.adminCreateItemTitle,
        icon: Icons.inventory_2_outlined,
        routeName: AppRoutes.adminItemCreate,
      ),
      _AdminHubActionCandidate(
        key: const ValueKey('admin-hub-item-group-create'),
        title: l10n.adminCreateItemGroupTitle,
        icon: Icons.account_tree_outlined,
        routeName: AppRoutes.adminItemGroupCreate,
      ),
      const _AdminHubActionCandidate(
        key: ValueKey('admin-hub-calculate-order-create'),
        title: 'Zakaz yaratish',
        icon: Icons.add_task_outlined,
        routeName: AppRoutes.adminCalculate,
      ),
    ];
    final visible = candidates
        .where((action) => AppRouter.canOpenRoute(action.routeName))
        .toList(growable: false);
    final n = visible.length;
    return [
      for (var i = 0; i < visible.length; i++)
        _AdminHubAction(
          key: visible[i].key,
          title: visible[i].title,
          icon: visible[i].icon,
          routeName: visible[i].routeName,
          row: i,
          staggerOrder: n - 1 - i,
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

class _AdminHubActionCandidate {
  const _AdminHubActionCandidate({
    required this.key,
    required this.title,
    required this.icon,
    required this.routeName,
  });

  final Key key;
  final String title;
  final IconData icon;
  final String routeName;
}

class AdminFabMenuAction {
  const AdminFabMenuAction({
    required this.title,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
}

class AdminFabOverlayActionMenu extends StatefulWidget {
  const AdminFabOverlayActionMenu({
    super.key,
    required this.actions,
    required this.closedLabel,
    required this.openLabel,
    required this.closedIcon,
    this.openIcon = Icons.close_rounded,
    this.alignEnd = true,
  });

  final List<AdminFabMenuAction> actions;
  final String closedLabel;
  final String openLabel;
  final IconData closedIcon;
  final IconData openIcon;
  final bool alignEnd;

  @override
  State<AdminFabOverlayActionMenu> createState() =>
      _AdminFabOverlayActionMenuState();
}

class _AdminFabOverlayActionMenuState extends State<AdminFabOverlayActionMenu> {
  OverlayEntry? _entry;
  final GlobalKey<_AdminFabActionOverlayState> _overlayKey =
      GlobalKey<_AdminFabActionOverlayState>();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    final entry = _entry;
    _entry = null;
    if (entry?.mounted ?? false) {
      entry!.remove();
    }
  }

  void _showOverlay() {
    if (_entry != null) {
      _overlayKey.currentState?.setOpen(true);
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _AdminFabActionOverlay(
          key: _overlayKey,
          actions: widget.actions,
          closedLabel: widget.closedLabel,
          openLabel: widget.openLabel,
          closedIcon: widget.closedIcon,
          openIcon: widget.openIcon,
          alignEnd: widget.alignEnd,
          onClose: _removeOverlay,
        );
      },
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return _AdminMorphFabButton(
      fabMorphAnimation: const AlwaysStoppedAnimation<double>(0),
      effectsAnimation: const AlwaysStoppedAnimation<double>(0),
      onTap: _showOverlay,
      closedSize: _AdminCreateHubOverlayState._fabClosedSize,
      openSize: _AdminCreateHubOverlayState._fabOpenSize,
      shapeTween: ShapeBorderTween(
        begin: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            appNavigationBarPrimaryButtonBorderRadius,
          ),
        ),
        end: const CircleBorder(),
      ),
      closedLabel: widget.closedLabel,
      openLabel: widget.openLabel,
      closedIcon: widget.closedIcon,
      openIcon: widget.openIcon,
    );
  }
}

class _AdminFabActionOverlay extends StatefulWidget {
  const _AdminFabActionOverlay({
    super.key,
    required this.actions,
    required this.closedLabel,
    required this.openLabel,
    required this.closedIcon,
    required this.openIcon,
    required this.alignEnd,
    required this.onClose,
  });

  final List<AdminFabMenuAction> actions;
  final String closedLabel;
  final String openLabel;
  final IconData closedIcon;
  final IconData openIcon;
  final bool alignEnd;
  final VoidCallback onClose;

  @override
  State<_AdminFabActionOverlay> createState() => _AdminFabActionOverlayState();
}

class _AdminFabActionOverlayState extends State<_AdminFabActionOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _spatialController = AnimationController(
    vsync: this,
    duration: _AdminCreateHubOverlayState._openDuration,
    reverseDuration: _AdminCreateHubOverlayState._closeDuration,
    lowerBound: _AdminCreateHubOverlayState._spatialLower,
    upperBound: _AdminCreateHubOverlayState._spatialUpper,
  );
  late final AnimationController _fabMorphController = AnimationController(
    vsync: this,
    duration: _AdminCreateHubOverlayState._openDuration,
    reverseDuration: _AdminCreateHubOverlayState._closeDuration,
    lowerBound: _AdminCreateHubOverlayState._fabMorphLower,
    upperBound: _AdminCreateHubOverlayState._fabMorphUpper,
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

  @override
  void dispose() {
    _spatialController.dispose();
    _fabMorphController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  void setOpen(bool open) {
    _setOpen(open);
  }

  void _setOpen(bool open) {
    _targetOpen = open;

    final double target = open ? 1.0 : 0.0;
    final spatialFuture = _animateWithSpring(
      controller: _spatialController,
      spring: open
          ? _AdminCreateHubOverlayState._spatialSpring
          : _AdminCreateHubOverlayState._spatialSpringClose,
      target: target,
    );
    final fabMorphFuture = _animateWithSpring(
      controller: _fabMorphController,
      spring: open
          ? _AdminCreateHubOverlayState._fabMorphSpring
          : _AdminCreateHubOverlayState._fabMorphSpringClose,
      target: target,
    );
    final effectsFuture = _animateWithSpring(
      controller: _effectsController,
      spring: open
          ? _AdminCreateHubOverlayState._effectsSpring
          : _AdminCreateHubOverlayState._effectsSpringClose,
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

  List<_AdminHubAction> _menuActions() {
    final visible = widget.actions;
    final n = visible.length;
    return [
      for (var i = 0; i < visible.length; i++)
        _AdminHubAction(
          key: ValueKey('admin-fab-menu-${visible[i].title}'),
          title: visible[i].title,
          icon: visible[i].icon,
          routeName: '',
          row: i,
          staggerOrder: n - 1 - i,
        ),
    ];
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

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final targetBackdropColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.78)
        : Colors.white.withValues(alpha: 0.68);
    final viewMetrics = MediaQueryData.fromView(View.of(context));
    final systemBottomInset = dockLayoutBottomInset(
      viewMetrics,
      thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
    );
    const dockHeight = 60.0;
    final toggleBottom = appNavigationBarPrimaryButtonBottom(
      dockHeight: dockHeight + systemBottomInset,
    );
    final actions = _menuActions();
    final menuInset = widget.alignEnd
        ? _AdminCreateHubOverlayState._menuTrailingInset
        : _AdminCreateHubOverlayState._stackTrailingInset;
    final motionAlignment =
        widget.alignEnd ? Alignment.bottomRight : Alignment.bottomLeft;

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
                  final progress = _effectsController.value.clamp(0.0, 1.0);
                  return ColoredBox(
                    color: Color.lerp(
                      Colors.transparent,
                      targetBackdropColor,
                      progress,
                    )!,
                  );
                },
              ),
            ),
          ),
          PositionedDirectional(
            start: widget.alignEnd ? null : menuInset,
            end: widget.alignEnd ? menuInset : null,
            bottom: toggleBottom +
                _AdminCreateHubOverlayState._fabClosedSize +
                _AdminCreateHubOverlayState._groupButtonGap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: widget.alignEnd
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
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
                    overflowAlignment: widget.alignEnd
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    motionKey:
                        ValueKey('admin-fab-menu-reveal-${actions[index].row}'),
                    onTap: widget.actions[index].enabled
                        ? () {
                            _setOpen(false);
                            widget.actions[index].onTap();
                          }
                        : null,
                  ),
                  if (index != actions.length - 1)
                    const SizedBox(
                      height: _AdminCreateHubOverlayState._menuItemGap,
                    ),
                ],
              ],
            ),
          ),
          AnimatedBuilder(
            animation:
                Listenable.merge([_fabMorphController, _effectsController]),
            builder: (context, _) {
              final progress = _m3SpatialLerpT(_fabMorphController.value);
              final currentButtonSize = _lerpDouble(
                _AdminCreateHubOverlayState._fabClosedSize,
                _AdminCreateHubOverlayState._fabOpenSize,
                progress,
              );
              final anchoredBottom = toggleBottom +
                  _AdminCreateHubOverlayState._fabClosedSize -
                  currentButtonSize;
              return PositionedDirectional(
                start: widget.alignEnd ? null : menuInset,
                end: widget.alignEnd ? menuInset : null,
                bottom: anchoredBottom,
                child: Transform.scale(
                  alignment: motionAlignment,
                  scale: _adminFabSpringScale(progress),
                  child: _AdminMorphFabButton(
                    fabMorphAnimation: _fabMorphController,
                    effectsAnimation: _effectsController,
                    onTap: () => _setOpen(!_targetOpen),
                    closedSize: _AdminCreateHubOverlayState._fabClosedSize,
                    openSize: _AdminCreateHubOverlayState._fabOpenSize,
                    shapeTween: _fabShapeTween,
                    closedLabel: widget.closedLabel,
                    openLabel: widget.openLabel,
                    closedIcon: widget.closedIcon,
                    openIcon: widget.openIcon,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AdminFabActionMenu extends StatefulWidget {
  const AdminFabActionMenu({
    super.key,
    required this.open,
    required this.actions,
    required this.onToggle,
    required this.closedLabel,
    required this.openLabel,
    required this.closedIcon,
    this.openIcon = Icons.close_rounded,
    this.alignEnd = true,
    this.columns = 1,
  });

  final bool open;
  final List<AdminFabMenuAction> actions;
  final VoidCallback onToggle;
  final String closedLabel;
  final String openLabel;
  final IconData closedIcon;
  final IconData openIcon;
  final bool alignEnd;
  final int columns;

  @override
  State<AdminFabActionMenu> createState() => _AdminFabActionMenuState();
}

class _AdminFabActionMenuState extends State<AdminFabActionMenu>
    with TickerProviderStateMixin {
  late bool _targetOpen = widget.open;

  late final AnimationController _spatialController = AnimationController(
    vsync: this,
    duration: _AdminCreateHubOverlayState._openDuration,
    reverseDuration: _AdminCreateHubOverlayState._closeDuration,
    lowerBound: _AdminCreateHubOverlayState._spatialLower,
    upperBound: _AdminCreateHubOverlayState._spatialUpper,
  );
  late final AnimationController _fabMorphController = AnimationController(
    vsync: this,
    duration: _AdminCreateHubOverlayState._openDuration,
    reverseDuration: _AdminCreateHubOverlayState._closeDuration,
    lowerBound: _AdminCreateHubOverlayState._fabMorphLower,
    upperBound: _AdminCreateHubOverlayState._fabMorphUpper,
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

  @override
  void initState() {
    super.initState();
    _setOpen(widget.open, animate: false);
  }

  @override
  void didUpdateWidget(covariant AdminFabActionMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
      _setOpen(widget.open);
    }
  }

  @override
  void dispose() {
    _spatialController.dispose();
    _fabMorphController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  void _setOpen(bool open, {bool animate = true}) {
    _targetOpen = open;
    final target = open ? 1.0 : 0.0;
    if (!animate) {
      _spatialController.value = target;
      _fabMorphController.value = target;
      _effectsController.value = target;
      return;
    }
    if ((_spatialController.value - target).abs() < 0.001 &&
        (_fabMorphController.value - target).abs() < 0.001 &&
        (_effectsController.value - target).abs() < 0.001) {
      return;
    }
    _animateWithSpring(
      controller: _spatialController,
      spring: open
          ? _AdminCreateHubOverlayState._spatialSpring
          : _AdminCreateHubOverlayState._spatialSpringClose,
      target: target,
    );
    _animateWithSpring(
      controller: _fabMorphController,
      spring: open
          ? _AdminCreateHubOverlayState._fabMorphSpring
          : _AdminCreateHubOverlayState._fabMorphSpringClose,
      target: target,
    );
    _animateWithSpring(
      controller: _effectsController,
      spring: open
          ? _AdminCreateHubOverlayState._effectsSpring
          : _AdminCreateHubOverlayState._effectsSpringClose,
      target: target,
    );
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

  List<_AdminHubAction> _menuActions() {
    final n = widget.actions.length;
    return [
      for (var i = 0; i < widget.actions.length; i++)
        _AdminHubAction(
          key: ValueKey('admin-fab-menu-${widget.actions[i].title}'),
          title: widget.actions[i].title,
          icon: widget.actions[i].icon,
          routeName: '',
          row: i,
          staggerOrder: n - 1 - i,
        ),
    ];
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

  @override
  Widget build(BuildContext context) {
    final actions = _menuActions();
    final columns = widget.columns.clamp(1, 4).toInt();
    final rowCount = (actions.length / columns).ceil();
    final menuHeight = rowCount * _adminHubMenuItemHeight +
        math.max(0, rowCount - 1) * _AdminCreateHubOverlayState._menuItemGap;
    final hostWidth = _menuWidth(context, actions, columns);
    final hostHeight = menuHeight +
        _AdminCreateHubOverlayState._groupButtonGap +
        _AdminCreateHubOverlayState._fabClosedSize;
    final motionAlignment =
        widget.alignEnd ? Alignment.bottomRight : Alignment.bottomLeft;
    return SizedBox(
      width: hostWidth,
      height: hostHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            start: widget.alignEnd ? null : 0,
            end: widget.alignEnd ? 0 : null,
            bottom: _AdminCreateHubOverlayState._fabClosedSize +
                _AdminCreateHubOverlayState._groupButtonGap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: widget.alignEnd
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                for (var rowStart = 0;
                    rowStart < actions.length;
                    rowStart += columns) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var offset = 0; offset < columns; offset++)
                        if (rowStart + offset < actions.length) ...[
                          _AdminHubActionPill(
                            key: actions[rowStart + offset].key,
                            action: actions[rowStart + offset],
                            targetWidth: _targetActionWidth(
                              context,
                              actions[rowStart + offset],
                            ),
                            spatial: _spatialController,
                            effectsAnimation: _buildEffectsStagger(
                              actions[rowStart + offset],
                              _effectsController,
                            ),
                            overflowAlignment: widget.alignEnd
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            motionKey: ValueKey(
                              'admin-fab-menu-reveal-${actions[rowStart + offset].row}',
                            ),
                            onTap: widget.actions[rowStart + offset].enabled
                                ? widget.actions[rowStart + offset].onTap
                                : null,
                          ),
                          if (offset != columns - 1 &&
                              rowStart + offset + 1 < actions.length)
                            const SizedBox(width: 8),
                        ],
                    ],
                  ),
                  if (rowStart + columns < actions.length)
                    const SizedBox(
                      height: _AdminCreateHubOverlayState._menuItemGap,
                    ),
                ],
              ],
            ),
          ),
          AnimatedBuilder(
            animation:
                Listenable.merge([_fabMorphController, _effectsController]),
            builder: (context, _) {
              final progress = _m3SpatialLerpT(_fabMorphController.value);
              final currentButtonSize = _lerpDouble(
                _AdminCreateHubOverlayState._fabClosedSize,
                _AdminCreateHubOverlayState._fabOpenSize,
                progress,
              );
              final buttonScale =
                  _targetOpen ? _adminFabSpringScale(progress) : 1.0;
              final anchoredBottom =
                  _AdminCreateHubOverlayState._fabClosedSize -
                      currentButtonSize;
              return PositionedDirectional(
                start: widget.alignEnd ? null : 0,
                end: widget.alignEnd ? 0 : null,
                bottom: anchoredBottom,
                child: Transform.scale(
                  alignment: motionAlignment,
                  scale: buttonScale,
                  child: _AdminMorphFabButton(
                    fabMorphAnimation: _fabMorphController,
                    effectsAnimation: _effectsController,
                    onTap: () {
                      _setOpen(!_targetOpen);
                      widget.onToggle();
                    },
                    closedSize: _AdminCreateHubOverlayState._fabClosedSize,
                    openSize: _AdminCreateHubOverlayState._fabOpenSize,
                    shapeTween: _fabShapeTween,
                    closedLabel: widget.closedLabel,
                    openLabel: widget.openLabel,
                    closedIcon: widget.closedIcon,
                    openIcon: widget.openIcon,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _menuWidth(
    BuildContext context,
    List<_AdminHubAction> actions,
    int columns,
  ) {
    var width = 0.0;
    for (var rowStart = 0; rowStart < actions.length; rowStart += columns) {
      var rowWidth = 0.0;
      for (var offset = 0; offset < columns; offset++) {
        final index = rowStart + offset;
        if (index >= actions.length) {
          break;
        }
        rowWidth += _targetActionWidth(context, actions[index]);
        if (offset != columns - 1 && index + 1 < actions.length) {
          rowWidth += 8;
        }
      }
      if (rowWidth > width) {
        width = rowWidth;
      }
    }
    return math.max(width, _AdminCreateHubOverlayState._fabClosedSize);
  }

  double _targetActionWidth(BuildContext context, _AdminHubAction action) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textDirection = Directionality.of(context);
    final columns = widget.columns.clamp(1, 4).toInt();
    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    final maxActionWidth =
        (availableWidth - math.max(0, columns - 1) * 8) / columns;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        );
    final titlePainter = TextPainter(
      text: TextSpan(text: action.title, style: titleStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final targetWidth = math.max(
      _adminHubMenuItemHeight,
      _adminHubActionPaddingStart +
          24 +
          _adminHubActionIconGap +
          titlePainter.width +
          _adminHubActionPaddingEnd,
    );
    return math.min(targetWidth, maxActionWidth);
  }
}

class _AdminHubActionPill extends StatelessWidget {
  const _AdminHubActionPill({
    super.key,
    required this.action,
    required this.spatial,
    required this.effectsAnimation,
    this.targetWidth,
    this.motionKey,
    required this.onTap,
    this.overflowAlignment = Alignment.centerRight,
  });

  final _AdminHubAction action;
  final double? targetWidth;
  final Animation<double> spatial;
  final Animation<double> effectsAnimation;
  final Key? motionKey;
  final VoidCallback? onTap;
  final Alignment overflowAlignment;

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
    final titlePainter = TextPainter(
      text: TextSpan(text: action.title, style: titleStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final resolvedTargetWidth = targetWidth ??
        math.max(
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
        final double scale = _adminFabSpringScale(widthT);
        final double currentWidth = _lerpDouble(
          _adminHubMenuItemHeight,
          resolvedTargetWidth,
          widthT,
        );

        return IgnorePointer(
          ignoring: opacity <= 0.001,
          child: ExcludeSemantics(
            excluding: opacity <= 0.001,
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                alignment: overflowAlignment,
                scale: scale,
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
                          alignment: overflowAlignment,
                          minWidth: resolvedTargetWidth,
                          maxWidth: resolvedTargetWidth,
                          child: SizedBox(
                            width: resolvedTargetWidth,
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
          ),
        );
      },
    );
  }
}

double _adminFabSpringScale(double t) {
  final clamped = t.clamp(0.0, 1.14);
  if (clamped <= 1.0) {
    return _lerpDouble(0.86, 1.0, clamped);
  }
  return 1.0 + ((clamped - 1.0) * 0.18);
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
    this.closedLabel,
    this.openLabel,
    this.closedIcon = Icons.add_rounded,
    this.openIcon = Icons.close_rounded,
  });

  final Animation<double> fabMorphAnimation;
  final Animation<double> effectsAnimation;
  final VoidCallback onTap;
  final double closedSize;
  final double openSize;
  final ShapeBorderTween shapeTween;
  final String? closedLabel;
  final String? openLabel;
  final IconData closedIcon;
  final IconData openIcon;

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
              ? openLabel ?? context.l10n.closeAction
              : closedLabel ?? context.l10n.createHubTitle,
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Material(
              color: containerColor,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
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
                          closedIcon,
                          size: iconSize,
                          color: foregroundColor,
                        ),
                      ),
                      Opacity(
                        opacity: iconT,
                        child: Icon(
                          openIcon,
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
