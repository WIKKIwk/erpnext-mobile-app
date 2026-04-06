import '../../../core/api/mobile_api.dart';
import '../../../core/app_preview.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  static const String _welcomeSeenKey = 'welcome_screen_seen';

  bool _booting = true;
  bool _showLogin = false;
  bool _showWelcome = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (!AppSession.instance.isLoggedIn) {
      if (AppPreview.hasPreviewLoginCredentials) {
        try {
          await MobileApi.instance
              .login(
                phone: AppPreview.previewPhone,
                code: AppPreview.previewCode,
              )
              .timeout(const Duration(seconds: 6));
        } catch (_) {}
      }
    }

    if (!AppSession.instance.isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final bool welcomeSeen = prefs.getBool(_welcomeSeenKey) ?? false;
      if (!mounted) {
        return;
      }
      setState(() {
        _booting = false;
        _showWelcome = !welcomeSeen;
        _showLogin = welcomeSeen;
      });
      return;
    }

    try {
      await MobileApi.instance.profile().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Keep existing local session on transient network/backend failures.
    }

    if (!mounted) {
      return;
    }

    if (!AppSession.instance.isLoggedIn) {
      setState(() {
        _booting = false;
        _showWelcome = false;
        _showLogin = true;
      });
      return;
    }

    _navigated = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppPreview.initialRouteOverride ?? AppSession.instance.homeRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return WelcomeScreen(
        onGetStarted: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_welcomeSeenKey, true);
          if (!mounted) {
            return;
          }
          setState(() {
            _showWelcome = false;
            _showLogin = true;
          });
        },
      );
    }

    if (_showLogin) {
      return const LoginScreen();
    }

    return AppShell(
      title: 'Accord',
      subtitle: '',
      child: Center(
        child: _navigated
            ? const SizedBox.shrink()
            : _booting
                ? const AppLoadingIndicator()
                : const SizedBox.shrink(),
      ),
    );
  }
}
