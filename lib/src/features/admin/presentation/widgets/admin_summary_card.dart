import '../../../../core/widgets/m3_segmented_list.dart';
import 'package:flutter/material.dart';

class AdminSummaryCard extends StatelessWidget {
  const AdminSummaryCard({
    super.key,
    required this.slot,
    required this.cornerRadius,
    required this.title,
    required this.value,
    this.onTap,
    this.subtitle,
    this.leading,
    this.showChevron = true,
    this.titleStyle,
    this.subtitleStyle,
    this.valueStyle,
    this.backgroundColor,
    this.borderRadiusOverride,
    this.minHeight,
    this.titleMaxLines = 2,
    this.subtitleMaxLines = 2,
    this.valueMaxLines = 1,
  });

  final M3SegmentVerticalSlot slot;
  final double cornerRadius;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? leading;
  final bool showChevron;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? valueStyle;
  final Color? backgroundColor;
  final BorderRadius? borderRadiusOverride;
  final double? minHeight;
  final int titleMaxLines;
  final int subtitleMaxLines;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final BorderRadius radius = borderRadiusOverride ??
        M3SegmentedListGeometry.borderRadius(slot, cornerRadius);
    final Color bg = backgroundColor ??
        switch (brightness) {
          Brightness.dark => scheme.surfaceContainerLow,
          Brightness.light => scheme.surfaceContainerHighest,
        };
    final bool showValue = value.trim().isNotEmpty;

    final Widget ink = Ink(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight ?? 0,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle ??
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle ??
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.25,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showValue) ...[
                const SizedBox(width: 16),
                Text(
                  value,
                  maxLines: valueMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: valueStyle ??
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                ),
              ],
              if (showChevron) ...[
                SizedBox(width: showValue ? 8 : 16),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: radius, child: ink)
          : ink,
    );
  }
}
