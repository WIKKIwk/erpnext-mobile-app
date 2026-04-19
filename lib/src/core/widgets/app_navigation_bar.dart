import 'package:flutter/material.dart';

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
    this.height = 80,
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
    const double primaryButtonSize = 84.0;
    const double primaryButtonGap = 44.0;

    if (destinations.isEmpty) {
      return SizedBox(height: height);
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
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
    final Color selectedLabelColor = barSelectionVisible
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    final Color unselectedLabelColor = scheme.onSurfaceVariant;
    final double hostHeight =
        hasPrimary ? height + primaryButtonSize + primaryButtonGap : height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return SizedBox(
          width: availableWidth,
          height: hostHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: availableWidth,
                    child: NavigationBarTheme(
                      data: NavigationBarThemeData(
                        height: height,
                        backgroundColor: scheme.surfaceContainerLow,
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        indicatorColor: !barSelectionVisible
                            ? Colors.transparent
                            : scheme.secondaryContainer,
                        indicatorShape: const StadiumBorder(),
                        labelTextStyle:
                            WidgetStateProperty.resolveWith<TextStyle?>(
                          (states) {
                            final bool selected = barSelectionVisible &&
                                states.contains(
                                  WidgetState.selected,
                                );
                            return theme.textTheme.labelSmall?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selected
                                  ? selectedLabelColor
                                  : unselectedLabelColor,
                              letterSpacing: 0.1,
                            );
                          },
                        ),
                        iconTheme:
                            WidgetStateProperty.resolveWith<IconThemeData?>(
                          (states) {
                            final bool selected = barSelectionVisible &&
                                states.contains(
                                  WidgetState.selected,
                                );
                            return IconThemeData(
                              color: selected
                                  ? selectedLabelColor
                                  : unselectedLabelColor,
                              size: 24,
                            );
                          },
                        ),
                      ),
                      child: NavigationBar(
                        height: height,
                        selectedIndex: barSelectedIndex,
                        onDestinationSelected: (index) {
                          final destination = barDestinations[index];
                          final originalIndex = destinations.indexOf(destination);
                          onDestinationSelected(originalIndex);
                        },
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        backgroundColor: scheme.surfaceContainerLow,
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        indicatorColor: !barSelectionVisible
                            ? Colors.transparent
                            : scheme.secondaryContainer,
                        indicatorShape: const StadiumBorder(),
                        destinations: List<NavigationDestination>.generate(
                          barDestinations.length,
                          (index) {
                            final destination = barDestinations[index];
                            return NavigationDestination(
                              label: destination.label,
                              icon: _AppNavigationDestinationIcon(
                                destination: destination,
                                selected: false,
                                selectionVisible: selectionVisible,
                              ),
                              selectedIcon: _AppNavigationDestinationIcon(
                                destination: destination,
                                selected: true,
                                selectionVisible: selectionVisible,
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
                  bottom: height + primaryButtonGap,
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
    );
  }
}

class _AppNavigationDestinationIcon extends StatelessWidget {
  const _AppNavigationDestinationIcon({
    required this.destination,
    required this.selected,
    required this.selectionVisible,
  });

  final AppNavigationDestination destination;
  final bool selected;
  final bool selectionVisible;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool highlighted = selectionVisible && selected;
    final Widget content = IconTheme(
      data: IconThemeData(
        color:
            highlighted ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
        size: 24,
      ),
      child: highlighted
          ? destination.selectedIcon ?? destination.icon
          : destination.icon,
    );
    final Widget icon = destination.showBadge
        ? Badge(
            smallSize: 8,
            alignment: Alignment.topRight,
            backgroundColor: scheme.error,
            child: content,
          )
        : content;

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
        color: Colors.transparent,
        elevation: 8,
        shadowColor: scheme.primary.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          onLongPress: destination.onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: IconTheme(
              data: IconThemeData(
                color: foreground,
                size: 28,
              ),
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}
