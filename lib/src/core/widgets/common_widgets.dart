import '../../features/shared/models/app_models.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(24),
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
          width: isDark ? 1.35 : 1,
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
  });

  final List<Widget> leading;
  final List<Widget> trailing;
  final Widget center;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool compact = width <= 375;
    final List<Widget> buttons = [
      ...leading,
      center,
      ...trailing,
    ];

    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.dockDivider(context),
            width: 1.2,
          ),
        ),
      ),
      child: Transform.translate(
        offset: const Offset(0, -2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buttons
              .map(
                (button) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 3),
                  child: button,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class DockButton extends StatelessWidget {
  const DockButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.active = false,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final bool compact = width <= 375;
    final Color background = primary
        ? AppTheme.primaryButton(context)
        : active
            ? AppTheme.dockActive(context)
            : AppTheme.dockInactive(context);
    final Color foreground = primary
        ? AppTheme.primaryButtonForeground(context)
        : Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.smooth,
        height: primary
            ? (compact ? 54 : 60)
            : (compact ? 46 : 54),
        width: primary
            ? (compact ? 54 : 60)
            : (compact ? 46 : 54),
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(
            color: primary ? background : AppTheme.cardBorder(context),
            width: primary ? 2 : 1.2,
          ),
          boxShadow: primary
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: foreground,
          size: primary
              ? (compact ? 24 : 27)
              : (compact ? 22 : 25),
        ),
      ),
    );
  }
}
