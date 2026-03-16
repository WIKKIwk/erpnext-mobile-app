import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.actions,
    this.bottom,
    this.contentPadding = const EdgeInsets.fromLTRB(4, 0, 6, 0),
    this.bottomPadding = const EdgeInsets.fromLTRB(20, 0, 24, 0),
    this.animateOnEnter = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final EdgeInsets contentPadding;
  final EdgeInsets bottomPadding;
  final bool animateOnEnter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: bottomPadding,
                child: bottom!,
              ),
            ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.shellStart(context),
        ),
        child: SafeArea(
          bottom: false,
          child: _buildAnimatedContent(theme),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent(ThemeData theme) {
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: contentPadding,
            child: child,
          ),
        ),
      ],
    );

    if (!animateOnEnter) {
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
    required this.onTap,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;

  @override
  State<AppShellIconAction> createState() => _AppShellIconActionState();
}

class _AppShellIconActionState extends State<AppShellIconAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: AppMotion.fast,
      curve: AppMotion.smooth,
      scale: _pressed ? 0.95 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0x33212121),
          highlightColor: const Color(0x14212121),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.smooth,
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppTheme.actionSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder(context)),
            ),
            child: Center(
              child: widget.iconWidget ??
                  Icon(
                    widget.icon,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
