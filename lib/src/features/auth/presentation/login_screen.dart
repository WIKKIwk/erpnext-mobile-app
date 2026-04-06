import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/app_preview.dart';
import '../../../core/network/network_required_dialog.dart';
import '../../../core/notifications/push_messaging_service.dart';
import '../../../core/security/security_controller.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode codeFocusNode = FocusNode();
  String? errorText;
  bool loading = false;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    phoneFocusNode.dispose();
    codeFocusNode.dispose();
    super.dispose();
  }

  void submitLogin(BuildContext context) {
    if (loading) {
      return;
    }
    final String phone = phoneController.text.trim();
    final String code = codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      setState(() => errorText = 'Telefon raqam va code ni kiriting');
      return;
    }
    setState(() {
      errorText = null;
      loading = true;
    });

    MobileApi.instance
        .login(phone: phone, code: code)
        .then((SessionProfile profile) {
      if (!context.mounted) {
        return;
      }
      PushMessagingService.instance.syncCurrentToken();
      SecurityController.instance.unlockAfterLogin();
      final String route = profile.role == UserRole.supplier
          ? AppRoutes.supplierHome
          : profile.role == UserRole.werka
              ? AppRoutes.werkaHome
              : profile.role == UserRole.customer
                  ? AppRoutes.customerHome
                  : AppRoutes.adminHome;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppPreview.initialRouteOverride ?? route,
        (route) => false,
      );
    }).catchError((error) {
      if (!context.mounted) {
        return;
      }
      setState(() {
        errorText = 'Login muvaffaqiyatsiz';
        loading = false;
      });
      final text = '$error';
      if (text.contains('SocketException') ||
          text.contains('ClientException') ||
          text.contains('Failed host lookup') ||
          text.contains('Connection refused') ||
          text.contains('timed out')) {
        showNetworkRequiredDialog(
          context,
          message: 'Iltimos internetga ulaning.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: '',
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double topSpacing = constraints.maxHeight >= 760 ? 12 : 4;
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 396,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, topSpacing, 0, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SmoothAppear(
                        delay: const Duration(milliseconds: 20),
                        offset: const Offset(0, 12),
                        child: Text(
                          'Sign in',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 40,
                            letterSpacing: -1.4,
                            height: 1.02,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SmoothAppear(
                        delay: const Duration(milliseconds: 170),
                        offset: const Offset(0, 12),
                        child: AutofillGroup(
                          child: Column(
                            children: [
                              TextField(
                                controller: phoneController,
                                focusNode: phoneFocusNode,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.phone,
                                autocorrect: false,
                                enableSuggestions: true,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Telefon raqam',
                                  hintText: '+998901234567',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: codeController,
                                focusNode: codeFocusNode,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                enableSuggestions: false,
                                onSubmitted: (_) {
                                  if (!loading) {
                                    submitLogin(context);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Code',
                                  hintText: '10XXXXXXXXXX',
                                  prefixIcon: Icon(Icons.password_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 14),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 210),
                          offset: const Offset(0, 8),
                          child: _LoginErrorBanner(message: errorText!),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SmoothAppear(
                        delay: const Duration(milliseconds: 220),
                        offset: const Offset(0, 10),
                        child: FilledButton(
                          onPressed:
                              loading ? null : () => submitLogin(context),
                          child: loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
