import '../../localization/app_localizations.dart';
import 'package:flutter/material.dart';

class AppRetryState extends StatelessWidget {
  const AppRetryState({
    super.key,
    required this.onRetry,
    this.padding,
    this.message,
  });

  final Future<void> Function() onRetry;
  final EdgeInsetsGeometry? padding;

  /// Bo‘sh bo‘lsa — umumiy tushuntirish ([AppLocalizations.serverDisconnectedRetry]).
  final String? message;

  static double contentWidthFor(Size screenSize) {
    return (screenSize.width * 0.88).clamp(280.0, 360.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenSize = mediaQuery?.size ?? const Size(390, 844);
    final contentWidth = contentWidthFor(screenSize);
    final resolvedPadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 40);
    final body = message ?? context.l10n.serverDisconnectedRetry;

    return Padding(
      padding: resolvedPadding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
