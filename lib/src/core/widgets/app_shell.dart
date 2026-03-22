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
  static const double _triggerDistance = 72.0;
  static const double _maxPullDistance = 108.0;
  final ScrollController _scrollController = ScrollController();
  double _pullExtent = 0.0;
  bool _refreshing = false;

  static const double _edgeTolerance = 0.5;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  bool _matchesRefreshContext(ScrollNotification notification) {
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
    return true;
  }

  Future<void> _startRefresh() async {
    if (_refreshing) {
      return;
    }
    setState(() {
      _refreshing = true;
      _pullExtent = 0.0;
    });
    _settleTopEdge(forceJump: true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _pullExtent = 0.0;
        });
        _settleTopEdge();
        Future<void>.delayed(AppMotion.medium, () {
          if (!mounted) {
            return;
          }
          _settleTopEdge(forceJump: true);
        });
      }
    }
  }

  void _setPullExtent(double nextExtent) {
    final clamped = nextExtent.clamp(0.0, _maxPullDistance);
    if ((clamped - _pullExtent).abs() <= _edgeTolerance) {
      return;
    }
    setState(() {
      _pullExtent = clamped;
    });
  }

  void _settleTopEdge({bool forceJump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.minScrollExtent;
      final distance = position.pixels - target;
      if (distance.abs() <= _edgeTolerance) {
        return;
      }
      if (forceJump) {
        position.jumpTo(target);
        return;
      }
      try {
        await position.animateTo(
          target,
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
        );
      } catch (_) {}
      if (!mounted || !position.hasPixels) {
        return;
      }
      if ((position.pixels - target).abs() > _edgeTolerance) {
        position.jumpTo(target);
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_matchesRefreshContext(notification)) {
      return false;
    }

    if (_refreshing) {
      return false;
    }

    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        _isNearTop(notification.metrics) &&
        notification.overscroll < 0) {
      _setPullExtent(_pullExtent + (-notification.overscroll));
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        _pullExtent > 0) {
      final delta = notification.scrollDelta ?? 0.0;
      if (delta > 0) {
        _setPullExtent(_pullExtent - delta);
      } else if (_isNearTop(notification.metrics) && delta < 0) {
        _setPullExtent(_pullExtent + (-delta));
      }
      return false;
    }

    if (notification is ScrollEndNotification && _pullExtent > 0) {
      if (_pullExtent >= _triggerDistance) {
        _startRefresh();
      } else {
        _setPullExtent(0.0);
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (_pullExtent / _triggerDistance).clamp(0.0, 1.0);
    final visible = _refreshing || _pullExtent > 0.0;
    final translateY = _refreshing
        ? widget.edgeOffset + 12.0
        : widget.edgeOffset + (widget.displacement * progress) - 28.0;

    return PrimaryScrollController(
      controller: _scrollController,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            widget.child,
            if (visible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedOpacity(
                        duration: AppMotion.fast,
                        opacity: visible ? 1 : 0,
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            value: _refreshing ? null : progress,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
