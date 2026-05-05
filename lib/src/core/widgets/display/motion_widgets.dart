import '../../theme/app_motion.dart';
import 'package:flutter/material.dart';

class SmoothAppear extends StatelessWidget {
  const SmoothAppear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 16),
    this.duration = AppMotion.medium,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: AppMotion.emphasizedDecelerate,
      builder: (context, value, animatedChild) {
        final double delayedValue = delay == Duration.zero
            ? value
            : ((value * (duration + delay).inMilliseconds) -
                        delay.inMilliseconds)
                    .clamp(0, duration.inMilliseconds)
                    .toDouble() /
                duration.inMilliseconds;

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: Offset(
                offset.dx * (1 - delayedValue), offset.dy * (1 - delayedValue)),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

class SoftReveal extends StatelessWidget {
  const SoftReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 12),
    this.duration = AppMotion.medium,
    this.beginScale = 0.985,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final Duration duration;
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: AppMotion.emphasized,
      builder: (context, value, animatedChild) {
        final double delayedValue = delay == Duration.zero
            ? value
            : ((value * (duration + delay).inMilliseconds) -
                        delay.inMilliseconds)
                    .clamp(0, duration.inMilliseconds)
                    .toDouble() /
                duration.inMilliseconds;
        final eased = AppMotion.emphasizedDecelerate.transform(delayedValue);
        final scale = beginScale + ((1 - beginScale) * eased);

        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - eased),
              offset.dy * (1 - eased),
            ),
            child: Transform.scale(
              scale: scale,
              child: animatedChild,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 24,
    this.splashColor = const Color(0x33212121),
    this.highlightColor = const Color(0x14212121),
    this.scale = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color splashColor;
  final Color highlightColor;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? widget.scale : 1,
      duration: AppMotion.fast,
      curve: AppMotion.smooth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  splashColor: widget.splashColor,
                  highlightColor: widget.highlightColor,
                  onTapDown: (_) => setState(() => pressed = true),
                  onTapCancel: () => setState(() => pressed = false),
                  onTapUp: (_) => setState(() => pressed = false),
                  onTap: widget.onTap,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
