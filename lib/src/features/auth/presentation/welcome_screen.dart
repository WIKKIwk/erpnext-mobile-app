import 'dart:math' as math;

import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/motion_widgets.dart';
import 'package:androidx_graphics_shapes/material_shapes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onGetStarted,
  });

  final Future<void> Function() onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        LocaleController.instance,
        ThemeController.instance,
      ]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final currentLocale = LocaleController.instance.locale;
        final currentVariant = ThemeController.instance.variant;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: _AmbientOutlineBackground(
                      outlineColor: scheme.outlineVariant,
                      accentColor: scheme.primary,
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
                          child: Text(
                            l10n.welcomeToAccord,
                            style: GoogleFonts.manrope(
                              fontSize: 46,
                              height: 1.02,
                              letterSpacing: -1.7,
                              fontWeight: FontWeight.w400,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 110),
                          offset: const Offset(0, 14),
                          child: _WelcomeSelectionRow(
                            icon: Icons.language_rounded,
                            label: l10n.languageTitle,
                            value: _localeLabel(l10n, currentLocale),
                            onTap: () => _pickLocale(context, currentLocale),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 150),
                          offset: const Offset(0, 14),
                          child: _WelcomeSelectionRow(
                            icon: Icons.palette_outlined,
                            label: l10n.themeTitle,
                            value: _themeLabel(l10n, currentVariant),
                            onTap: () => _pickTheme(context, currentVariant),
                          ),
                        ),
                        const SizedBox(height: 34),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 190),
                          offset: const Offset(0, 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: onGetStarted,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Text(
                                l10n.getStarted,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w700,
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
            children: [
              _SelectionOption(
                title: l10n.uzbek,
                active: currentLocale.languageCode == 'uz',
                onTap: () => Navigator.of(context).pop(const Locale('uz')),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.english,
                active: currentLocale.languageCode == 'en',
                onTap: () => Navigator.of(context).pop(const Locale('en')),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.russian,
                active: currentLocale.languageCode == 'ru',
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
    await LocaleController.instance.setLocale(picked);
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
          child: Column(
            children: [
              _SelectionOption(
                title: l10n.themeClassicLabel,
                active: currentVariant == AppThemeVariant.classic,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.classic),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.themeEarthLabel,
                active: currentVariant == AppThemeVariant.earthy,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.earthy),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.themeBlushLabel,
                active: currentVariant == AppThemeVariant.blush,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.blush),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.themeMossLabel,
                active: currentVariant == AppThemeVariant.moss,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.moss),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.themeLavenderLabel,
                active: currentVariant == AppThemeVariant.lavender,
                onTap: () =>
                    Navigator.of(context).pop(AppThemeVariant.lavender),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.themeSlateLabel,
                active: currentVariant == AppThemeVariant.slate,
                onTap: () => Navigator.of(context).pop(AppThemeVariant.slate),
              ),
              const SizedBox(height: 10),
              _SelectionOption(
                title: l10n.themeOceanLabel,
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

class _AmbientOutlineBackground extends StatefulWidget {
  const _AmbientOutlineBackground({
    required this.outlineColor,
    required this.accentColor,
  });

  final Color outlineColor;
  final Color accentColor;

  @override
  State<_AmbientOutlineBackground> createState() =>
      _AmbientOutlineBackgroundState();
}

class _AmbientOutlineBackgroundState extends State<_AmbientOutlineBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _AmbientOutlinePainter(
            progress: _controller.value,
            outlineColor: widget.outlineColor,
            accentColor: widget.accentColor,
          ),
        );
      },
    );
  }
}

class _AmbientOutlinePainter extends CustomPainter {
  const _AmbientOutlinePainter({
    required this.progress,
    required this.outlineColor,
    required this.accentColor,
  });

  final double progress;
  final Color outlineColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ovalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..color = outlineColor.withValues(alpha: 0.18);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..color = accentColor.withValues(alpha: 0.22);
    final cookieMaskPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF000000).withValues(alpha: 0.92);

    final double phase = progress * math.pi * 2;
    final double sharedDriftX = _loopNoise(
      phase,
      frequencies: const [1, 2, 3],
      amplitudes: const [6, 3, 1.5],
      phases: const [0.0, 1.1, -0.35],
    );
    final double sharedDriftY = _loopNoise(
      phase,
      frequencies: const [1, 2],
      amplitudes: const [4, 2],
      phases: const [0.7, -1.4],
      cosine: true,
    );
    final Offset ovalCenter = Offset(
      size.width * 0.31 + sharedDriftX,
      size.height * 0.77 + sharedDriftY,
    );
    final double ovalWidth = size.width * 2.25;
    final double ovalHeight = ovalWidth * 0.64;

    final Path ovalPath = _buildOfficialOvalPath(
      center: ovalCenter,
      width: ovalWidth,
    );
    canvas.drawPath(ovalPath, ovalPaint);

    final double cookieRadius = math.min(size.width, size.height) * 0.42;
    final double anchorT =
        (-0.18 * math.pi) + (math.sin((phase * 1.4) + 0.8) * 0.035);
    final Offset anchorPoint = _pointOnOfficialOval(
      center: ovalCenter,
      width: ovalWidth,
      height: ovalHeight,
      t: anchorT,
    );
    final Offset outwardNormal = _outwardNormalOnOfficialOval(
      width: ovalWidth,
      height: ovalHeight,
      t: anchorT,
    );
    final double compression = ((math.sin((phase * 2.0) - 0.7) + 1) / 2) * 3;
    final double cookieDistance = (cookieRadius * 0.79) - compression;
    final Path cookiePath = _buildOfficialCookie12Path(
      center: anchorPoint + (outwardNormal * cookieDistance),
      radius: cookieRadius,
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
  }) {
    final Path normalized = MaterialShapes.cookie12Sided.toPath();
    return _fitNormalizedPath(
      normalized,
      center: center,
      width: radius * 2,
      height: radius * 2,
    );
  }

  // Official AndroidX M3 Oval from MaterialShapes.oval.
  Path _buildOfficialOvalPath({
    required Offset center,
    required double width,
  }) {
    final Path normalized = MaterialShapes.oval.toPath();
    return _fitNormalizedPath(
      normalized,
      center: center,
      width: width,
      height: width * 0.64,
    );
  }

  Path _fitNormalizedPath(
    Path source, {
    required Offset center,
    required double width,
    required double height,
  }) {
    final Rect bounds = source.getBounds();
    final Matrix4 transform = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(
        width / bounds.width,
        height / bounds.height,
        1,
        1,
      )
      ..translateByDouble(
        -(bounds.left + bounds.width / 2),
        -(bounds.top + bounds.height / 2),
        0,
        1,
      );
    return source.transform(transform.storage);
  }

  double _loopNoise(
    double phase, {
    required List<int> frequencies,
    required List<double> amplitudes,
    required List<double> phases,
    bool cosine = false,
  }) {
    double total = 0;
    for (int i = 0; i < frequencies.length; i++) {
      final double angle = (phase * frequencies[i]) + phases[i];
      total += (cosine ? math.cos(angle) : math.sin(angle)) * amplitudes[i];
    }
    return total;
  }

  Offset _pointOnOfficialOval({
    required Offset center,
    required double width,
    required double height,
    required double t,
  }) {
    final double a = width / 2;
    final double b = height / 2;
    final Offset local = Offset(a * math.cos(t), b * math.sin(t));
    final Offset rotated = _rotate(local, -math.pi / 4);
    return center + rotated;
  }

  Offset _outwardNormalOnOfficialOval({
    required double width,
    required double height,
    required double t,
  }) {
    final double a = width / 2;
    final double b = height / 2;
    final Offset localNormal = Offset(math.cos(t) / a, math.sin(t) / b);
    final Offset rotatedNormal = _rotate(localNormal, -math.pi / 4);
    final double length = rotatedNormal.distance;
    if (length == 0) {
      return const Offset(0, -1);
    }
    return rotatedNormal / length;
  }

  Offset _rotate(Offset point, double radians) {
    final double c = math.cos(radians);
    final double s = math.sin(radians);
    return Offset(
      (point.dx * c) - (point.dy * s),
      (point.dx * s) + (point.dy * c),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientOutlinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.accentColor != accentColor;
  }
}

class _WelcomeSelectionRow extends StatelessWidget {
  const _WelcomeSelectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
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
                child: Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 21,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.expand_more_rounded,
                color: scheme.onSurface.withValues(alpha: 0.72),
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
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
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
              Text(
                title,
                style: theme.textTheme.titleLarge,
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

class _SelectionOption extends StatelessWidget {
  const _SelectionOption({
    required this.title,
    required this.active,
    required this.onTap,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;

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
