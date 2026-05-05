import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../native_back_button_bridge.dart';
import '../../native_dock_bridge.dart';
import '../display/shared_header_title.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

/// [AppShell] AppBar [bottom] va [AppRefreshIndicator] uchun bir xil chiziqli progress.
Widget _appShellStyleLinearProgress(
  ThemeData theme, {
  double? value,
}) {
  return LinearProgressIndicator(
    minHeight: 3,
    value: value,
    backgroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.14),
    color: theme.colorScheme.primary,
  );
}

/// Vertikal ro‘yxat pastki chekka yaqinlashganda dock ustidagi scrim uchun **0–1**.
///
/// [AppShell.bottomDockFadeStrength] bilan ishlatiladi; qisqa ro‘yxatda (`maxScrollExtent`
/// juda kichik) fade yo‘q — kontent baribir pastga «tushmaydi».
double dockFadeStrengthFromScrollMetrics(
  ScrollMetrics m, {
  double bandPx = 112,
  double minScrollExtentForFade = 28,
}) {
  if (m.axis != Axis.vertical) return 0;
  if (!m.hasContentDimensions) return 0;
  final maxExtent = m.maxScrollExtent;
  if (maxExtent < minScrollExtentForFade) return 0;
  final remaining = (maxExtent - m.pixels).clamp(0.0, bandPx);
  return 1.0 - remaining / bandPx;
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.actions,
    this.drawer,
    this.bottom,
    this.bottomDockFadeStrength,
    this.contentPadding = const EdgeInsets.fromLTRB(4, 0, 6, 0),
    this.bottomPadding = EdgeInsets.zero,
    this.animateOnEnter = true,
    this.preferNativeTitle = false,
    this.nativeTopBar = false,
    this.nativeTitleTextStyle,
    this.backgroundColor,
    this.appBarBottomLoading = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottom;

  /// Pastki dock ustidagi yumshoq scrim: **0** yo‘q, **1** to‘liq. `null` — scrim chizilmaydi.
  final ValueListenable<double>? bottomDockFadeStrength;
  final EdgeInsets contentPadding;
  final EdgeInsets bottomPadding;
  final bool animateOnEnter;
  final bool preferNativeTitle;
  final bool nativeTopBar;
  final TextStyle? nativeTitleTextStyle;
  final Color? backgroundColor;

  /// [nativeTopBar] bo‘lsa, AppBar ostida indeterminate chiziqli yuklanish (Google uslubi).
  final bool appBarBottomLoading;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  AnimationController? _expressiveDrawerController;
  CurvedAnimation? _expressiveDrawerCurve;
  LocalHistoryEntry? _expressiveDrawerHistory;

  @override
  void initState() {
    super.initState();
    if (widget.drawer != null) {
      _expressiveDrawerController = AnimationController(
        vsync: this,
        duration: AppMotion.expressiveDrawerDuration,
      );
      _expressiveDrawerCurve = CurvedAnimation(
        parent: _expressiveDrawerController!,
        curve: AppMotion.expressiveSpatialDefault,
        reverseCurve: AppMotion.expressiveSpatialDefault.flipped,
      );
      _expressiveDrawerController!
          .addStatusListener(_expressiveDrawerStatusChanged);
    }
  }

  @override
  void dispose() {
    _expressiveDrawerHistory?.remove();
    _expressiveDrawerCurve?.dispose();
    _expressiveDrawerController?.dispose();
    super.dispose();
  }

  void _expressiveDrawerStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _ensureExpressiveDrawerHistory();
    } else if (status == AnimationStatus.reverse) {
      _expressiveDrawerHistory?.remove();
      _expressiveDrawerHistory = null;
    }
  }

  void _ensureExpressiveDrawerHistory() {
    if (_expressiveDrawerHistory != null) {
      return;
    }
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null) {
      _expressiveDrawerHistory = LocalHistoryEntry(
        onRemove: _handleExpressiveDrawerHistoryRemoved,
        impliesAppBarDismissal: false,
      );
      route.addLocalHistoryEntry(_expressiveDrawerHistory!);
    }
  }

  void _handleExpressiveDrawerHistoryRemoved() {
    _expressiveDrawerHistory = null;
    _expressiveCloseDrawer();
  }

  void _expressiveCloseDrawer() {
    final c = _expressiveDrawerController;
    if (c == null || c.isDismissed) {
      return;
    }
    c.reverse();
  }

  void _openExpressiveDrawer() {
    _expressiveDrawerController?.forward();
  }

  Widget? _nativeAppBarLeading(bool shouldHideLeading) {
    if (shouldHideLeading) {
      return null;
    }
    if (widget.leading != null) {
      return widget.leading;
    }
    if (widget.drawer != null) {
      return IconButton(
        icon: const Icon(Icons.menu),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        onPressed: _openExpressiveDrawer,
      );
    }
    return null;
  }

  /// [nativeTopBar] rejimida ixtiyoriy [AppShell.subtitle] — ikkinchi qator sifatida.
  Widget _nativeAppBarTitle(ThemeData theme) {
    final titleStyle =
        widget.nativeTitleTextStyle ?? theme.textTheme.titleLarge;
    final subtitle = widget.subtitle.trim();
    if (subtitle.isEmpty) {
      return Text(widget.title, style: titleStyle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: titleStyle),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color shellBackground =
        widget.backgroundColor ?? AppTheme.shellStart(context);
    final useNativeTitle =
        NativeBackButtonBridge.useNativeNavigationTitleWhenPossible(
      context,
      widget.title,
      allowWithoutBackButton: widget.preferNativeTitle,
    );
    final shouldHideLeading = widget.leading != null &&
        NativeBackButtonBridge.shouldUseNativeBackButton(context);
    final route = ModalRoute.of(context);
    final inferredBackLeading = !shouldHideLeading &&
        widget.leading == null &&
        widget.drawer == null &&
        (route?.canPop ?? false) &&
        !(route?.isFirst ?? true);
    final compactTitleNearLeading = !shouldHideLeading &&
        (widget.drawer != null ||
            widget.leading != null ||
            inferredBackLeading);
    if (widget.bottom == null) {
      NativeDockBridge.instance.clearFromBuild();
    }

    final Widget scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: widget.nativeTopBar
          ? AppBar(
              title: _nativeAppBarTitle(theme),
              leading: _nativeAppBarLeading(shouldHideLeading),
              automaticallyImplyLeading: shouldHideLeading
                  ? false
                  : widget.leading == null && widget.drawer == null,
              actions: widget.actions,
              backgroundColor: widget.backgroundColor ??
                  theme.appBarTheme.backgroundColor ??
                  theme.colorScheme.surfaceContainer,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 50,
              titleSpacing: compactTitleNearLeading ? 0 : 20,
              centerTitle: false,
              bottom: widget.appBarBottomLoading
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(3),
                      child: _appShellStyleLinearProgress(theme),
                    )
                  : null,
            )
          : null,
      bottomNavigationBar: widget.bottom == null
          ? null
          : Padding(
              padding: widget.bottomPadding,
              child: widget.bottom!,
            ),
      body: SafeArea(
        bottom: false,
        child: _buildAnimatedContent(
          context,
          theme,
          shouldHideLeading,
          useNativeTitle,
          showHeader: !widget.nativeTopBar,
        ),
      ),
    );

    if (widget.drawer != null &&
        _expressiveDrawerController != null &&
        _expressiveDrawerCurve != null) {
      final controller = _expressiveDrawerController!;
      final curved = _expressiveDrawerCurve!;
      return DecoratedBox(
        decoration: BoxDecoration(color: shellBackground),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            // Scrim faqat chiziqli [0,1] progress bilan — Expressive cubic overshoot
            // (curved.value > 1) qora fonni bir kadrlik «qoraytirish» flashini berardi.
            final double linearT = controller.value.clamp(0.0, 1.0);
            final bool drawerBlocking =
                linearT > 0.001 || controller.isAnimating;
            return PopScope(
              canPop: !drawerBlocking,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && drawerBlocking) {
                  _expressiveCloseDrawer();
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  scaffold,
                  if (drawerBlocking) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _expressiveCloseDrawer,
                        child: Semantics(
                          label: MaterialLocalizations.of(context)
                              .modalBarrierDismissLabel,
                          child: ColoredBox(
                            color:
                                Colors.black.withValues(alpha: 0.54 * linearT),
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      ).animate(curved),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: widget.drawer!,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: shellBackground),
      child: scaffold,
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
                if (!shouldHideLeading && widget.leading != null) ...[
                  HeaderLeadingTransition(
                    child: widget.leading!,
                  ),
                  const SizedBox(width: 14),
                ],
                if (!useNativeTitle)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SharedHeaderTitle(
                          title: widget.title,
                        ),
                        if (widget.subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                if (useNativeTitle) const Spacer(),
                if (widget.actions != null) ...[
                  const SizedBox(width: 12),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.actions!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: widget.contentPadding,
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                if (widget.bottom != null &&
                    widget.bottomDockFadeStrength != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: widget.bottomDockFadeStrength!,
                        builder: (context, _) {
                          final fade = widget.bottomDockFadeStrength!.value
                              .clamp(0.0, 1.0);
                          if (fade <= 0.002) {
                            return const SizedBox.shrink();
                          }
                          final Color chrome =
                              theme.navigationBarTheme.backgroundColor ??
                                  theme.colorScheme.surfaceContainer;
                          // Oldin ~0.92 taga — endi faqat scroll yaqinida va pastda yengil.
                          final peakAlpha = 0.26 * fade;
                          return SizedBox(
                            height:
                                72 + MediaQuery.viewPaddingOf(context).bottom,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.5, 1.0],
                                  colors: [
                                    Colors.transparent,
                                    chrome.withValues(alpha: peakAlpha * 0.35),
                                    chrome.withValues(alpha: peakAlpha),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.animateOnEnter) {
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
    final theme = Theme.of(context);
    final progress = (_pullExtent / _triggerDistance).clamp(0.0, 1.0);
    final visible = _refreshing || _pullExtent > 0.0;
    final contentTranslateY = _refreshing
        ? 0.0
        : _pullExtent.clamp(0.0, widget.displacement + 12.0).toDouble();
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
                top: widget.edgeOffset,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: visible ? 1 : 0,
                    child: _appShellStyleLinearProgress(
                      theme,
                      value: _refreshing ? null : progress,
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
