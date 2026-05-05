import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaSuccessScreen extends StatelessWidget {
  const WerkaSuccessScreen({
    super.key,
    required this.record,
    this.returnRouteName,
    this.returnLabel,
  });

  final DispatchRecord record;
  final String? returnRouteName;
  final String? returnLabel;

  static WerkaSuccessScreen fromArgs(WerkaSuccessArgs args) {
    return WerkaSuccessScreen(
      record: args.record,
      returnRouteName: args.returnRouteName,
      returnLabel: args.returnLabel,
    );
  }

  String _title(AppLocalizations l10n) {
    if (record.eventType == 'customer_issue_pending') {
      return l10n.sentSuccess;
    }
    if (record.eventType == 'werka_unannounced_pending') {
      return l10n.createdSuccess;
    }
    return l10n.receivedSuccess;
  }

  String _subtitleLine(AppLocalizations l10n) {
    if (record.eventType == 'customer_issue_pending') {
      return l10n.sentToCustomerLine(record.sentQty, record.uom);
    }
    if (record.eventType == 'werka_unannounced_pending') {
      return l10n.createdLine(record.sentQty, record.uom);
    }
    return l10n.receivedLine(record.acceptedQty, record.uom);
  }

  bool get _returnsToCreateHub {
    return record.eventType == 'customer_issue_pending' ||
        record.eventType == 'werka_unannounced_pending';
  }

  String _ctaLabel(AppLocalizations l10n) {
    return returnLabel ??
        (_returnsToCreateHub ? l10n.createFlowBack : l10n.pendingListBack);
  }

  String get _targetRoute {
    return returnRouteName ??
        (_returnsToCreateHub ? AppRoutes.werkaCreateHub : AppRoutes.werkaHome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppShell(
      title: _title(l10n),
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
      bottom: const WerkaDock(activeTab: null),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 140),
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 88,
                    width: 88,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: 44,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    record.id,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subtitleLine(l10n),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                _targetRoute,
                (route) => route.isFirst,
              ),
              child: Text(_ctaLabel(l10n)),
            ),
          ),
        ],
      ),
    );
  }
}

class WerkaSuccessArgs {
  const WerkaSuccessArgs({
    required this.record,
    this.returnRouteName,
    this.returnLabel,
  });

  final DispatchRecord record;
  final String? returnRouteName;
  final String? returnLabel;
}
