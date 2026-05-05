import 'dart:async';
import 'dart:math' as math;

import '../../theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinCodeEditor extends StatefulWidget {
  const PinCodeEditor({
    super.key,
    required this.controller,
    required this.onAction,
    required this.actionLabel,
    required this.actionIcon,
    this.errorText,
    this.busy = false,
  });

  final TextEditingController controller;
  final VoidCallback onAction;
  final String actionLabel;
  final IconData actionIcon;
  final String? errorText;
  final bool busy;

  @override
  State<PinCodeEditor> createState() => _PinCodeEditorState();
}

class _PinCodeEditorState extends State<PinCodeEditor> {
  final math.Random _random = math.Random();
  int _animateTick = 0;
  int? _insertingIndex;
  int? _deletingIndex;
  _PinShapeKind? _deletingShape;
  List<_PinShapeKind> _shapeCycle = const [];
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
    _lastValue = widget.controller.text;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant PinCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      _lastValue = widget.controller.text;
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final value = widget.controller.text;
    if (value == _lastValue) {
      return;
    }
    if (value.length > _lastValue.length && value.isNotEmpty) {
      if (_shapeCycle.length != 4) {
        _shapeCycle = _generateUniqueShapes();
      }
      _animateTick += 1;
      _insertingIndex = value.length - 1;
      _deletingIndex = null;
      _deletingShape = null;
    } else if (value.length < _lastValue.length) {
      _animateTick += 1;
      _deletingIndex = _lastValue.length - 1;
      if (_deletingIndex! >= 0 && _deletingIndex! < _shapeCycle.length) {
        _deletingShape = _shapeCycle[_deletingIndex!];
      }
      _insertingIndex = null;
      final deleteTick = _animateTick;
      Timer(const Duration(milliseconds: 320), () {
        if (!mounted || _animateTick != deleteTick) {
          return;
        }
        setState(() {
          _deletingIndex = null;
          _deletingShape = null;
        });
      });
      if (value.isEmpty) {
        _shapeCycle = const [];
      }
    }
    _lastValue = value;
    if (mounted) {
      setState(() {});
    }
  }

  List<_PinShapeKind> _generateUniqueShapes() {
    final pool = _PinShapeKind.values.toList()..shuffle(_random);
    return pool.take(4).toList(growable: false);
  }

  bool get _canSubmit => widget.controller.text.length == 4 && !widget.busy;

  void _appendDigit(String digit) {
    if (widget.busy || widget.controller.text.length >= 4) {
      return;
    }
    HapticFeedback.selectionClick();
    final value = widget.controller.text + digit;
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _removeDigit() {
    if (widget.busy || widget.controller.text.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    final value =
        widget.controller.text.substring(0, widget.controller.text.length - 1);
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _PinIndicatorRow(
            length: widget.controller.text.length,
            insertingIndex: _insertingIndex,
            deletingIndex: _deletingIndex,
            deletingShape: _deletingShape,
            shapeCycle: _shapeCycle,
            animateTick: _animateTick,
          ),
        ),
        if (widget.errorText != null &&
            widget.errorText!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            widget.errorText!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.error,
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Column(
          children: [
            _PinKeypadRow(digits: ['1', '2', '3']),
            SizedBox(height: 12),
            _PinKeypadRow(digits: ['4', '5', '6']),
            SizedBox(height: 12),
            _PinKeypadRow(digits: ['7', '8', '9']),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PinActionButton(
              icon: Icons.backspace_outlined,
              onTap: _removeDigit,
              enabled: widget.controller.text.isNotEmpty && !widget.busy,
            ),
            _PinDigitButton(
              label: '0',
              onTap: () => _appendDigit('0'),
              enabled: !widget.busy,
            ),
            _PinActionButton(
              icon: widget.actionIcon,
              onTap: widget.onAction,
              enabled: _canSubmit,
              emphasized: true,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            widget.actionLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _PinIndicatorRow extends StatelessWidget {
  const _PinIndicatorRow({
    required this.length,
    required this.insertingIndex,
    required this.deletingIndex,
    required this.deletingShape,
    required this.shapeCycle,
    required this.animateTick,
  });

  final int length;
  final int? insertingIndex;
  final int? deletingIndex;
  final _PinShapeKind? deletingShape;
  final List<_PinShapeKind> shapeCycle;
  final int animateTick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(4, (index) {
          final filled = index < length;
          final motion = filled && insertingIndex == index
              ? _PinGlyphMotion.insert
              : (!filled && deletingIndex == index)
                  ? _PinGlyphMotion.delete
                  : _PinGlyphMotion.none;
          final shapeKind = filled
              ? (index < shapeCycle.length ? shapeCycle[index] : null)
              : (deletingIndex == index ? deletingShape : null);
          return Padding(
            padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
            child: _PinGlyph(
              filled: filled,
              motion: motion,
              animateTick: animateTick,
              variant: index,
              shapeKind: shapeKind,
            ),
          );
        }),
      ),
    );
  }
}

enum _PinGlyphMotion {
  none,
  insert,
  delete,
}

enum _PinShapeKind {
  clover,
  arrow,
  square,
  pentagon,
  diamond,
  verySunny,
  ghostish,
}

class _PinGlyph extends StatelessWidget {
  const _PinGlyph({
    required this.filled,
    required this.motion,
    required this.animateTick,
    required this.variant,
    required this.shapeKind,
  });

  final bool filled;
  final _PinGlyphMotion motion;
  final int animateTick;
  final int variant;
  final _PinShapeKind? shapeKind;

  ShapeBorder _startShape() {
    switch (shapeKind) {
      case _PinShapeKind.clover:
        return const _OrganicBlobBorder(
          lobes: 4,
          amplitude: 0.12,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.9,
          scaleY: 0.9,
        );
      case _PinShapeKind.arrow:
        return const _OrganicBlobBorder(
          lobes: 3,
          amplitude: 0.13,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.9,
          scaleY: 0.94,
        );
      case _PinShapeKind.square:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        );
      case _PinShapeKind.pentagon:
        return const _OrganicBlobBorder(
          lobes: 5,
          amplitude: 0.06,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.9,
          scaleY: 0.9,
        );
      case _PinShapeKind.diamond:
        return const _OrganicBlobBorder(
          lobes: 4,
          amplitude: 0.035,
          secondaryAmplitude: 0.0,
          rotation: math.pi / 4,
          scaleX: 0.84,
          scaleY: 0.98,
        );
      case _PinShapeKind.verySunny:
        return const _OrganicBlobBorder(
          lobes: 8,
          amplitude: 0.055,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.9,
          scaleY: 0.9,
        );
      case _PinShapeKind.ghostish:
        return const _OrganicBlobBorder(
          lobes: 1,
          amplitude: 0.11,
          secondaryAmplitude: 0.0,
          rotation: math.pi / 2,
          scaleX: 0.9,
          scaleY: 1.02,
        );
      case null:
        return const CircleBorder();
    }
  }

  ShapeBorder _midShape() {
    switch (shapeKind) {
      case _PinShapeKind.clover:
        return const _OrganicBlobBorder(
          lobes: 4,
          amplitude: 0.07,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.94,
          scaleY: 0.94,
        );
      case _PinShapeKind.arrow:
        return const _OrganicBlobBorder(
          lobes: 3,
          amplitude: 0.07,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.94,
          scaleY: 0.95,
        );
      case _PinShapeKind.square:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        );
      case _PinShapeKind.pentagon:
        return const _OrganicBlobBorder(
          lobes: 5,
          amplitude: 0.04,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.95,
          scaleY: 0.95,
        );
      case _PinShapeKind.diamond:
        return const _OrganicBlobBorder(
          lobes: 4,
          amplitude: 0.02,
          secondaryAmplitude: 0.0,
          rotation: math.pi / 4,
          scaleX: 0.9,
          scaleY: 1.0,
        );
      case _PinShapeKind.verySunny:
        return const _OrganicBlobBorder(
          lobes: 8,
          amplitude: 0.03,
          secondaryAmplitude: 0.0,
          rotation: 0.0,
          scaleX: 0.95,
          scaleY: 0.95,
        );
      case _PinShapeKind.ghostish:
        return const _OrganicBlobBorder(
          lobes: 1,
          amplitude: 0.07,
          secondaryAmplitude: 0.0,
          rotation: math.pi / 2,
          scaleX: 0.95,
          scaleY: 1.02,
        );
      case null:
        return const CircleBorder();
    }
  }

  ShapeBorder _settledShape() {
    return const CircleBorder();
  }

  ShapeBorder _shapeAt(double t) {
    if (t < 0.56) {
      return _startShape();
    }
    if (t < 0.84) {
      final local = AppMotion.emphasizedDecelerate
          .transform(((t - 0.56) / 0.28).clamp(0.0, 1.0));
      return ShapeBorder.lerp(_startShape(), _midShape(), local)!;
    }
    final local = AppMotion.emphasizedDecelerate
        .transform(((t - 0.84) / 0.16).clamp(0.0, 1.0));
    return ShapeBorder.lerp(_midShape(), _settledShape(), local)!;
  }

  double _sizeAt(double t) {
    if (t < 0.18) {
      final local =
          AppMotion.emphasizedDecelerate.transform((t / 0.18).clamp(0.0, 1.0));
      return 20.0 + (18.0 * local);
    }
    if (t < 0.56) {
      final local = AppMotion.emphasizedDecelerate
          .transform(((t - 0.18) / 0.38).clamp(0.0, 1.0));
      return 38.0 - (2.0 * local);
    }
    final local = AppMotion.emphasizedDecelerate
        .transform(((t - 0.56) / 0.44).clamp(0.0, 1.0));
    return 34.0 - (14.0 * local);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!filled && motion != _PinGlyphMotion.delete) {
      return const SizedBox(width: 40, height: 40);
    }

    if (motion == _PinGlyphMotion.none) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: _GlyphSurface(
            shape: CircleBorder(),
            color: null,
            size: 20,
          ),
        ),
      );
    }

    if (motion == _PinGlyphMotion.delete) {
      return TweenAnimationBuilder<double>(
        key: ValueKey<String>('glyph-delete-$variant-$animateTick'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 340),
        curve: AppMotion.standardAccelerate,
        builder: (context, value, _) {
          final eased = AppMotion.standardAccelerate.transform(value);
          final size = 20.0 - (12.0 * eased);
          return SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Opacity(
                opacity: 1 - eased,
                child: Transform.rotate(
                  angle: 0.18 * eased,
                  child: _GlyphSurface(
                    shape: ShapeBorder.lerp(
                      _settledShape(),
                      _midShape(),
                      eased,
                    )!,
                    color: scheme.primary,
                    size: size,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('glyph-$variant-$animateTick'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2760),
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, value, _) {
        final eased = AppMotion.emphasizedDecelerate.transform(value);
        final size = _sizeAt(value);
        return SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Transform.rotate(
              angle: 0,
              child: Transform.scale(
                scale: 1.08 - (0.08 * eased),
                child: _GlyphSurface(
                  shape: _shapeAt(value),
                  color: scheme.primary,
                  size: size,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlyphSurface extends StatelessWidget {
  const _GlyphSurface({
    required this.shape,
    required this.color,
    this.size = 20,
  });

  final ShapeBorder shape;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color ?? Theme.of(context).colorScheme.primary,
          shape: shape,
        ),
      ),
    );
  }
}

class _OrganicBlobBorder extends OutlinedBorder {
  const _OrganicBlobBorder({
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
    return _OrganicBlobBorder(
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
    if (a is _OrganicBlobBorder) {
      return _OrganicBlobBorder(
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
    if (b is _OrganicBlobBorder) {
      return _OrganicBlobBorder(
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
  _OrganicBlobBorder copyWith({
    BorderSide? side,
  }) {
    return _OrganicBlobBorder(
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

class _PinKeypadRow extends StatelessWidget {
  const _PinKeypadRow({
    required this.digits,
  });

  final List<String> digits;

  @override
  Widget build(BuildContext context) {
    final editor = context.findAncestorStateOfType<_PinCodeEditorState>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (digit) => _PinDigitButton(
              label: digit,
              onTap: () => editor._appendDigit(digit),
              enabled: !editor.widget.busy,
            ),
          )
          .toList(),
    );
  }
}

class _PinDigitButton extends StatefulWidget {
  const _PinDigitButton({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_PinDigitButton> createState() => _PinDigitButtonState();
}

class _PinDigitButtonState extends State<_PinDigitButton> {
  bool _pressed = false;

  void _press() {
    if (!_pressed) {
      setState(() => _pressed = true);
    }
  }

  void _release() {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idleColor = scheme.surfaceContainerHigh.withValues(alpha: 0.78);
    final pressedColor = scheme.secondaryContainer.withValues(alpha: 0.78);
    final foreground = scheme.onSurface;
    final overlayColor = scheme.secondaryContainer.withValues(alpha: 0.22);
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _press() : null,
      onTapUp: widget.enabled ? (_) => _release() : null,
      onTapCancel: widget.enabled
          ? () {
              _release();
            }
          : null,
      onTap: widget.enabled
          ? () {
              widget.onTap();
              _release();
            }
          : null,
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 960),
        curve: _pressed ? AppMotion.standardDecelerate : Curves.easeOutCubic,
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: widget.enabled
              ? (_pressed ? pressedColor : idleColor)
              : idleColor.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(_pressed ? 28 : 999),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: _pressed
                  ? const Duration(milliseconds: 90)
                  : const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              opacity: _pressed ? 1 : 0,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: widget.enabled
                        ? foreground
                        : foreground.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinActionButton extends StatefulWidget {
  const _PinActionButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
    this.emphasized = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool emphasized;

  @override
  State<_PinActionButton> createState() => _PinActionButtonState();
}

class _PinActionButtonState extends State<_PinActionButton> {
  bool _pressed = false;

  void _press() {
    if (!_pressed) {
      setState(() => _pressed = true);
    }
  }

  void _release() {
    if (_pressed) {
      setState(() => _pressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idleColor = widget.emphasized
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh.withValues(alpha: 0.78);
    final pressedColor = widget.emphasized
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.18),
            scheme.primaryContainer,
          )
        : scheme.secondaryContainer.withValues(alpha: 0.82);
    final foreground =
        widget.emphasized ? scheme.onPrimaryContainer : scheme.onSurface;
    final overlayColor = widget.emphasized
        ? scheme.onPrimaryContainer.withValues(alpha: 0.08)
        : scheme.secondaryContainer.withValues(alpha: 0.22);
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _press() : null,
      onTapUp: widget.enabled ? (_) => _release() : null,
      onTapCancel: widget.enabled
          ? () {
              _release();
            }
          : null,
      onTap: widget.enabled
          ? () {
              widget.onTap();
              _release();
            }
          : null,
      child: AnimatedContainer(
        duration: _pressed
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 960),
        curve: _pressed ? AppMotion.standardDecelerate : Curves.easeOutCubic,
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: widget.enabled
              ? (_pressed ? pressedColor : idleColor)
              : idleColor.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(_pressed ? 28 : 999),
          border: Border.all(
            color: widget.emphasized
                ? scheme.outlineVariant.withValues(alpha: 0.28)
                : Colors.transparent,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: _pressed
                  ? const Duration(milliseconds: 90)
                  : const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              opacity: _pressed ? 1 : 0,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
            Icon(
              widget.icon,
              color: widget.enabled
                  ? foreground
                  : foreground.withValues(alpha: 0.35),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
