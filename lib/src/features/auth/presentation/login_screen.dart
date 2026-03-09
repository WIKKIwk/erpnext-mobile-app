import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String lastCodeKey = 'last_login_code';
  static const String lastPhoneKey = 'last_login_phone';

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode codeFocusNode = FocusNode();
  String? errorText;
  bool loading = false;
  String? rememberedCode;
  String? rememberedPhone;

  @override
  void initState() {
    super.initState();
    loadRememberedCode();
  }

  Future<void> loadRememberedCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(lastCodeKey);
    final savedPhone = prefs.getString(lastPhoneKey);
    if (!mounted) {
      return;
    }
    setState(() {
      rememberedCode = savedCode;
      rememberedPhone = savedPhone;
      if (phoneController.text.trim().isEmpty &&
          savedPhone != null &&
          savedPhone.isNotEmpty) {
        phoneController.text = savedPhone;
      }
      if (codeController.text.trim().isEmpty &&
          savedCode != null &&
          savedCode.isNotEmpty) {
        codeController.text = savedCode;
      }
    });
  }

  Future<void> persistRememberedCode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(lastCodeKey);
      if (!mounted) {
        return;
      }
      setState(() {
        rememberedCode = null;
      });
      return;
    }

    await prefs.setString(lastCodeKey, trimmed);
    if (!mounted) {
      return;
    }
    setState(() {
      rememberedCode = trimmed;
    });
  }

  Future<void> persistRememberedPhone(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(lastPhoneKey);
      if (!mounted) {
        return;
      }
      setState(() {
        rememberedPhone = null;
      });
      return;
    }

    await prefs.setString(lastPhoneKey, trimmed);
    if (!mounted) {
      return;
    }
    setState(() {
      rememberedPhone = trimmed;
    });
  }

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
      SharedPreferences.getInstance().then((prefs) {
        prefs
          ..setString(lastCodeKey, code)
          ..setString(lastPhoneKey, phone);
      });
      final String route = profile.role == UserRole.supplier
          ? AppRoutes.supplierHome
          : AppRoutes.werkaHome;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    }).catchError((_) {
      if (!context.mounted) {
        return;
      }
      setState(() {
        errorText = 'Login muvaffaqiyatsiz';
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Login',
      subtitle: '',
      bottom: ElevatedButton(
        onPressed: loading ? null : () => submitLogin(context),
        child: Text(loading ? 'Kuting...' : 'Login'),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AutofillGroup(
                        child: Column(
                          children: [
                            SmoothAppear(
                              delay: const Duration(milliseconds: 30),
                              child: TextField(
                                controller: phoneController,
                                focusNode: phoneFocusNode,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.phone,
                                autocorrect: false,
                                enableSuggestions: true,
                                autofillHints: const [AutofillHints.telephoneNumber],
                                onChanged: persistRememberedPhone,
                                onSubmitted: (_) => codeFocusNode.requestFocus(),
                                decoration: const InputDecoration(
                                  labelText: 'Telefon raqam',
                                  hintText: 'Masalan: +998901234567',
                                ),
                              ),
                            ),
                            if (rememberedPhone != null &&
                                rememberedPhone!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SmoothAppear(
                                delay: const Duration(milliseconds: 42),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ActionChip(
                                    label:
                                        Text('Oxirgi telefon: $rememberedPhone'),
                                    onPressed: () {
                                      phoneController.text = rememberedPhone!;
                                      codeFocusNode.requestFocus();
                                    },
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            SmoothAppear(
                              delay: const Duration(milliseconds: 40),
                              child: TextField(
                                controller: codeController,
                                focusNode: codeFocusNode,
                                textInputAction: TextInputAction.done,
                                autocorrect: false,
                                enableSuggestions: true,
                                autofillHints: const [AutofillHints.username],
                                onChanged: persistRememberedCode,
                                onSubmitted: (_) {
                                  if (!loading) {
                                    submitLogin(context);
                                  }
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Code',
                                  hintText: 'Masalan: 10XXXXXXXXXX',
                                ),
                              ),
                            ),
                            if (rememberedCode != null &&
                                rememberedCode!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SmoothAppear(
                                delay: const Duration(milliseconds: 55),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ActionChip(
                                    label: Text('Oxirgi code: $rememberedCode'),
                                    onPressed: () {
                                      codeController.text = rememberedCode!;
                                      codeFocusNode.unfocus();
                                    },
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 14),
                        SmoothAppear(
                          delay: const Duration(milliseconds: 120),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B0B0B),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: const Color(0xFF2A2A2A)),
                            ),
                            child: Text(
                              errorText!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
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
