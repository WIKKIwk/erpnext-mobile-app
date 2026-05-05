import '../../native_back_button_bridge.dart';
import '../../theme/app_theme.dart';
import '../display/shared_header_title.dart';
import 'package:flutter/material.dart';

bool useNativeBackButton(BuildContext context) {
  return NativeBackButtonBridge.shouldUseNativeBackButton(context);
}

bool useNativeNavigationTitle(BuildContext context, String title) {
  return NativeBackButtonBridge.useNativeNavigationTitle(context, title);
}

class NativeNavigationTitleHeader extends StatelessWidget {
  const NativeNavigationTitleHeader({
    super.key,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
  });

  final String title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final showFlutterBackButton = !useNativeNavigationTitle(context, title);
    if (!showFlutterBackButton) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderLeadingTransition(
            child: NativeBackButtonSlot(
              filledTonal: true,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SharedHeaderTitle(
              title: title,
            ),
          ),
        ],
      ),
    );
  }
}

class NativeBackButtonSlot extends StatelessWidget {
  const NativeBackButtonSlot({
    super.key,
    required this.onPressed,
    this.iconSize = AppTheme.headerActionIconSize,

    /// `true` — in-shell sarlavha uchun eski **filled tonal** chip; `false` (default) — [AppBar.leading] uchun fon doirasiz.
    this.filledTonal = false,
  });

  final VoidCallback onPressed;
  final double iconSize;
  final bool filledTonal;

  @override
  Widget build(BuildContext context) {
    if (useNativeBackButton(context)) {
      return const SizedBox.shrink();
    }

    if (filledTonal) {
      return SizedBox(
        height: AppTheme.headerActionSize,
        width: AppTheme.headerActionSize,
        child: IconButton.filledTonal(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
          icon: Icon(Icons.arrow_back_rounded, size: iconSize),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(40, 40),
        fixedSize: const Size(40, 40),
      ),
      icon: Icon(Icons.arrow_back_rounded, size: iconSize),
    );
  }
}
