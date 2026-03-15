import 'dart:async';

import '../theme/app_motion.dart';
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
  int _animateTick = 0;
  int? _animatedIndex;
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
      _animateTick += 1;
      _animatedIndex = value.length - 1;
    } else if (value.length < _lastValue.length) {
      _animatedIndex = null;
    }
    _lastValue = value;
    if (mounted) {
      setState(() {});
    }
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
            animatedIndex: _animatedIndex,
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
    required this.animatedIndex,
    required this.animateTick,
  });

  final int length;
  final int? animatedIndex;
  final int animateTick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(4, (index) {
        final filled = index < length;
        final animate = filled && animatedIndex == index;
        return Padding(
          padding: EdgeInsets.only(right: index == 3 ? 0 : 12),
          child: _PinGlyph(
            filled: filled,
            animate: animate,
            animateTick: animateTick,
            variant: index,
          ),
        );
      }),
    );
  }
}

class _PinGlyph extends StatelessWidget {
  const _PinGlyph({
    required this.filled,
    required this.animate,
    required this.animateTick,
    required this.variant,
  });

  final bool filled;
  final bool animate;
  final int animateTick;
  final int variant;

  ShapeBorder _polygonShape() {
    switch (variant % 3) {
      case 0:
        return const StarBorder.polygon(sides: 5);
      case 1:
        return const StarBorder.polygon(sides: 6);
      default:
        return const StarBorder.polygon(sides: 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!filled) {
      return const SizedBox(width: 20, height: 20);
    }

    if (!animate) {
      return _GlyphSurface(
        shape: const CircleBorder(),
        color: scheme.onSurface,
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('glyph-$variant-$animateTick'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 760),
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, value, _) {
        final polygonOpacity = (1 - (value * 1.1)).clamp(0.0, 1.0);
        final circleOpacity = ((value - 0.34) / 0.66).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: polygonOpacity,
              child: Transform.scale(
                scale: 1.6 - (0.72 * value),
                child: _GlyphSurface(
                  shape: _polygonShape(),
                  color: scheme.onSurface,
                ),
              ),
            ),
            Opacity(
              opacity: circleOpacity,
              child: Transform.scale(
                scale: 0.72 + (0.28 * value),
                child: _GlyphSurface(
                  shape: const CircleBorder(),
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlyphSurface extends StatelessWidget {
  const _GlyphSurface({
    required this.shape,
    required this.color,
  });

  final ShapeBorder shape;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shape: shape,
        ),
      ),
    );
  }
}

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
  Timer? _releaseTimer;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  void _press() {
    _releaseTimer?.cancel();
    if (!_pressed) {
      setState(() => _pressed = true);
    }
  }

  void _releaseSoon() {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() => _pressed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idleColor = scheme.surfaceContainerHighest.withValues(alpha: 0.58);
    final pressedColor = scheme.secondaryContainer.withValues(alpha: 0.78);
    final foreground = scheme.onSurface;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _press() : null,
      onTapUp: widget.enabled ? (_) => _releaseSoon() : null,
      onTapCancel: widget.enabled
          ? () {
              _releaseTimer?.cancel();
              setState(() => _pressed = false);
            }
          : null,
      onTap: widget.enabled
          ? () {
              widget.onTap();
              _releaseSoon();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        curve: AppMotion.emphasizedDecelerate,
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: widget.enabled
              ? (_pressed ? pressedColor : idleColor)
              : idleColor.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(_pressed ? 20 : 999),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: widget.enabled
                    ? foreground
                    : foreground.withValues(alpha: 0.35),
                fontWeight: FontWeight.w500,
              ),
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
  Timer? _releaseTimer;

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  void _press() {
    _releaseTimer?.cancel();
    if (!_pressed) {
      setState(() => _pressed = true);
    }
  }

  void _releaseSoon() {
    _releaseTimer?.cancel();
    _releaseTimer = Timer(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() => _pressed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idleColor = widget.emphasized
        ? scheme.primary.withValues(alpha: 0.82)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.58);
    final pressedColor = widget.emphasized
        ? scheme.primary.withValues(alpha: 0.96)
        : scheme.secondaryContainer.withValues(alpha: 0.82);
    final foreground = widget.emphasized ? scheme.onPrimary : scheme.onSurface;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _press() : null,
      onTapUp: widget.enabled ? (_) => _releaseSoon() : null,
      onTapCancel: widget.enabled
          ? () {
              _releaseTimer?.cancel();
              setState(() => _pressed = false);
            }
          : null,
      onTap: widget.enabled
          ? () {
              widget.onTap();
              _releaseSoon();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 340),
        curve: AppMotion.emphasizedDecelerate,
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: widget.enabled
              ? (_pressed ? pressedColor : idleColor)
              : idleColor.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(_pressed ? 20 : 999),
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          color:
              widget.enabled ? foreground : foreground.withValues(alpha: 0.35),
          size: 28,
        ),
      ),
    );
  }
}
