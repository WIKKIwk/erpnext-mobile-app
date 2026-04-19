import 'dart:math' as math;

import '../../../../app/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

final ValueNotifier<bool> werkaCreateHubMenuOpen = ValueNotifier<bool>(false);

Future<void> showWerkaCreateHubSheet(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;

  werkaCreateHubMenuOpen.value = true;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: scheme.scrim.withValues(alpha: 0.58),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _WerkaCreateHubFloatingMenu(
        onClose: () => Navigator.of(dialogContext).pop(),
        onOpenRoute: (routeName) => _closeAndOpenRoute(
          dialogContext: dialogContext,
          parentContext: context,
          routeName: routeName,
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  ).whenComplete(() {
    werkaCreateHubMenuOpen.value = false;
  });
}

void _closeAndOpenRoute({
  required BuildContext dialogContext,
  required BuildContext parentContext,
  required String routeName,
}) {
  final navigator = Navigator.of(parentContext);
  Navigator.of(dialogContext).pop();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigator.pushNamed(routeName);
  });
}

class _WerkaCreateHubFloatingMenu extends StatefulWidget {
  const _WerkaCreateHubFloatingMenu({
    required this.onClose,
    required this.onOpenRoute,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onOpenRoute;

  @override
  State<_WerkaCreateHubFloatingMenu> createState() =>
      _WerkaCreateHubFloatingMenuState();
}

class _WerkaCreateHubFloatingMenuState
    extends State<_WerkaCreateHubFloatingMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final menuWidth = math.min(320.0, size.width - 32.0);
    const double bottomAnchor = 112.0;
    const double menuGap = 14.0;
    const double collapsedButtonSize = 58.0;
    const double expandedButtonSize = 84.0;
    final items = [
      _WerkaFloatingActionItem(
        title: l10n.unannouncedTitle,
        description: l10n.unannouncedDescription,
        icon: Icons.inventory_2_outlined,
        animation: CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.08, 0.78, curve: Curves.easeOutCubic),
        ),
        onTap: () => widget.onOpenRoute(AppRoutes.werkaUnannouncedSupplier),
      ),
      _WerkaFloatingActionItem(
        title: l10n.customerIssueTitle,
        description: l10n.customerIssueDescription,
        icon: Icons.send_outlined,
        animation: CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.18, 0.88, curve: Curves.easeOutCubic),
        ),
        onTap: () => widget.onOpenRoute(AppRoutes.werkaCustomerIssueCustomer),
      ),
      _WerkaFloatingActionItem(
        title: l10n.batchDispatchTitle,
        description: l10n.batchDispatchDescription,
        icon: Icons.playlist_add_check_rounded,
        animation: CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.28, 1.0, curve: Curves.easeOutCubic),
        ),
        onTap: () => widget.onOpenRoute(AppRoutes.werkaBatchDispatch),
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: false,
        minimum: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: const SizedBox.expand(),
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: bottomAnchor + collapsedButtonSize + menuGap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int index = 0; index < items.length; index++) ...[
                    SizedBox(
                      width: menuWidth,
                      child: items[index],
                    ),
                    if (index != items.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            PositionedDirectional(
              end: 16,
              bottom: bottomAnchor,
              child: _WerkaCreateHubToggleButton(
                animation: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutBack,
                ),
                onTap: widget.onClose,
                color: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                collapsedSize: collapsedButtonSize,
                expandedSize: expandedButtonSize,
                expandedBorderRadius: 22.0,
              ),
            ),
          ],
        ),
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
        final value = Curves.easeOutCubic.transform(animation.value.clamp(
          0.0,
          1.0,
        ));
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(22 * (1 - value), 18 * (1 - value)),
            child: Transform.scale(
              scale: 0.98 + (0.02 * value),
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
        final value = Curves.easeOutBack.transform(animation.value.clamp(
          0.0,
          1.0,
        ));
        final size = _lerpDouble(expandedSize, collapsedSize, value);
        final radius = _lerpDouble(expandedBorderRadius, size / 2, value);
        return SizedBox(
          width: size,
          height: size,
          child: Material(
            color: color,
            elevation: 8,
            shadowColor: color.withValues(alpha: 0.32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              onTap: onTap,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 1 - value,
                      child: Transform.rotate(
                        angle: math.pi * 0.18 * value,
                        child: Icon(
                          Icons.add_rounded,
                          color: foregroundColor,
                          size: 28.5 - (1.5 * value),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: value,
                      child: Icon(
                        Icons.close_rounded,
                        color: foregroundColor,
                        size: 28,
                      ),
                    ),
                  ],
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
