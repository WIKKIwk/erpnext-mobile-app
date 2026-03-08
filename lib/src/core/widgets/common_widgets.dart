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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1.35,
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
        background = const Color(0xFF1F8B4C);
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
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF090909),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 1.35),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Wrap(
                  spacing: 10,
                  children: leading,
                ),
                const Spacer(),
                const SizedBox(width: 58),
                const Spacer(),
                Wrap(
                  spacing: 10,
                  children: trailing,
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: center,
          ),
        ],
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
    final Color background = primary
        ? Colors.white
        : active
            ? const Color(0xFF181818)
            : const Color(0xFF101010);
    final Color foreground = primary ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.smooth,
        height: primary ? 62 : 46,
        width: primary ? 62 : 46,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(
            color: primary ? Colors.white : const Color(0xFF2A2A2A),
            width: primary ? 2 : 1.2,
          ),
          boxShadow: primary
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: foreground, size: primary ? 26 : 20),
      ),
    );
  }
}
