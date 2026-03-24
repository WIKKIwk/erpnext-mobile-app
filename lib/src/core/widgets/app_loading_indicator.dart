import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 64,
    this.glyphSize = 20,
  });

  final double size;
  final double glyphSize;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();
  late final int _startOffset = math.Random().nextInt(_shapeCycle.length);

  static const List<_LoaderShapeKind> _shapeCycle = <_LoaderShapeKind>[
    _LoaderShapeKind.clover,
    _LoaderShapeKind.arrow,
    _LoaderShapeKind.diamond,
    _LoaderShapeKind.ghostish,
    _LoaderShapeKind.verySunny,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ShapeBorder _shapeFor(_LoaderShapeKind kind) {
    switch (kind) {
      case _LoaderShapeKind.clover:
        return const _LoaderBlobBorder(
          lobes: 4,
          amplitude: 0.12,
          secondaryAmplitude: 0,
          rotation: 0,
          scaleX: 0.9,
          scaleY: 0.9,
        );
      case _LoaderShapeKind.arrow:
        return const _LoaderBlobBorder(
          lobes: 3,
          amplitude: 0.13,
          secondaryAmplitude: 0,
          rotation: 0,
          scaleX: 0.9,
          scaleY: 0.94,
        );
      case _LoaderShapeKind.diamond:
        return const _LoaderBlobBorder(
          lobes: 4,
          amplitude: 0.035,
          secondaryAmplitude: 0,
          rotation: math.pi / 4,
          scaleX: 0.84,
          scaleY: 0.98,
        );
      case _LoaderShapeKind.ghostish:
        return const _LoaderBlobBorder(
          lobes: 1,
          amplitude: 0.11,
          secondaryAmplitude: 0,
          rotation: math.pi / 2,
          scaleX: 0.9,
          scaleY: 1.02,
        );
      case _LoaderShapeKind.verySunny:
        return const _LoaderBlobBorder(
          lobes: 8,
          amplitude: 0.055,
          secondaryAmplitude: 0,
          rotation: 0,
          scaleX: 0.9,
          scaleY: 0.9,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = scheme.outlineVariant.withValues(alpha: 0.42);
    final surface = Theme.of(context).brightness == Brightness.dark
        ? scheme.surfaceContainerLow
        : scheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final rotation = _controller.value * math.pi * 2;
        final morphValue =
            (_controller.value * _shapeCycle.length) + _startOffset;
        final currentIndex = morphValue.floor() % _shapeCycle.length;
        final nextIndex = (currentIndex + 1) % _shapeCycle.length;
        final localT = Curves.easeInOutCubicEmphasized
            .transform((morphValue - morphValue.floor()).clamp(0.0, 1.0));
        final shape = ShapeBorder.lerp(
              _shapeFor(_shapeCycle[currentIndex]),
              _shapeFor(_shapeCycle[nextIndex]),
              localT,
            ) ??
            const CircleBorder();
        final pulse = 0.94 + (0.08 * math.sin(_controller.value * math.pi * 2));

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: pulse,
                  child: SizedBox(
                    width: widget.glyphSize,
                    height: widget.glyphSize,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: scheme.primary,
                        shape: shape,
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

enum _LoaderShapeKind {
  clover,
  arrow,
  diamond,
  ghostish,
  verySunny,
}

class _LoaderBlobBorder extends OutlinedBorder {
  const _LoaderBlobBorder({
    required this.lobes,
    required this.amplitude,
    required this.secondaryAmplitude,
    required this.rotation,
    required this.scaleX,
    required this.scaleY,
    super.side,
  });

  final double lobes;
  final double amplitude;
  final double secondaryAmplitude;
  final double rotation;
  final double scaleX;
  final double scaleY;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) {
    return _LoaderBlobBorder(
      lobes: lobes,
      amplitude: amplitude,
      secondaryAmplitude: secondaryAmplitude,
      rotation: rotation,
      scaleX: scaleX,
      scaleY: scaleY,
      side: side.scale(t),
    );
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _LoaderBlobBorder) {
      return _LoaderBlobBorder(
        lobes: _lerpDouble(a.lobes, lobes, t),
        amplitude: _lerpDouble(a.amplitude, amplitude, t),
        secondaryAmplitude:
            _lerpDouble(a.secondaryAmplitude, secondaryAmplitude, t),
        rotation: _lerpDouble(a.rotation, rotation, t),
        scaleX: _lerpDouble(a.scaleX, scaleX, t),
        scaleY: _lerpDouble(a.scaleY, scaleY, t),
        side: BorderSide.lerp(a.side, side, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _LoaderBlobBorder) {
      return _LoaderBlobBorder(
        lobes: _lerpDouble(lobes, b.lobes, t),
        amplitude: _lerpDouble(amplitude, b.amplitude, t),
        secondaryAmplitude:
            _lerpDouble(secondaryAmplitude, b.secondaryAmplitude, t),
        rotation: _lerpDouble(rotation, b.rotation, t),
        scaleX: _lerpDouble(scaleX, b.scaleX, t),
        scaleY: _lerpDouble(scaleY, b.scaleY, t),
        side: BorderSide.lerp(side, b.side, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    final rx = rect.width / 2 * scaleX;
    final ry = rect.height / 2 * scaleY;
    const steps = 72;
    final points = <Offset>[];

    for (int i = 0; i < steps; i++) {
      final theta = (i / steps) * math.pi * 2;
      final primary = math.cos((lobes * theta) + rotation);
      final secondary = secondaryAmplitude == 0
          ? 0
          : math.sin(((lobes + 1.35) * theta) - (rotation * 0.65));
      final radiusFactor =
          1 + (amplitude * primary) + (secondaryAmplitude * secondary);
      final x = center.dx + (math.cos(theta) * rx * radiusFactor);
      final y = center.dy + (math.sin(theta) * ry * radiusFactor);
      points.add(Offset(x, y));
    }

    final path = Path();
    if (points.isEmpty) {
      return path;
    }

    final firstMid = Offset(
      (points[0].dx + points[1].dx) / 2,
      (points[0].dy + points[1].dy) / 2,
    );
    path.moveTo(firstMid.dx, firstMid.dy);
    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  _LoaderBlobBorder copyWith({BorderSide? side}) {
    return _LoaderBlobBorder(
      lobes: lobes,
      amplitude: amplitude,
      secondaryAmplitude: secondaryAmplitude,
      rotation: rotation,
      scaleX: scaleX,
      scaleY: scaleY,
      side: side ?? this.side,
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + ((b - a) * t);
