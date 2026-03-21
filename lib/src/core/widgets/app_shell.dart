import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.actions,
    this.bottom,
    this.contentPadding = const EdgeInsets.fromLTRB(4, 0, 6, 0),
    this.bottomPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.animateOnEnter = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final EdgeInsets contentPadding;
  final EdgeInsets bottomPadding;
  final bool animateOnEnter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: bottomPadding,
                child: bottom!,
              ),
            ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.shellStart(context),
        ),
        child: SafeArea(
          bottom: false,
          child: _buildAnimatedContent(theme),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(ThemeData theme) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: contentPadding,
            child: child,
          ),
        ),
      ],
    );

    if (!animateOnEnter) {
      return content;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.pageEnter,
      curve: AppMotion.pageIn,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: animatedChild,
        );
      },
      child: content,
    );
  }
}

class AppShellIconAction extends StatefulWidget {
  const AppShellIconAction({
    super.key,
    this.icon,
    this.iconWidget,
    this.showBorder = false,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final bool showBorder;
  final VoidCallback onTap;

  @override
  State<AppShellIconAction> createState() => _AppShellIconActionState();
}

class _AppShellIconActionState extends State<AppShellIconAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      duration: AppMotion.fast,
      curve: AppMotion.smooth,
      scale: _pressed ? 0.95 : 1,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: scheme.primary.withValues(alpha: 0.10),
          highlightColor: scheme.primary.withValues(alpha: 0.06),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.smooth,
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: widget.showBorder
                  ? Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    )
                  : null,
            ),
            child: Center(
              child: widget.iconWidget ??
                  Icon(
                    widget.icon,
                    color: scheme.onSecondaryContainer,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.semanticsLabel,
    this.semanticsValue,
    this.triggerMode = RefreshIndicatorTriggerMode.onEdge,
    this.allowRefreshOnShortContent = false,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final double displacement;
  final double edgeOffset;
  final ScrollNotificationPredicate notificationPredicate;
  final String? semanticsLabel;
  final String? semanticsValue;
  final RefreshIndicatorTriggerMode triggerMode;
  final bool allowRefreshOnShortContent;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  bool _showOverlay = false;
  int _statusToken = 0;
  bool _gestureActive = false;
  bool _gestureAllowsRefresh = true;
  bool _gestureDirectionResolved = false;
  static const double _edgeTolerance = 0.5;

  bool _isNearTop(ScrollMetrics metrics) {
    return metrics.extentBefore <= _edgeTolerance &&
        metrics.pixels <= metrics.minScrollExtent + _edgeTolerance;
  }

  bool _contentCanActuallyScroll(ScrollMetrics metrics) {
    return (metrics.maxScrollExtent - metrics.minScrollExtent) >
        _edgeTolerance;
  }

  bool _canRefreshFromMetrics(ScrollMetrics metrics) {
    return widget.allowRefreshOnShortContent || _contentCanActuallyScroll(metrics);
  }

  void _handleStatusChange(RefreshIndicatorStatus? status) {
    _statusToken++;
    final token = _statusToken;

    if (!mounted) {
      return;
    }

    setState(() {
      if (status != RefreshIndicatorStatus.done &&
          status != RefreshIndicatorStatus.canceled &&
          status != null) {
        _showOverlay = true;
      }
    });

    if (status == RefreshIndicatorStatus.done ||
        status == RefreshIndicatorStatus.canceled ||
        status == null) {
      Future<void>.delayed(AppMotion.fast, () {
        if (!mounted || token != _statusToken) {
          return;
        }
        setState(() {
          _showOverlay = false;
        });
      });
    }
  }

  bool _handleRefreshScrollNotification(ScrollNotification notification) {
    if (widget.triggerMode != RefreshIndicatorTriggerMode.onEdge) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      if (!_canRefreshFromMetrics(notification.metrics)) {
        _gestureActive = false;
        _gestureAllowsRefresh = false;
        _gestureDirectionResolved = false;
        return true;
      }
      _gestureActive = notification.dragDetails != null;
      _gestureAllowsRefresh = _isNearTop(notification.metrics);
      _gestureDirectionResolved = false;
      return false;
    }

    if (!_isNearTop(notification.metrics)) {
      _gestureAllowsRefresh = false;
      if (notification is ScrollEndNotification) {
        _gestureActive = false;
        _gestureAllowsRefresh = true;
        _gestureDirectionResolved = false;
      }
      return true;
    }

    if (!_gestureActive || !_gestureAllowsRefresh) {
      if (notification is ScrollEndNotification) {
        _gestureActive = false;
        _gestureAllowsRefresh = true;
        _gestureDirectionResolved = false;
      }
      return !_gestureAllowsRefresh;
    }

    if (!_gestureDirectionResolved &&
        (notification is ScrollUpdateNotification ||
            notification is OverscrollNotification)) {
      double? dragDelta;
      if (notification is ScrollUpdateNotification) {
        dragDelta =
            notification.dragDetails?.delta.dy ??
            (notification.scrollDelta == null
                ? null
                : -notification.scrollDelta!);
      } else if (notification is OverscrollNotification) {
        dragDelta =
            notification.dragDetails?.delta.dy ?? -notification.overscroll;
      }

      if (dragDelta != null) {
        if (dragDelta < 0.0) {
          _gestureAllowsRefresh = false;
          return true;
        }
        if (dragDelta > 0.0) {
          _gestureDirectionResolved = true;
        }
      }
    }

    if (notification is ScrollEndNotification) {
      _gestureActive = false;
      _gestureAllowsRefresh = true;
      _gestureDirectionResolved = false;
    }

    return false;
  }

  bool _refreshNotificationPredicate(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) {
      return false;
    }
    if (!_canRefreshFromMetrics(notification.metrics)) {
      return false;
    }
    if (notification.metrics.axisDirection != AxisDirection.down) {
      return false;
    }
    if (!_isNearTop(notification.metrics)) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      return notification.dragDetails != null;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: _handleStatusChange,
          notificationPredicate: _refreshNotificationPredicate,
          semanticsLabel: widget.semanticsLabel,
          semanticsValue: widget.semanticsValue,
          triggerMode: widget.triggerMode,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleRefreshScrollNotification,
            child: widget.child,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedSlide(
                  duration: AppMotion.fast,
                  curve: AppMotion.smooth,
                  offset: _showOverlay ? Offset.zero : const Offset(0, -0.15),
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    curve: AppMotion.smooth,
                    opacity: _showOverlay ? 1 : 0,
                    child: AnimatedScale(
                      duration: AppMotion.fast,
                      curve: AppMotion.smooth,
                      scale: _showOverlay ? 1 : 0.98,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Card.filled(
                          margin: EdgeInsets.zero,
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.96,
                          ),
                          clipBehavior: Clip.antiAlias,
                          shape: const StadiumBorder(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: scheme.primary,
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
        ),
      ],
    );
  }
}
