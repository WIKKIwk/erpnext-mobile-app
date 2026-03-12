import '../../features/shared/models/app_models.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _DockDeviceClass {
  small,
  medium,
  large,
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderWidth,
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? borderWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: AppTheme.cardBorder(context),
          width: borderWidth ?? (isDark ? 1.35 : 1),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
  });

  final DispatchStatus status;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final Color background;

    switch (status) {
      case DispatchStatus.draft:
        label = 'Draft';
        color = const Color(0xFF131313);
        background = const Color(0xFFA78BFA);
      case DispatchStatus.pending:
        label = 'Kutilmoqda';
        color = const Color(0xFF1A1A1A);
        background = const Color(0xFFFFD54F);
      case DispatchStatus.accepted:
        label = 'Qabul qilindi';
        color = const Color(0xFFFFFFFF);
        background = const Color(0xFF5BB450);
      case DispatchStatus.partial:
        label = 'Qisman qabul';
        color = const Color(0xFFFFFFFF);
        background = const Color(0xFF2A6FDB);
      case DispatchStatus.rejected:
        label = 'Rad etildi';
        color = const Color(0xFFFFFFFF);
        background = const Color(0xFFC53B30);
      case DispatchStatus.cancelled:
        label = 'Bekor qilindi';
        color = const Color(0xFFFFFFFF);
        background = const Color(0xFF6B7280);
    }

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: status == DispatchStatus.accepted ||
                  status == DispatchStatus.draft
              ? Colors.transparent
              : const Color(0x33000000),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class MetricBadge extends StatelessWidget {
  const MetricBadge({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class ActionDock extends StatelessWidget {
  const ActionDock({
    super.key,
    required this.leading,
    required this.trailing,
    required this.center,
    this.compact = false,
    this.tightToEdges = false,
  });

  final List<Widget> leading;
  final List<Widget> trailing;
  final Widget center;
  final bool compact;
  final bool tightToEdges;

  double _hostHeightForDevice(_DockDeviceClass deviceClass) {
    final double base = switch (deviceClass) {
      _DockDeviceClass.small => 72.0,
      _DockDeviceClass.medium => 76.0,
      _DockDeviceClass.large => 78.0,
    };
    return compact ? base - 6.0 : base;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final _DockDeviceClass deviceClass = width <= 375
        ? _DockDeviceClass.small
        : width <= 430
            ? _DockDeviceClass.medium
            : _DockDeviceClass.large;
    final List<Widget> buttons = [
      ...leading,
      center,
      ...trailing,
    ];

    final double panelHeight = 10;
    final double hostHeight = _hostHeightForDevice(deviceClass);

    return SizedBox(
      height: hostHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: panelHeight,
              color: AppTheme.cardBackground(context),
            ),
          ),
          Positioned(
            left: tightToEdges ? 4 : 0,
            right: tightToEdges ? 4 : 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: tightToEdges
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.spaceEvenly,
              children: buttons
                  .map(
                    (button) => Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: switch (deviceClass) {
                          _DockDeviceClass.small => tightToEdges ? 0 : 1,
                          _DockDeviceClass.medium => tightToEdges ? 1 : 2,
                          _DockDeviceClass.large => tightToEdges ? 1 : 3,
                        },
                      ),
                      child: button,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class DockButton extends StatefulWidget {
  const DockButton({
    super.key,
    this.icon,
    this.iconWidget,
    required this.onTap,
    this.active = false,
    this.primary = false,
    this.onHoldComplete,
    this.holdDuration = const Duration(seconds: 3),
    this.compact = false,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;
  final bool active;
  final bool primary;
  final VoidCallback? onHoldComplete;
  final Duration holdDuration;
  final bool compact;

  @override
  State<DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<DockButton> {
  Timer? _holdTimer;
  bool _holdTriggered = false;

  void _startHold() {
    if (widget.onHoldComplete == null) {
      return;
    }
    _holdTriggered = false;
    _holdTimer?.cancel();
    _holdTimer = Timer(widget.holdDuration, () {
      _holdTriggered = true;
      widget.onHoldComplete?.call();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final _DockDeviceClass deviceClass = width <= 375
        ? _DockDeviceClass.small
        : width <= 430
            ? _DockDeviceClass.medium
            : _DockDeviceClass.large;
    final Color background = widget.primary
        ? AppTheme.primaryButton(context)
        : widget.active
            ? AppTheme.dockActive(context)
            : AppTheme.dockInactive(context);
    final Color foreground = widget.primary
        ? AppTheme.primaryButtonForeground(context)
        : Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      onTap: () {
        if (_holdTriggered) {
          _holdTriggered = false;
          return;
        }
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.smooth,
        height: widget.primary
            ? switch (deviceClass) {
                _DockDeviceClass.small => widget.compact ? 50 : 54,
                _DockDeviceClass.medium => widget.compact ? 53 : 57,
                _DockDeviceClass.large => widget.compact ? 52 : 56,
              }
            : switch (deviceClass) {
                _DockDeviceClass.small => widget.compact ? 42 : 46,
                _DockDeviceClass.medium => widget.compact ? 46 : 50,
                _DockDeviceClass.large => widget.compact ? 46 : 50,
              },
        width: widget.primary
            ? switch (deviceClass) {
                _DockDeviceClass.small => widget.compact ? 50 : 54,
                _DockDeviceClass.medium => widget.compact ? 53 : 57,
                _DockDeviceClass.large => widget.compact ? 52 : 56,
              }
            : switch (deviceClass) {
                _DockDeviceClass.small => widget.compact ? 42 : 46,
                _DockDeviceClass.medium => widget.compact ? 46 : 50,
                _DockDeviceClass.large => widget.compact ? 46 : 50,
              },
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.primary ? background : AppTheme.cardBorder(context),
            width: widget.primary ? 2 : 1.2,
          ),
          boxShadow: widget.primary
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppTheme.isDark(context)
                        ? const Color(0x22000000)
                        : const Color(0x12000000),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Center(
          child: widget.iconWidget ??
              Icon(
                widget.icon,
                color: foreground,
                size: widget.primary
                    ? switch (deviceClass) {
                        _DockDeviceClass.small => 24,
                        _DockDeviceClass.medium => 25,
                        _DockDeviceClass.large => 25,
                      }
                    : switch (deviceClass) {
                        _DockDeviceClass.small => 22,
                        _DockDeviceClass.medium => 23,
                        _DockDeviceClass.large => 23,
                      },
              ),
        ),
      ),
    );
  }
}

class DockSvgIcon extends StatelessWidget {
  const DockSvgIcon({
    super.key,
    required this.fillAsset,
    required this.lineAsset,
    required this.primary,
    this.size,
  });

  final String fillAsset;
  final String lineAsset;
  final bool primary;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final bool dark = AppTheme.isDark(context);
    final String asset = dark ? lineAsset : fillAsset;
    final Color color = primary
        ? AppTheme.primaryButtonForeground(context)
        : Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      asset,
      width: size ?? (primary ? 26 : 25),
      height: size ?? (primary ? 26 : 25),
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
