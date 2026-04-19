import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../native_back_button_bridge.dart';
import '../native_dock_bridge.dart';
import 'app_loading_indicator.dart';
import 'shared_header_title.dart';
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
    this.bottomPadding = EdgeInsets.zero,
    this.animateOnEnter = true,
    this.preferNativeTitle = false,
    this.nativeTopBar = false,
    this.backgroundColor,
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
  final bool preferNativeTitle;
  final bool nativeTopBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useNativeTitle =
        NativeBackButtonBridge.useNativeNavigationTitleWhenPossible(
      context,
      title,
      allowWithoutBackButton: preferNativeTitle,
    );
    final shouldHideLeading = leading != null &&
        NativeBackButtonBridge.shouldUseNativeBackButton(context);
    final preserveNativeDock = NativeDockBridge.isSupportedPlatform &&
        NativeDockBridge.instance.supportsSystemDock;
    if (bottom == null && !preserveNativeDock) {
      NativeDockBridge.instance.clearFromBuild();
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: nativeTopBar
          ? AppBar(
              title: Text(title),
              leading: shouldHideLeading ? null : leading,
              automaticallyImplyLeading:
                  shouldHideLeading ? false : leading == null,
              actions: actions,
              backgroundColor:
                  backgroundColor ?? theme.colorScheme.surfaceContainerLow,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 60,
              titleSpacing: 20,
              centerTitle: false,
            )
          : null,
      bottomNavigationBar: bottom == null
          ? null
          : Padding(
              padding: bottomPadding,
              child: bottom!,
            ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.shellStart(context),
        ),
        child: SafeArea(
          bottom: false,
          child: _buildAnimatedContent(
            context,
            theme,
            shouldHideLeading,
            useNativeTitle,
            showHeader: !nativeTopBar,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(BuildContext context, ThemeData theme,
      bool shouldHideLeading, bool useNativeTitle,
      {required bool showHeader}) {
    final content = Column(
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!shouldHideLeading && leading != null) ...[
                  HeaderLeadingTransition(
                    child: leading!,
                  ),
                  const SizedBox(width: 14),
                ],
                if (!useNativeTitle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SharedHeaderTitle(
                          title: title,
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
                if (useNativeTitle) const Spacer(),
                if (actions != null) ...[
                  const SizedBox(width: 12),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: actions!,
                    ),
                  ),
                ],
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
            height: AppTheme.headerActionSize,
            width: AppTheme.headerActionSize,
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
                    size: AppTheme.headerActionIconSize,
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
  static const Duration _releaseSettleDuration = Duration(milliseconds: 380);
  final ScrollController _scrollController = ScrollController();
  double _pullExtent = 0.0;
  bool _refreshing = false;
  bool _userPulling = false;
  bool _refreshArmed = false;

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
    return (metrics.maxScrollExtent - metrics.minScrollExtent) > _edgeTolerance;
  }

  bool _canRefreshFromMetrics(ScrollMetrics metrics) {
    return widget.allowRefreshOnShortContent ||
        _contentCanActuallyScroll(metrics);
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
      _userPulling = false;
      _refreshArmed = false;
      _pullExtent = 0.0;
    });
    _settleTopEdge(forceJump: true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _userPulling = false;
          _refreshArmed = false;
          _pullExtent = 0.0;
        });
        _settleTopEdge();
        _scheduleHardSettleBursts();
      }
    }
  }

  void _scheduleHardSettleBursts() {
    for (final delayMs in <int>[16, 32, 64, 96, 140, 220]) {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted) {
          return;
        }
        _settleTopEdge(forceJump: true);
      });
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

  void _setUserPulling(bool nextValue) {
    if (_userPulling == nextValue) {
      return;
    }
    setState(() {
      _userPulling = nextValue;
    });
  }

  void _setRefreshArmed(bool nextValue) {
    if (_refreshArmed == nextValue) {
      return;
    }
    setState(() {
      _refreshArmed = nextValue;
    });
  }

  void _settleTopEdge({bool forceJump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = position.minScrollExtent;
      final topOverscrollDistance = target - position.pixels;
      if (topOverscrollDistance <= _edgeTolerance) {
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
      if (position.pixels < target - _edgeTolerance) {
        position.jumpTo(target);
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_refreshing) {
      return false;
    }

    if (notification is ScrollEndNotification && _pullExtent > 0) {
      _setUserPulling(false);
      if (_refreshArmed) {
        _startRefresh();
      } else {
        _setPullExtent(0.0);
        if (_scrollController.hasClients) {
          final position = _scrollController.position;
          if (position.pixels < position.minScrollExtent - _edgeTolerance) {
            _scheduleHardSettleBursts();
          }
        }
      }
      return false;
    }

    if (!_matchesRefreshContext(notification)) {
      return false;
    }

    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        _isNearTop(notification.metrics) &&
        notification.overscroll < 0) {
      _setUserPulling(true);
      final nextPull = (_pullExtent + (-notification.overscroll))
          .clamp(0.0, _maxPullDistance);
      _setPullExtent(nextPull);
      _setRefreshArmed(nextPull >= _triggerDistance);
      return false;
    }

    if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        _pullExtent > 0) {
      _setUserPulling(true);
      final delta = notification.scrollDelta ?? 0.0;
      late final double nextPull;
      if (delta > 0) {
        nextPull = (_pullExtent - delta).clamp(0.0, _maxPullDistance);
      } else if (_isNearTop(notification.metrics) && delta < 0) {
        nextPull = (_pullExtent + (-delta)).clamp(0.0, _maxPullDistance);
      } else {
        nextPull = _pullExtent;
      }
      _setPullExtent(nextPull);
      _setRefreshArmed(nextPull >= _triggerDistance);
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = (_pullExtent / _triggerDistance).clamp(0.0, 1.0);
    final visible = _refreshing || _pullExtent > 0.0;
    final contentTranslateY = _refreshing
        ? 0.0
        : _pullExtent.clamp(0.0, widget.displacement + 12.0).toDouble();
    final translateY = _refreshing
        ? widget.edgeOffset + 12.0
        : widget.edgeOffset + (widget.displacement * progress) - 28.0;
    final motionDuration = _userPulling
        ? Duration.zero
        : _refreshing
            ? AppMotion.fast
            : _releaseSettleDuration;
    final motionCurve = _refreshing
        ? AppMotion.standardDecelerate
        : AppMotion.emphasizedDecelerate;

    return PrimaryScrollController(
      controller: _scrollController,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: motionDuration,
              curve: motionCurve,
              transform: Matrix4.translationValues(0, contentTranslateY, 0),
              transformAlignment: Alignment.topCenter,
              child: widget.child,
            ),
            if (visible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedContainer(
                    duration: motionDuration,
                    curve: motionCurve,
                    transform: Matrix4.translationValues(0, translateY, 0),
                    transformAlignment: Alignment.topCenter,
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
                          child: AnimatedScale(
                            duration: motionDuration,
                            curve: motionCurve,
                            scale: _refreshing ? 1 : (0.72 + (0.28 * progress)),
                            child: AnimatedOpacity(
                              duration: AppMotion.fast,
                              opacity:
                                  _refreshing ? 1 : (0.35 + (0.65 * progress)),
                              child: const AppLoadingIndicator(
                                size: 20,
                                glyphSize: 20,
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
        ),
      ),
    );
  }
}
