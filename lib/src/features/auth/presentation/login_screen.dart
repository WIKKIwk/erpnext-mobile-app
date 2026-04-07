import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/app_preview.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/network/network_required_dialog.dart';
import '../../../core/notifications/push_messaging_service.dart';
import '../../../core/security/security_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'welcome_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onBack,
    this.useSharedBackground = false,
  });

  final VoidCallback? onBack;
  final bool useSharedBackground;

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

  bool get _canSubmit =>
      phoneController.text.trim().isNotEmpty &&
      codeController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_handleInputChanged);
    codeController.addListener(_handleInputChanged);
  }

  void _handleInputChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    phoneController.removeListener(_handleInputChanged);
    codeController.removeListener(_handleInputChanged);
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
    final l10n = AppLocalizations.of(context);
    final String phone = phoneController.text.trim();
    final String code = codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      setState(() => errorText = l10n.loginRequiredFields);
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
      _openPostLoginRoute(
        context,
        AppPreview.initialRouteOverride ?? route,
      );
    }).catchError((error) {
      if (!context.mounted) {
        return;
      }
      setState(() {
        errorText = l10n.loginFailed;
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
          message: l10n.connectInternetPrompt,
        );
      }
    });
  }

  void _openPostLoginRoute(BuildContext context, String routeName) {
    final PageRoute<dynamic> targetRoute = AppRouter.onGenerateRoute(
      RouteSettings(name: routeName),
    ) as PageRoute<dynamic>;

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<dynamic>(
        settings: targetRoute.settings,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          return targetRoute.buildPage(
            context,
            animation,
            secondaryAnimation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final Animation<double> fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final Animation<Offset> lift = Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );
          final Animation<double> scale = Tween<double>(
            begin: 0.992,
            end: 1,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: lift,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final l10n = AppLocalizations.of(context);
        final bool isDark = ThemeController.instance.isDark;
        final Color inputFillColor =
            isDark ? const Color(0xFF000000) : scheme.surface;
        final darkTheme = theme.copyWith(
          colorScheme: scheme.copyWith(
            surface: const Color(0xFF000000),
            surfaceContainerLowest: const Color(0xFF000000),
            surfaceContainerLow: const Color(0xFF000000),
            surfaceContainer: const Color(0xFF000000),
            surfaceContainerHigh: const Color(0xFF000000),
            surfaceContainerHighest: const Color(0xFF000000),
          ),
          scaffoldBackgroundColor: const Color(0xFF000000),
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: inputFillColor,
            labelStyle: theme.inputDecorationTheme.labelStyle?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.82),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.44),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.94),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.primary.withValues(alpha: 0.96),
                width: 1.35,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.94),
                width: 1.0,
              ),
            ),
          ),
        );

        return Theme(
          key: ValueKey<String>('login-${ThemeController.instance.variant}'),
          data: darkTheme,
          child: AppShell(
            title: '',
            subtitle: '',
            backgroundColor: widget.useSharedBackground
                ? Colors.transparent
                : const Color(0xFF000000),
            leading: widget.onBack == null
                ? null
                : IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Stack(
              children: [
                if (!widget.useSharedBackground)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AuthAmbientOutlineBackground(
                        outlineColor: scheme.outlineVariant,
                        accentColor: scheme.primary,
                        backgroundColor: ThemeController.instance.isDark
                            ? const Color(0xFF000000)
                            : scheme.surface,
                        isDarkBackground: ThemeController.instance.isDark,
                      ),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double topSpacing =
                        constraints.maxHeight >= 760 ? 160 : 120;
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SmoothAppear(
                                  delay: const Duration(milliseconds: 20),
                                  offset: const Offset(0, 12),
                                  child: Text(
                                    l10n.signInTitle,
                                    style:
                                        theme.textTheme.displaySmall?.copyWith(
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
                                          decoration: InputDecoration(
                                            labelText: l10n.phoneLabel,
                                            hintText: '+998901234567',
                                            prefixIcon: const Icon(
                                              Icons.phone_outlined,
                                            ),
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
                                          decoration: InputDecoration(
                                            labelText: l10n.codeLabel,
                                            hintText: '10XXXXXXXXXX',
                                            prefixIcon: const Icon(
                                              Icons.password_outlined,
                                            ),
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
                                    child:
                                        _LoginErrorBanner(message: errorText!),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                SmoothAppear(
                                  delay: const Duration(milliseconds: 220),
                                  offset: const Offset(0, 10),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutCubic,
                                    opacity: (_canSubmit || loading) ? 1 : 0,
                                    child: AnimatedSlide(
                                      duration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      offset: (_canSubmit || loading)
                                          ? Offset.zero
                                          : const Offset(0, 0.08),
                                      child: IgnorePointer(
                                        ignoring: !_canSubmit && !loading,
                                        child: FilledButton(
                                          onPressed: loading
                                              ? null
                                              : _canSubmit
                                                  ? () => submitLogin(context)
                                                  : null,
                                          child: loading
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.2,
                                                  ),
                                                )
                                              : Text(l10n.loginAction),
                                        ),
                                      ),
                                    ),
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
              ],
            ),
          ),
        );
      },
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
