import '../localization/app_localizations.dart';
import '../security/security_controller.dart';
import '../session/app_session.dart';
import 'm3_confirm_dialog.dart';
import 'package:flutter/material.dart';

Future<void> showLogoutPrompt(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final l10n = context.l10n;
  final confirmed = await showM3ConfirmDialog(
    context: context,
    title: l10n.logoutTitle,
    message: l10n.logoutPrompt,
    cancelLabel: l10n.no,
    confirmLabel: l10n.yes,
    blurBackground: true,
  );
  if (confirmed != true) {
    return;
  }

  await AppSession.instance.clear();
  await SecurityController.instance.clearForLogout();
  if (!navigator.mounted) {
    return;
  }
  navigator.pushNamedAndRemoveUntil('/', (route) => false);
}
