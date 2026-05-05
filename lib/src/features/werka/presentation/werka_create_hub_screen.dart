import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaCreateHubScreen extends StatelessWidget {
  const WerkaCreateHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppShell(
      title: l10n.createHubTitle,
      subtitle: '',
      bottom: const WerkaDock(activeTab: WerkaDockTab.create),
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Card.filled(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  _CreateHubRow(
                    title: l10n.unannouncedTitle,
                    description: l10n.unannouncedDescription,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.werkaUnannouncedSupplier,
                    ),
                    isFirst: true,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 18,
                    endIndent: 18,
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                  _CreateHubRow(
                    title: l10n.customerIssueTitle,
                    description: l10n.customerIssueDescription,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.werkaCustomerIssueCustomer,
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 18,
                    endIndent: 18,
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                  _CreateHubRow(
                    title: l10n.batchDispatchTitle,
                    description: l10n.batchDispatchDescription,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.werkaBatchDispatch,
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateHubRow extends StatelessWidget {
  const _CreateHubRow({
    required this.title,
    required this.description,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 28 : 0),
      topRight: Radius.circular(isFirst ? 28 : 0),
      bottomLeft: Radius.circular(isLast ? 28 : 0),
      bottomRight: Radius.circular(isLast ? 28 : 0),
    );
    return PressableScale(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.smooth,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
