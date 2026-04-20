import 'dart:math' as math;
import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_navigation_bar.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> werkaCreateHubMenuOpen = ValueNotifier<bool>(false);

OverlayEntry? _werkaCreateHubOverlayEntry;

void showWerkaCreateHubSheet(BuildContext context) {
  if (_werkaCreateHubOverlayEntry != null) {
    return;
  }

  final overlay = Overlay.of(context, rootOverlay: true);

  final navigator = Navigator.of(context);
  late final OverlayEntry entry;

  void closeMenu() {
    if (entry.mounted) {
      entry.remove();
    }
    werkaCreateHubMenuOpen.value = false;
    if (_werkaCreateHubOverlayEntry == entry) {
      _werkaCreateHubOverlayEntry = null;
    }
  }

  void openRoute(String routeName) {
    closeMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigator.pushNamed(routeName);
    });
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      return _WerkaCreateHubOverlay(
        onClose: closeMenu,
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
  static const double _toggleCollapsedSize = 58.0;
  static const double _toggleExpandedSize = 84.0;
  static const double _menuGap = 34.0;
  static const double _menuSpacing = 10.0;

  late final AnimationController _menuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final AnimationController _toggleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 30),
    reverseDuration: const Duration(milliseconds: 125),
  )..forward();

  @override
  void dispose() {
    _menuController.dispose();
    _toggleController.dispose();
    super.dispose();
  }

  CurvedAnimation _actionCardAnimation({
    required int orderFromBottom,
  }) {
    final start = 0.02 + (orderFromBottom * 0.10);
    final end = (start + 0.42).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _menuController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeInCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color backdropColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.34);
    final size = MediaQuery.sizeOf(context);
    final menuWidth = math.min(320.0, size.width - 32.0);
    final viewMetrics = MediaQueryData.fromView(View.of(context));
    final double systemBottomInset = math.max(
      viewMetrics.viewPadding.bottom,
      viewMetrics.systemGestureInsets.bottom,
    );
    const double dockHeight = 60.0;
    final double toggleBottom = appNavigationBarPrimaryButtonBottom(
      dockHeight: dockHeight + systemBottomInset,
    );
    final menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final toggleAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: Easing.standardDecelerate,
      reverseCurve: Easing.standardAccelerate,
    );
    final items = [
      _WerkaFloatingActionItem(
        animation: _actionCardAnimation(orderFromBottom: 2),
        title: l10n.unannouncedTitle,
        icon: Icons.inventory_2_outlined,
        onTap: () => widget.onOpenRoute(AppRoutes.werkaUnannouncedSupplier),
      ),
      _WerkaFloatingActionItem(
        animation: _actionCardAnimation(orderFromBottom: 1),
        title: l10n.customerIssueTitle,
        icon: Icons.send_outlined,
        onTap: () => widget.onOpenRoute(AppRoutes.werkaCustomerIssueCustomer),
      ),
      _WerkaFloatingActionItem(
        animation: _actionCardAnimation(orderFromBottom: 0),
        title: l10n.batchDispatchTitle,
        icon: Icons.playlist_add_check_rounded,
        onTap: () => widget.onOpenRoute(AppRoutes.werkaBatchDispatch),
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: AnimatedBuilder(
                animation: menuAnimation,
                builder: (context, _) {
                  final value = menuAnimation.value;
                  return Container(
                    color: Color.lerp(
                      Colors.transparent,
                      backdropColor,
                      value,
                    ),
                  );
                },
              ),
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: toggleBottom + _toggleCollapsedSize + _menuGap,
            child: AnimatedBuilder(
              animation: menuAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: menuAnimation.value,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int index = 0; index < items.length; index++) ...[
                    SizedBox(
                      width: menuWidth,
                      child: items[index],
                    ),
                    if (index != items.length - 1)
                      const SizedBox(height: _menuSpacing),
                  ],
                ],
              ),
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: toggleBottom,
            child: _WerkaCreateHubToggleButton(
              animation: toggleAnimation,
              onTap: widget.onClose,
              color: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              collapsedSize: _toggleCollapsedSize,
              expandedSize: _toggleExpandedSize,
              expandedBorderRadius: 22.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WerkaFloatingActionItem extends StatelessWidget {
  const _WerkaFloatingActionItem({
    required this.title,
    required this.icon,
    required this.animation,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0);
        final xOffset = _tweenSequence(
          value,
          const [
            _TweenStep<double>(18, 0, Curves.easeOutCubic, 0.82),
            _TweenStep<double>(0, 3, Curves.easeOutQuad, 0.10),
            _TweenStep<double>(3, 0, Curves.easeOutQuad, 0.08),
          ],
        );
        final yOffset = _tweenSequence(
          value,
          const [
            _TweenStep<double>(26, 0, Curves.easeOutCubic, 0.82),
            _TweenStep<double>(0, -4, Curves.easeOutQuad, 0.10),
            _TweenStep<double>(-4, 0, Curves.easeOutQuad, 0.08),
          ],
        );
        final scale = _tweenSequence(
          value,
          const [
            _TweenStep<double>(0.98, 1.01, Curves.easeOutCubic, 0.84),
            _TweenStep<double>(1.01, 1.0, Curves.easeOutQuad, 0.16),
          ],
        );
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(xOffset, yOffset),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: scheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: scheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WerkaCreateHubToggleButton extends StatelessWidget {
  const _WerkaCreateHubToggleButton({
    required this.animation,
    required this.onTap,
    required this.color,
    required this.foregroundColor,
    required this.collapsedSize,
    required this.expandedSize,
    required this.expandedBorderRadius,
  });

  final Animation<double> animation;
  final VoidCallback onTap;
  final Color color;
  final Color foregroundColor;
  final double collapsedSize;
  final double expandedSize;
  final double expandedBorderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0);
        final morphProgress =
            Easing.standardDecelerate.transform((value * 2.1).clamp(0.0, 1.0));
        final iconProgress = Easing.standardDecelerate.transform(value);
        final buttonScale = _lerpDouble(1.0, 0.74, morphProgress);
        final radius = _lerpDouble(
          expandedBorderRadius,
          expandedSize / 2,
          morphProgress,
        );
        return SizedBox(
          width: expandedSize,
          height: expandedSize,
          child: Center(
            child: Transform.scale(
              scale: buttonScale,
              alignment: Alignment.center,
              child: Material(
                color: color,
                elevation: 8,
                shadowColor: color.withValues(alpha: 0.28),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  onTap: onTap,
                  child: SizedBox.square(
                    dimension: expandedSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 1 - iconProgress,
                          child: Transform.rotate(
                            angle: (-math.pi / 4) * iconProgress,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add_rounded,
                              color: foregroundColor,
                              size: 28.5,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: iconProgress,
                          child: Icon(
                            Icons.close_rounded,
                            color: foregroundColor,
                            size: 28.5,
                          ),
                        ),
                      ],
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

class _TweenStep<T extends num> {
  const _TweenStep(
    this.begin,
    this.end,
    this.curve,
    this.weight,
  );

  final T begin;
  final T end;
  final Curve curve;
  final double weight;
}

double _tweenSequence(
  double value,
  List<_TweenStep<double>> steps,
) {
  return TweenSequence<double>(
    steps
        .map(
          (step) => TweenSequenceItem(
            tween: Tween<double>(begin: step.begin, end: step.end).chain(
              CurveTween(curve: step.curve),
            ),
            weight: step.weight,
          ),
        )
        .toList(growable: false),
  ).transform(value);
}

double _lerpDouble(double begin, double end, double t) =>
    begin + ((end - begin) * t);
