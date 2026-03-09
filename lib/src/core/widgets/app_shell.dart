import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

enum _DockDeviceClass {
  small,
  medium,
  large,
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.actions,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final _DockDeviceClass deviceClass = width <= 375
        ? _DockDeviceClass.small
        : width <= 430
            ? _DockDeviceClass.medium
            : _DockDeviceClass.large;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.shellStart(context),
              AppTheme.shellEnd(context),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
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
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: AppMotion.slow,
                            curve: AppMotion.settle,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 12 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(title,
                                style: theme.textTheme.headlineMedium),
                          ),
                          if (subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 460),
                              curve: AppMotion.settle,
                              builder: (context, value, child) {
                                return Opacity(opacity: value, child: child);
                              },
                              child: Text(subtitle,
                                  style: theme.textTheme.bodyMedium),
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
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    24,
                    bottom != null ? 0 : 20,
                  ),
                  child: child,
                ),
              ),
              if (bottom != null)
                Container(
                  width: double.infinity,
                  color: theme.scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        switch (deviceClass) {
                          _DockDeviceClass.small => -2,
                          _DockDeviceClass.medium => 7,
                          _DockDeviceClass.large => 12,
                        },
                      ),
                      child: bottom,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppShellIconAction extends StatelessWidget {
  const AppShellIconAction({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
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
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
