import 'dart:math' as math;

import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
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
  static const double _toggleBottom = 112.0;
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
    duration: const Duration(milliseconds: 180),
  )..forward();

  @override
  void dispose() {
    _menuController.dispose();
    _toggleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final menuWidth = math.min(320.0, size.width - 32.0);
    final menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final toggleAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final items = [
      _WerkaFloatingActionItem(
        title: l10n.unannouncedTitle,
        description: l10n.unannouncedDescription,
        icon: Icons.inventory_2_outlined,
        animation: CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.00, 0.46, curve: Curves.easeOutCubic),
        ),
        onTap: () => widget.onOpenRoute(AppRoutes.werkaUnannouncedSupplier),
      ),
      _WerkaFloatingActionItem(
        title: l10n.customerIssueTitle,
        description: l10n.customerIssueDescription,
        icon: Icons.send_outlined,
        animation: CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.08, 0.54, curve: Curves.easeOutCubic),
        ),
        onTap: () => widget.onOpenRoute(AppRoutes.werkaCustomerIssueCustomer),
      ),
      _WerkaFloatingActionItem(
        title: l10n.batchDispatchTitle,
        description: l10n.batchDispatchDescription,
        icon: Icons.playlist_add_check_rounded,
        animation: CurvedAnimation(
          parent: _menuController,
          curve: const Interval(0.16, 0.62, curve: Curves.easeOutCubic),
        ),
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
                  return Container(
                    color: Colors.black.withValues(alpha: 0.34 * menuAnimation.value),
                  );
                },
              ),
            ),
          ),
          PositionedDirectional(
            end: 16,
            bottom: _toggleBottom + _toggleCollapsedSize + _menuGap,
            child: AnimatedBuilder(
              animation: menuAnimation,
              builder: (context, child) {
                final value = menuAnimation.value;
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(22 * (1 - value), 18 * (1 - value)),
                    child: child,
                  ),
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
            bottom: _toggleBottom,
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
    required this.description,
    required this.icon,
    required this.animation,
    required this.onTap,
  });

  final String title;
  final String description;
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
        final settle = Curves.easeOutCubic.transform(value);
        final xOffset = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 84, end: 0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ),
            weight: 74,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: -8.0).chain(
              CurveTween(curve: Curves.easeOutQuad),
            ),
            weight: 13,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -8.0, end: 0.0).chain(
              CurveTween(curve: Curves.easeOutQuad),
            ),
            weight: 13,
          ),
        ]).transform(settle);
        final yOffset = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 32, end: 0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ),
            weight: 74,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: -4.0).chain(
              CurveTween(curve: Curves.easeOutQuad),
            ),
            weight: 13,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -4.0, end: 0.0).chain(
              CurveTween(curve: Curves.easeOutQuad),
            ),
            weight: 13,
          ),
        ]).transform(settle);
        final scale = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.92, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ),
            weight: 80,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.015).chain(
              CurveTween(curve: Curves.easeOutQuad),
            ),
            weight: 10,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.015, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutQuad),
            ),
            weight: 10,
          ),
        ]).transform(settle);
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
        color: scheme.primaryContainer.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow.withValues(alpha: 0.82),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(
                            alpha: 0.74,
                          ),
                        ),
                      ),
                    ],
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
        final scale =
            _lerpDouble(1.0, collapsedSize / expandedSize, value);
        final radius =
            _lerpDouble(expandedBorderRadius, expandedSize / 2, value);
        return SizedBox(
          width: expandedSize,
          height: expandedSize,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Material(
                color: color,
                elevation: 8,
                shadowColor: color.withValues(alpha: 0.28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  onTap: onTap,
                  child: Center(
                    child: Transform.rotate(
                      angle: (-math.pi / 4) * value,
                      child: Transform.scale(
                        scale: 1 - (0.06 * value),
                        child: Icon(
                          Icons.add_rounded,
                          color: foregroundColor,
                          size: 28.5 - (1.5 * value),
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

double _lerpDouble(double begin, double end, double t) =>
    begin + ((end - begin) * t);
