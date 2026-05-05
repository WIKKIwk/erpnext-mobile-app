import 'dart:math' as math;
import 'dart:async';
import 'dart:ui' as ui;

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import 'package:androidx_graphics_shapes/material_shapes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

final _ShapeProfile _ambientOvalProfile = _ShapeProfile.fromPath(
  MaterialShapes.oval.toPath(),
);
final _ShapeProfile _ambientCookieProfile = _ShapeProfile.fromPath(
  MaterialShapes.cookie12Sided.toPath(),
);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
    this.useSharedBackground = false,
  });

  final Future<void> Function() onGetStarted;
  final bool useSharedBackground;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const List<Locale> _headlineLocales = <Locale>[
    Locale('uz'),
    Locale('en'),
    Locale('ru'),
  ];

  late final AnimationController _headlineController =
      AnimationController(vsync: this)
        ..addStatusListener(_handleHeadlineStatus);

  Timer? _headlineTimer;
  int _headlineIndex = 0;
  String _headlinePhase = 'idle';
  bool _lockToSelectedLocale = false;

  @override
  void initState() {
    super.initState();
    if (LocaleController.instance.hasExplicitSelection) {
      _lockToSelectedLocale = true;
      _headlineIndex = _headlineLocales.indexWhere(
        (item) =>
            item.languageCode == LocaleController.instance.locale.languageCode,
      );
      if (_headlineIndex < 0) {
        _headlineIndex = 0;
      }
    }
    _scheduleHeadlineCycle();
  }

  @override
  void dispose() {
    _headlineTimer?.cancel();
    _headlineController.dispose();
    super.dispose();
  }

  void _scheduleHeadlineCycle() {
    if (_lockToSelectedLocale) {
      _headlineTimer?.cancel();
      return;
    }
    _headlineTimer?.cancel();
    _headlineTimer = Timer(const Duration(seconds: 5), _startHeadlineExit);
  }

  void _startHeadlineExit() {
    if (!mounted || _headlinePhase != 'idle' || _lockToSelectedLocale) {
      return;
    }
    setState(() {
      _headlinePhase = 'exiting';
    });
    _headlineController.duration = const Duration(milliseconds: 300);
    _headlineController.forward(from: 0);
  }

  void _handleHeadlineStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    if (_headlinePhase == 'exiting') {
      _headlineController.stop();
      _headlineController.value = 0;
      setState(() {
        _headlineIndex = (_headlineIndex + 1) % _headlineLocales.length;
        _headlinePhase = 'entering';
      });
      Future<void>.delayed(const Duration(milliseconds: 70), () {
        if (!mounted || _headlinePhase != 'entering') {
          return;
        }
        _headlineController.duration = const Duration(milliseconds: 420);
        _headlineController.forward(from: 0);
      });
      return;
    }

    if (_headlinePhase == 'entering') {
      _headlineController.stop();
      _headlineController.value = 0;
      setState(() {
        _headlinePhase = 'idle';
      });
      if (!_lockToSelectedLocale) {
        _scheduleHeadlineCycle();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final Locale displayLocale = _lockToSelectedLocale
        ? LocaleController.instance.locale
        : _headlineLocales[_headlineIndex];
    final AppLocalizations displayL10n = AppLocalizations(displayLocale);
    final double headlineFontSize = 46;
    final double headlineLineHeight = 1.02 * headlineFontSize;
    final double headlineHeight = headlineLineHeight * 3.15;
    final TextStyle? primaryButtonLabelStyle =
        theme.textTheme.labelMedium?.copyWith(
      color: scheme.onPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 18,
      letterSpacing: -0.2,
    );
    final double primaryButtonWidth = _measurePrimaryButtonWidth(
      context,
      displayL10n.getStarted,
      primaryButtonLabelStyle,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([
        LocaleController.instance,
        ThemeController.instance,
        _headlineController,
      ]),
      builder: (context, _) {
        final currentLocale = LocaleController.instance.locale;
        final currentVariant = ThemeController.instance.variant;
        final Color authBackgroundColor = ThemeController.instance.isDark
            ? const Color(0xFF000000)
            : scheme.surfaceContainerLow;

        return Scaffold(
          backgroundColor: widget.useSharedBackground
              ? Colors.transparent
              : authBackgroundColor,
          body: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.useSharedBackground
                  ? Colors.transparent
                  : authBackgroundColor,
            ),
            child: Stack(
              children: [
                if (!widget.useSharedBackground)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AuthAmbientOutlineBackground(
                        outlineColor: scheme.outlineVariant,
                        accentColor: scheme.primary,
                        backgroundColor: authBackgroundColor,
                        isDarkBackground: ThemeController.instance.isDark,
                      ),
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      mediaQuery.size.height >= 760 ? 18 : 8,
                      24,
                      mediaQuery.padding.bottom + 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 180),
                        const Spacer(),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 40),
                          offset: const Offset(0, 16),
                          child: SizedBox(
                            height: headlineHeight,
                            child: _buildAnimatedText(
                              displayL10n.welcomeToAccord,
                              style: GoogleFonts.manrope(
                                fontSize: headlineFontSize,
                                height: 1.02,
                                letterSpacing: -1.7,
                                fontWeight: FontWeight.w400,
                                color: scheme.onSurface,
                              ),
                              maxLines: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 110),
                          offset: const Offset(0, 14),
                          child: _WelcomeSelectionRow(
                            icon: Icons.language_rounded,
                            label: _buildSoftAnimatedText(
                              displayL10n.languageTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 21,
                                color: scheme.onSurface,
                              ),
                            ),
                            value: _buildSoftAnimatedText(
                              LocaleController.instance.hasExplicitSelection
                                  ? _localeLabel(displayL10n, currentLocale)
                                  : displayL10n.languageUnselected,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _pickLocale(context, currentLocale),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 150),
                          offset: const Offset(0, 14),
                          child: _WelcomeSelectionRow(
                            icon: Icons.palette_outlined,
                            label: _buildSoftAnimatedText(
                              displayL10n.themeTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 21,
                                color: scheme.onSurface,
                              ),
                            ),
                            value: _buildSoftAnimatedText(
                              _themeLabel(displayL10n, currentVariant),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _pickTheme(context, currentVariant),
                          ),
                        ),
                        const SizedBox(height: 58),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 190),
                          offset: const Offset(0, 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeInOutCubicEmphasized,
                              width: primaryButtonWidth,
                              child: SizedBox(
                                height: 54,
                                child: FilledButton(
                                  onPressed: widget.onGetStarted,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 15,
                                    ),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  child: _buildSoftAnimatedText(
                                    displayL10n.getStarted,
                                    style: primaryButtonLabelStyle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText(
    String text, {
    required TextStyle? style,
    int maxLines = 1,
    TextAlign? textAlign,
    TextOverflow? overflow,
  }) {
    return _HeadlineMotionText(
      phase: _headlinePhase,
      progress: _headlineController.value,
      child: Text(
        text,
        key: ValueKey<String>('$_headlineIndex-$_headlinePhase-$text'),
        maxLines: maxLines,
        softWrap: maxLines != 1,
        overflow: overflow,
        textAlign: textAlign,
        style: style,
      ),
    );
  }

  Widget _buildSoftAnimatedText(
    String text, {
    required TextStyle? style,
    int maxLines = 1,
    TextAlign? textAlign,
    TextOverflow? overflow,
  }) {
    return _SoftBlurMotionText(
      phase: _headlinePhase,
      progress: _headlineController.value,
      child: Text(
        text,
        key: ValueKey<String>('soft-$_headlineIndex-$_headlinePhase-$text'),
        maxLines: maxLines,
        softWrap: maxLines != 1,
        overflow: overflow,
        textAlign: textAlign,
        style: style,
      ),
    );
  }

  double _measurePrimaryButtonWidth(
    BuildContext context,
    String text,
    TextStyle? style,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();

    return math.max(140.0, painter.width + 56);
  }

  Future<void> _pickLocale(BuildContext context, Locale currentLocale) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<Locale>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectionSheet(
          title: l10n.languageTitle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectionOption(
                title: l10n.uzbek,
                active: LocaleController.instance.hasExplicitSelection &&
                    currentLocale.languageCode == 'uz',
                onTap: () => Navigator.of(context).pop(const Locale('uz')),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.english,
                active: LocaleController.instance.hasExplicitSelection &&
                    currentLocale.languageCode == 'en',
                onTap: () => Navigator.of(context).pop(const Locale('en')),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.russian,
                active: LocaleController.instance.hasExplicitSelection &&
                    currentLocale.languageCode == 'ru',
                onTap: () => Navigator.of(context).pop(const Locale('ru')),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) {
      return;
    }
    _lockHeadlineToLocale(picked);
    await LocaleController.instance.setLocale(picked);
  }

  void _lockHeadlineToLocale(Locale locale) {
    _headlineTimer?.cancel();
    _headlineController.stop();
    _headlineController.value = 0;
    setState(() {
      _lockToSelectedLocale = true;
      _headlinePhase = 'idle';
      _headlineIndex = _headlineLocales.indexWhere(
        (item) => item.languageCode == locale.languageCode,
      );
      if (_headlineIndex < 0) {
        _headlineIndex = 0;
      }
    });
  }

  Future<void> _pickTheme(
    BuildContext context,
    AppThemeVariant currentVariant,
  ) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<AppThemeVariant>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SelectionSheet(
          title: l10n.themeTitle,
          trailing: const _ThemeModeToggleButton(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeSelectionOption(
                title: l10n.themeClassicLabel,
                swatches: _themeSwatches(AppThemeVariant.classic),
                active: currentVariant == AppThemeVariant.classic,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.classic),
              ),
              const SizedBox(height: 10),
              _ThemeSelectionOption(
                title: l10n.themeEarthLabel,
                swatches: _themeSwatches(AppThemeVariant.earthy),
                active: currentVariant == AppThemeVariant.earthy,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.earthy),
              ),
              const SizedBox(height: 10),
              _ThemeSelectionOption(
                title: l10n.themeBlushLabel,
                swatches: _themeSwatches(AppThemeVariant.blush),
                active: currentVariant == AppThemeVariant.blush,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.blush),
              ),
              const SizedBox(height: 10),
              _ThemeSelectionOption(
                title: l10n.themeMossLabel,
                swatches: _themeSwatches(AppThemeVariant.moss),
                active: currentVariant == AppThemeVariant.moss,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.moss),
              ),
              const SizedBox(height: 10),
              _ThemeSelectionOption(
                title: l10n.themeLavenderLabel,
                swatches: _themeSwatches(AppThemeVariant.lavender),
                active: currentVariant == AppThemeVariant.lavender,
                onTap: () =>
                    Navigator.of(context).pop(AppThemeVariant.lavender),
              ),
              const SizedBox(height: 10),
              _ThemeSelectionOption(
                title: l10n.themeSlateLabel,
                swatches: _themeSwatches(AppThemeVariant.slate),
                active: currentVariant == AppThemeVariant.slate,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.slate),
              ),
              const SizedBox(height: 10),
              _ThemeSelectionOption(
                title: l10n.themeOceanLabel,
                swatches: _themeSwatches(AppThemeVariant.ocean),
                active: currentVariant == AppThemeVariant.ocean,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.ocean),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null) {
      return;
    }
    await ThemeController.instance.setVariant(picked);
  }

  String _localeLabel(AppLocalizations l10n, Locale locale) {
    return locale.languageCode == 'uz'
        ? l10n.uzbek
        : locale.languageCode == 'ru'
            ? l10n.russian
            : l10n.english;
  }

  String _themeLabel(AppLocalizations l10n, AppThemeVariant variant) {
    return switch (variant) {
      AppThemeVariant.classic => l10n.themeClassicLabel,
      AppThemeVariant.earthy => l10n.themeEarthLabel,
      AppThemeVariant.blush => l10n.themeBlushLabel,
      AppThemeVariant.moss => l10n.themeMossLabel,
      AppThemeVariant.lavender => l10n.themeLavenderLabel,
      AppThemeVariant.slate => l10n.themeSlateLabel,
      AppThemeVariant.ocean => l10n.themeOceanLabel,
    };
  }
}

class _HeadlineMotionText extends StatelessWidget {
  const _HeadlineMotionText({
    required this.phase,
    required this.progress,
    required this.child,
  });

  final String phase;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = Curves.easeOutCubic.transform(progress);
    final bool isExiting = phase == 'exiting';
    final bool isEntering = phase == 'entering';
    final double opacity = phase == 'idle'
        ? 1
        : isExiting
            ? 1 - t
            : t;
    final double dx = isExiting
        ? 24 * t
        : isEntering
            ? -24 * (1 - t)
            : 0;
    final double sigma = phase == 'idle'
        ? 0.01
        : isExiting
            ? 2.8 * t
            : 2.8 * (1 - t);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma * 0.2,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SoftBlurMotionText extends StatelessWidget {
  const _SoftBlurMotionText({
    required this.phase,
    required this.progress,
    required this.child,
  });

  final String phase;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double t = Curves.easeOutCubic.transform(progress);
    final bool isExiting = phase == 'exiting';
    final double opacity = phase == 'idle'
        ? 1
        : isExiting
            ? 1 - t
            : t;
    final double sigma = phase == 'idle'
        ? 0.01
        : isExiting
            ? 3.2 * t
            : 3.2 * (1 - t);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma * 0.22,
        ),
        child: child,
      ),
    );
  }
}

class AuthAmbientOutlineBackground extends StatefulWidget {
  const AuthAmbientOutlineBackground({
    super.key,
    required this.outlineColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.isDarkBackground,
  });

  final Color outlineColor;
  final Color accentColor;
  final Color backgroundColor;
  final bool isDarkBackground;

  @override
  State<AuthAmbientOutlineBackground> createState() =>
      _AmbientOutlineBackgroundState();
}

class _AmbientOutlineBackgroundState extends State<AuthAmbientOutlineBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_handleTick);

  Size _sceneSize = Size.zero;
  Duration? _lastTick;
  double _phase = 0;
  double _impactEnergy = 0;
  double _ovalBounceLift = 0;
  double _cookieBounceLift = 0;
  bool _seeded = false;
  late _AmbientBody _oval;
  late _AmbientBody _cookie;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  void _handleTick(Duration elapsed) {
    final Duration? lastTick = _lastTick;
    _lastTick = elapsed;
    if (!_seeded || _sceneSize.isEmpty || !mounted) {
      return;
    }

    final int elapsedMicros =
        lastTick == null ? 16667 : (elapsed - lastTick).inMicroseconds;
    final double dt = (elapsedMicros / Duration.microsecondsPerSecond)
        .clamp(1 / 120, 1 / 24)
        .toDouble();

    _phase += dt;
    _stepSimulation(dt);
    setState(() {});
  }

  void _ensureSimulation(Size size) {
    if (_seeded && _sceneSize == size) {
      return;
    }
    _sceneSize = size;
    _seedSimulation();
  }

  void _seedSimulation() {
    if (_sceneSize.isEmpty) {
      return;
    }

    _oval = _AmbientBody(
      position: Offset(
        _sceneSize.width * 0.46,
        _sceneSize.height * 0.90,
      ),
      velocity: const Offset(4, -2),
      mass: 0.92,
    );
    _cookie = _AmbientBody(
      position: Offset(
        _sceneSize.width * 0.56,
        _sceneSize.height * 0.15,
      ),
      velocity: const Offset(-1, 1),
      mass: 1.0,
    );
    _phase = 0;
    _impactEnergy = 0;
    _ovalBounceLift = 0;
    _cookieBounceLift = 0;
    _seeded = true;
  }

  void _stepSimulation(double dt) {
    final _AmbientSceneMetrics metrics = _AmbientSceneMetrics.fromSize(
      _sceneSize,
    );
    final Offset ovalTarget = Offset(
      (_sceneSize.width * 0.57) + (math.sin(_phase * 0.12) * 7),
      (_sceneSize.height * 0.84) + (math.cos(_phase * 0.10) * 4),
    );
    final Offset cookieAnchor = Offset(
      (_sceneSize.width * 0.53) + (math.sin(_phase * 0.43) * 22),
      _sceneSize.height * 0.14,
    );

    _applySpring(
      body: _oval,
      target: ovalTarget,
      attraction: 0.42,
      damping: 2.25,
      dt: dt,
    );
    _applyOvalBounceLift(dt: dt);
    _applyCookieGravity(
      anchor: cookieAnchor,
      dt: dt,
    );

    _oval.position += _oval.velocity * dt;
    _cookie.position += _cookie.velocity * dt;

    _containBodies(metrics);
    _resolveCollision(metrics: metrics, dt: dt);

    final double ovalDrag = math.pow(0.993, dt * 60).toDouble();
    final double cookieDrag = math.pow(0.948, dt * 60).toDouble();
    _oval.velocity *= ovalDrag;
    _cookie.velocity *= cookieDrag;
    _ovalBounceLift = math.max(0.0, _ovalBounceLift - (dt * 420)).toDouble();
    _cookieBounceLift =
        math.max(0.0, _cookieBounceLift - (dt * 540)).toDouble();
    _impactEnergy = math.max(0.0, _impactEnergy - (dt * 1.9)).toDouble();
  }

  void _applySpring({
    required _AmbientBody body,
    required Offset target,
    required double attraction,
    required double damping,
    required double dt,
  }) {
    final Offset delta = target - body.position;
    final Offset acceleration =
        (delta * attraction) - (body.velocity * damping);
    body.velocity += acceleration * dt;
  }

  void _applyOvalBounceLift({
    required double dt,
  }) {
    final double lift = _ovalBounceLift;
    if (lift <= 0) {
      return;
    }
    final Offset acceleration = Offset(
      0,
      -lift - (_oval.velocity.dy * 0.1),
    );
    _oval.velocity += acceleration * dt;
  }

  void _applyCookieGravity({
    required Offset anchor,
    required double dt,
  }) {
    final double dx = anchor.dx - _cookie.position.dx;
    final double horizontalPull = dx * 0.75;
    final double downwardPull = 110;
    final double topLift = _cookie.position.dy < anchor.dy
        ? (anchor.dy - _cookie.position.dy) * 0.35
        : 0;
    final double bounceLift = _cookieBounceLift;
    final Offset acceleration = Offset(
      horizontalPull - (_cookie.velocity.dx * 3.2),
      downwardPull + topLift - bounceLift - (_cookie.velocity.dy * 0.44),
    );
    _cookie.velocity += (acceleration / _cookie.mass) * dt;
  }

  void _containBodies(_AmbientSceneMetrics metrics) {
    final double cookieMinX = -metrics.cookieRadius * 0.12;
    final double cookieMaxX = _sceneSize.width + (metrics.cookieRadius * 0.12);
    if (_cookie.position.dx < cookieMinX) {
      _cookie.position = Offset(cookieMinX, _cookie.position.dy);
      _cookie.velocity =
          Offset(_cookie.velocity.dx.abs() * 0.72, _cookie.velocity.dy);
    } else if (_cookie.position.dx > cookieMaxX) {
      _cookie.position = Offset(cookieMaxX, _cookie.position.dy);
      _cookie.velocity =
          Offset(-_cookie.velocity.dx.abs() * 0.72, _cookie.velocity.dy);
    }

    final double cookieMinY = metrics.cookieRadius * 0.35;
    if (_cookie.position.dy < cookieMinY) {
      _cookie.position = Offset(_cookie.position.dx, cookieMinY);
      _cookie.velocity =
          Offset(_cookie.velocity.dx, _cookie.velocity.dy.abs() * 0.35);
    }

    final double ovalMinX = _sceneSize.width * 0.28;
    final double ovalMaxX = _sceneSize.width * 0.72;
    if (_oval.position.dx < ovalMinX) {
      _oval.position = Offset(ovalMinX, _oval.position.dy);
      _oval.velocity = Offset(_oval.velocity.dx.abs() * 0.4, _oval.velocity.dy);
    } else if (_oval.position.dx > ovalMaxX) {
      _oval.position = Offset(ovalMaxX, _oval.position.dy);
      _oval.velocity =
          Offset(-_oval.velocity.dx.abs() * 0.4, _oval.velocity.dy);
    }
  }

  void _resolveCollision({
    required _AmbientSceneMetrics metrics,
    required double dt,
  }) {
    final _ShapeCollisionInfo? collision = _measureCollision(metrics);
    if (collision == null) {
      return;
    }

    final Offset normal = collision.normal;
    final double penetration = collision.penetration;
    final double correction = penetration * 0.52;
    final double totalMass = _oval.mass + _cookie.mass;
    final double ovalCorrectionShare = _cookie.mass / totalMass;
    final double cookieCorrectionShare = _oval.mass / totalMass;

    _oval.position -= normal * (correction * ovalCorrectionShare);
    _cookie.position += normal * (correction * cookieCorrectionShare);

    final double relativeVelocity = _dot(
      _cookie.velocity - _oval.velocity,
      normal,
    );
    if (relativeVelocity < 0) {
      const double restitution = 0.96;
      final double impulse = (-(1 + restitution) * relativeVelocity) /
          ((1 / _oval.mass) + (1 / _cookie.mass));
      _oval.velocity -= normal * (impulse / _oval.mass);
      _cookie.velocity += normal * (impulse / _cookie.mass);
      if (normal.dy < -0.18) {
        _oval.velocity += Offset(0, -68 - (penetration * 2.2));
        _ovalBounceLift = math
            .max(
              _ovalBounceLift,
              300 + (penetration * 11),
            )
            .toDouble();
        _cookie.velocity += Offset(0, -185 - (penetration * 4.8));
        _cookieBounceLift = math
            .max(
              _cookieBounceLift,
              980 + (penetration * 26),
            )
            .toDouble();
      }
      _impactEnergy = math
          .min(
            1.0,
            _impactEnergy + ((-relativeVelocity) / 200) + (penetration / 24),
          )
          .toDouble();
    }

    final double reboundBoost = 86 + (penetration * 6.5);
    _oval.velocity -= normal * ((reboundBoost / _oval.mass) * dt);
    _cookie.velocity += normal * ((reboundBoost / _cookie.mass) * dt);
  }

  double _dot(Offset a, Offset b) => (a.dx * b.dx) + (a.dy * b.dy);

  _ShapeCollisionInfo? _measureCollision(_AmbientSceneMetrics metrics) {
    const double contactThreshold = 3.4;

    final List<Offset> ovalPoints = _ambientOvalProfile.transformedPoints(
      center: _oval.position,
      width: metrics.ovalWidth,
      height: metrics.ovalHeight,
      rotation: _ambientOvalRotation(_phase),
    );
    final List<Offset> cookiePoints = _ambientCookieProfile.transformedPoints(
      center: _cookie.position,
      width: metrics.cookieRadius * 2,
      height: metrics.cookieRadius * 2,
      rotation: _ambientCookieRotation(_phase),
    );

    Offset bestOvalPoint = ovalPoints.first;
    Offset bestCookiePoint = cookiePoints.first;
    double minDistanceSquared = double.infinity;

    for (final Offset ovalPoint in ovalPoints) {
      for (final Offset cookiePoint in cookiePoints) {
        final Offset delta = cookiePoint - ovalPoint;
        final double distanceSquared = delta.distanceSquared;
        if (distanceSquared < minDistanceSquared) {
          minDistanceSquared = distanceSquared;
          bestOvalPoint = ovalPoint;
          bestCookiePoint = cookiePoint;
        }
      }
    }

    if (minDistanceSquared > contactThreshold * contactThreshold) {
      return null;
    }

    final double distance = math.sqrt(minDistanceSquared);
    Offset delta = bestCookiePoint - bestOvalPoint;
    if (distance <= 0.000001) {
      delta = _cookie.position - _oval.position;
    }
    if (delta.distanceSquared <= 0.000001) {
      delta = const Offset(0, -1);
    }

    final Offset normal = delta / delta.distance;
    return _ShapeCollisionInfo(
      normal: normal,
      penetration: contactThreshold - distance,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureSimulation(constraints.biggest);
        if (!_seeded) {
          return const SizedBox.expand();
        }
        return CustomPaint(
          isComplex: true,
          willChange: true,
          painter: _AmbientOutlinePainter(
            phase: _phase,
            impactEnergy: _impactEnergy,
            ovalCenter: _oval.position,
            cookieCenter: _cookie.position,
            outlineColor: widget.outlineColor,
            accentColor: widget.accentColor,
            backgroundColor: widget.backgroundColor,
            isDarkBackground: widget.isDarkBackground,
          ),
        );
      },
    );
  }
}

class _AmbientOutlinePainter extends CustomPainter {
  const _AmbientOutlinePainter({
    required this.phase,
    required this.impactEnergy,
    required this.ovalCenter,
    required this.cookieCenter,
    required this.outlineColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.isDarkBackground,
  });

  final double phase;
  final double impactEnergy;
  final Offset ovalCenter;
  final Offset cookieCenter;
  final Color outlineColor;
  final Color accentColor;
  final Color backgroundColor;
  final bool isDarkBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final _AmbientSceneMetrics metrics = _AmbientSceneMetrics.fromSize(size);
    final double impact =
        Curves.easeOut.transform(impactEnergy.clamp(0.0, 1.0).toDouble());
    final double ovalStrokeWidth = isDarkBackground ? 2.0 : 2.35;
    final double ovalAlpha = isDarkBackground ? 0.28 : 0.46;
    final double accentStrokeWidth = isDarkBackground ? 1.45 : 1.7;
    final double accentAlpha = isDarkBackground ? 0.36 : 0.48;
    final ovalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ovalStrokeWidth
      ..color = outlineColor.withValues(alpha: ovalAlpha);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = accentStrokeWidth + (impact * 0.75)
      ..color = accentColor.withValues(alpha: accentAlpha + (impact * 0.12));
    final cookieMaskPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2 + (impact * 1.9)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = backgroundColor.withValues(alpha: 0.96);

    final Path ovalPath = _buildOfficialOvalPath(
      center: ovalCenter,
      width: metrics.ovalWidth,
      height: metrics.ovalHeight,
      rotation: _ambientOvalRotation(phase),
    );
    canvas.drawPath(ovalPath, ovalPaint);

    final double cookieSpin = _ambientCookieRotation(phase);
    final Path cookiePath = _buildOfficialCookie12Path(
      center: cookieCenter,
      radius: metrics.cookieRadius * (1 + (impact * 0.02)),
      rotation: cookieSpin,
    );
    canvas.drawPath(cookiePath, cookieMaskPaint);
    canvas.drawPath(cookiePath, accentPaint);
  }

  // Ported from official AndroidX Material 3 expressive shapes source:
  // Cookie9Sided = star(numVerticesPerRadius = 9, innerRadius = .8f, rounding = .5f)
  // then rotated -90 degrees. Flutter doesn't ship RoundedPolygon, so the path is reconstructed
  // from the same official geometry parameters.
  Path _buildOfficialCookie12Path({
    required Offset center,
    required double radius,
    double rotation = 0,
  }) {
    final Path normalized = MaterialShapes.cookie12Sided.toPath();
    return _fitNormalizedPath(
      normalized,
      center: center,
      width: radius * 2,
      height: radius * 2,
      rotation: rotation,
    );
  }

  // Official AndroidX M3 Oval from MaterialShapes.oval.
  Path _buildOfficialOvalPath({
    required Offset center,
    required double width,
    required double height,
    double rotation = 0,
  }) {
    final Path normalized = MaterialShapes.oval.toPath();
    return _fitNormalizedPath(
      normalized,
      center: center,
      width: width,
      height: height,
      rotation: rotation,
    );
  }

  Path _fitNormalizedPath(
    Path source, {
    required Offset center,
    required double width,
    required double height,
    double rotation = 0,
  }) {
    final Rect bounds = source.getBounds();
    final Matrix4 transform = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(rotation)
      ..scaleByDouble(width / bounds.width, height / bounds.height, 1, 1)
      ..translateByDouble(
        -(bounds.left + (bounds.width / 2)),
        -(bounds.top + (bounds.height / 2)),
        0,
        1,
      );
    return source.transform(transform.storage);
  }

  @override
  bool shouldRepaint(covariant _AmbientOutlinePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.impactEnergy != impactEnergy ||
        oldDelegate.ovalCenter != ovalCenter ||
        oldDelegate.cookieCenter != cookieCenter ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _AmbientBody {
  _AmbientBody({
    required this.position,
    required this.velocity,
    required this.mass,
  });

  Offset position;
  Offset velocity;
  final double mass;
}

class _ShapeProfile {
  const _ShapeProfile(this.normalizedPoints);

  factory _ShapeProfile.fromPath(Path path, {int sampleCount = 180}) {
    final Rect bounds = path.getBounds();
    final Offset center = bounds.center;
    final metrics = path.computeMetrics(forceClosed: true).toList();
    final double totalLength = metrics.fold<double>(
      0,
      (sum, metric) => sum + metric.length,
    );
    final List<Offset> normalizedPoints = <Offset>[];

    for (final metric in metrics) {
      final int steps = math.max(
        24,
        ((sampleCount * metric.length) / math.max(totalLength, 1)).round(),
      );
      for (int index = 0; index < steps; index++) {
        final tangent = metric.getTangentForOffset(
          (metric.length * index) / steps,
        );
        if (tangent == null) {
          continue;
        }
        normalizedPoints.add(
          Offset(
            (tangent.position.dx - center.dx) / bounds.width,
            (tangent.position.dy - center.dy) / bounds.height,
          ),
        );
      }
    }

    return _ShapeProfile(normalizedPoints);
  }

  final List<Offset> normalizedPoints;

  List<Offset> transformedPoints({
    required Offset center,
    required double width,
    required double height,
    required double rotation,
  }) {
    return normalizedPoints
        .map(
          (point) =>
              center +
              _rotateOffset(
                Offset(point.dx * width, point.dy * height),
                rotation,
              ),
        )
        .toList(growable: false);
  }
}

class _ShapeCollisionInfo {
  const _ShapeCollisionInfo({
    required this.normal,
    required this.penetration,
  });

  final Offset normal;
  final double penetration;
}

class _AmbientSceneMetrics {
  const _AmbientSceneMetrics({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.ovalCollisionRadius,
    required this.cookieRadius,
    required this.cookieCollisionRadius,
    required this.contactDistance,
  });

  factory _AmbientSceneMetrics.fromSize(Size size) {
    final double ovalWidth = size.width * 1.86;
    final double ovalHeight = ovalWidth * 0.56;
    final double ovalCollisionRadius = ovalWidth * 0.29;
    final double cookieRadius = math.min(size.width, size.height) * 0.37;
    final double cookieCollisionRadius = cookieRadius * 0.92;
    final double contactDistance =
        ovalCollisionRadius + cookieCollisionRadius - 4;

    return _AmbientSceneMetrics(
      ovalWidth: ovalWidth,
      ovalHeight: ovalHeight,
      ovalCollisionRadius: ovalCollisionRadius,
      cookieRadius: cookieRadius,
      cookieCollisionRadius: cookieCollisionRadius,
      contactDistance: contactDistance,
    );
  }

  final double ovalWidth;
  final double ovalHeight;
  final double ovalCollisionRadius;
  final double cookieRadius;
  final double cookieCollisionRadius;
  final double contactDistance;
}

double _ambientOvalRotation(double phase) {
  return (-0.34) + (math.sin(phase * 0.22) * 0.05);
}

double _ambientCookieRotation(double phase) {
  return (phase * 0.74) + (math.sin((phase * 0.92) + 0.6) * 0.18);
}

Offset _rotateOffset(Offset point, double radians) {
  final double c = math.cos(radians);
  final double s = math.sin(radians);
  return Offset(
    (point.dx * c) - (point.dy * s),
    (point.dx * s) + (point.dy * c),
  );
}

class _WelcomeSelectionRow extends StatelessWidget {
  const _WelcomeSelectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final Widget label;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.88),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: label,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionSheet extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeToggleButton extends StatelessWidget {
  const _ThemeModeToggleButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final bool isDark = ThemeController.instance.isDark;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => ThemeController.instance.setThemeMode(
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.82),
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: RotationTransition(
                      turns: Tween<double>(
                        begin: 0.08,
                        end: 0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey<bool>(isDark),
                  size: 20,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectionOption extends StatelessWidget {
  const _SelectionOption({
    required this.title,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: active
          ? scheme.secondaryContainer.withValues(alpha: 0.92)
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        active ? scheme.onSecondaryContainer : scheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border:
                      active ? null : Border.all(color: scheme.outlineVariant),
                ),
                child: active
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: scheme.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelectionOption extends StatelessWidget {
  const _ThemeSelectionOption({
    required this.title,
    required this.swatches,
    required this.active,
    required this.onTap,
  });

  final String title;
  final List<Color> swatches;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SelectionOption(
      title: title,
      active: active,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final swatch in swatches) ...[
            Container(
              height: 14,
              width: 14,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
            if (swatch != swatches.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

List<Color> _themeSwatches(AppThemeVariant variant) {
  return switch (variant) {
    AppThemeVariant.classic => const [
        Color(0xFF324670),
        Color(0xFFD8E2FF),
        Color(0xFF53627F),
      ],
    AppThemeVariant.earthy => const [
        Color(0xFF8A7650),
        Color(0xFFDBCEA5),
        Color(0xFF8E977D),
      ],
    AppThemeVariant.blush => const [
        Color(0xFFF5AFAF),
        Color(0xFFF9DFDF),
        Color(0xFFFBEFEF),
      ],
    AppThemeVariant.moss => const [
        Color(0xFF84B179),
        Color(0xFFC7EABB),
        Color(0xFFA2CB8B),
      ],
    AppThemeVariant.lavender => const [
        Color(0xFF4D4C7D),
        Color(0xFFD8B9C3),
        Color(0xFF827397),
      ],
    AppThemeVariant.slate => const [
        Color(0xFF30364F),
        Color(0xFFACBAC4),
        Color(0xFFE1D9BC),
      ],
    AppThemeVariant.ocean => const [
        Color(0xFF1C4D8D),
        Color(0xFF4988C4),
        Color(0xFFBDE8F5),
      ],
  };
}
