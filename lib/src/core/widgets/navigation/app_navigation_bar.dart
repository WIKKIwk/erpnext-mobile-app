import 'package:flutter/material.dart';

import 'dock_gesture_overlay.dart';
import 'dock_system_bottom_inset.dart';

const double appNavigationBarHeight = 80.0;
const double appNavigationBarPrimaryButtonSize = 80.0;

/// Default dock plus / primary action (80×80). Lower = sharper corners.
const double appNavigationBarPrimaryButtonBorderRadius = 22.0;
const double appNavigationBarPrimaryButtonGap = 44.0;
const double appNavigationBarPrimaryButtonLift = 10.0;

double appNavigationBarPrimaryButtonBottom({
  required double dockHeight,
}) {
  return dockHeight +
      appNavigationBarPrimaryButtonGap -
      (appNavigationBarPrimaryButtonSize / 2) +
      appNavigationBarPrimaryButtonLift;
}

double appNavigationBarDockHeight({
  required double height,
  required double systemBottomInset,
}) {
  return height + systemBottomInset;
}

class AppNavigationDestination {
  const AppNavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.onLongPress,
    this.showBadge = false,
    this.isPrimary = false,
  });

  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final VoidCallback? onLongPress;
  final bool showBadge;
  final bool isPrimary;
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.selectionVisible = true,
    this.height = appNavigationBarHeight,
    this.primaryVisible = true,
  });

  final List<AppNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool selectionVisible;
  final double height;
  final bool primaryVisible;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData viewMetrics =
        MediaQueryData.fromView(View.of(context));
    final double systemBottomInset = dockLayoutBottomInset(
      viewMetrics,
      thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
    );

    if (destinations.isEmpty) {
      return SizedBox(height: height + systemBottomInset);
    }

    final int effectiveIndex =
        selectedIndex.clamp(0, destinations.length - 1).toInt();
    final int primaryIndex =
        destinations.indexWhere((destination) => destination.isPrimary);
    final bool hasPrimary = primaryIndex != -1;
    final bool primarySelected = hasPrimary && effectiveIndex == primaryIndex;
    final bool barSelectionVisible = selectionVisible && !primarySelected;
    final List<AppNavigationDestination> barDestinations = hasPrimary
        ? destinations
            .asMap()
            .entries
            .where((entry) => entry.key != primaryIndex)
            .map((entry) => entry.value)
            .toList()
        : destinations;
    final int barSelectedIndex = hasPrimary
        ? primarySelected || barDestinations.isEmpty
            ? 0
            : destinations
                .take(effectiveIndex)
                .where((destination) => !destination.isPrimary)
                .length
                .clamp(0, barDestinations.length - 1)
                .toInt()
        : effectiveIndex;
    final double dockHeight = appNavigationBarDockHeight(
      height: height,
      systemBottomInset: systemBottomInset,
    );
    final double hostHeight = dockHeight +
        (hasPrimary && primaryVisible
            ? appNavigationBarPrimaryButtonSize +
                appNavigationBarPrimaryButtonGap
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
            key: const ValueKey('app-navigation-bar-host'),
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
                    key: const ValueKey('app-navigation-bar-shell'),
                    width: availableWidth,
                    height: dockHeight,
                    child: MediaQuery(
                      data: viewMetrics.copyWith(
                        padding: EdgeInsets.only(bottom: systemBottomInset),
                      ),
                      child: _SelectionAwareNavigationBarTheme(
                        enabled: barSelectionVisible,
                        height: height,
                        child: NavigationBar(
                          height: height,
                          selectedIndex: barSelectedIndex,
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          onDestinationSelected: (index) {
                            final destination = barDestinations[index];
                            final originalIndex =
                                destinations.indexOf(destination);
                            onDestinationSelected(originalIndex);
                          },
                          destinations: List<NavigationDestination>.generate(
                            barDestinations.length,
                            (index) {
                              final destination = barDestinations[index];
                              return NavigationDestination(
                                label: destination.label,
                                tooltip:
                                    destination.onLongPress == null ? null : '',
                                icon: _AppNavigationDestinationIcon(
                                  destination: destination,
                                  selected: false,
                                ),
                                selectedIcon: _AppNavigationDestinationIcon(
                                  destination: destination,
                                  selected: true,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasPrimary && primaryVisible)
                  PositionedDirectional(
                    end: 16,
                    bottom: appNavigationBarPrimaryButtonBottom(
                      dockHeight: dockHeight,
                    ),
                    child: _AppPrimaryNavigationButton(
                      destination: destinations[primaryIndex],
                      selected: primarySelected,
                      onTap: () => onDestinationSelected(primaryIndex),
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

class _SelectionAwareNavigationBarTheme extends StatelessWidget {
  const _SelectionAwareNavigationBarTheme({
    required this.enabled,
    required this.height,
    required this.child,
  });

  final bool enabled;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return child;
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? unselectedLabelStyle =
        theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: height,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final bool disabled = states.contains(WidgetState.disabled);
          return IconThemeData(
            size: 24,
            color: disabled
                ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
                : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return unselectedLabelStyle?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.38),
            );
          }
          return unselectedLabelStyle;
        }),
      ),
      child: child,
    );
  }
}

class _AppNavigationDestinationIcon extends StatelessWidget {
  const _AppNavigationDestinationIcon({
    required this.destination,
    required this.selected,
  });

  final AppNavigationDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    Widget icon = selected
        ? destination.selectedIcon ?? destination.icon
        : destination.icon;

    if (destination.showBadge) {
      icon = Badge(
        child: icon,
      );
    }

    if (destination.onLongPress == null) {
      return icon;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: destination.onLongPress,
      child: icon,
    );
  }
}

class _AppPrimaryNavigationButton extends StatelessWidget {
  const _AppPrimaryNavigationButton({
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

    return Semantics(
      key: const ValueKey('app-primary-navigation-button'),
      button: true,
      label: destination.label,
      child: Material(
        color: background,
        elevation: 8,
        shadowColor: scheme.primary.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(appNavigationBarPrimaryButtonBorderRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(appNavigationBarPrimaryButtonBorderRadius),
          onTap: onTap,
          onLongPress: destination.onLongPress,
          child: SizedBox(
            width: appNavigationBarPrimaryButtonSize,
            height: appNavigationBarPrimaryButtonSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  appNavigationBarPrimaryButtonBorderRadius,
                ),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: foreground,
                  size: 24,
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
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
