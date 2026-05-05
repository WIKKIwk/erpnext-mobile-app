import '../api/mobile_api.dart';
import '../session/session.dart';
import 'network_required_dialog.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class NetworkRequirementRuntime extends StatefulWidget {
  const NetworkRequirementRuntime({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<NetworkRequirementRuntime> createState() =>
      _NetworkRequirementRuntimeState();
}

class _NetworkRequirementRuntimeState extends State<NetworkRequirementRuntime>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBackend());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBackend();
    }
  }

  Future<void> _checkBackend() async {
    if (_checking || !AppSession.instance.isLoggedIn) {
      return;
    }
    _checking = true;
    try {
      final response = await http
          .get(Uri.parse('${MobileApi.baseUrl}/healthz'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return;
      }
      await _showOfflineMessage();
    } catch (_) {
      await _showOfflineMessage();
    } finally {
      _checking = false;
    }
  }

  Future<void> _showOfflineMessage() async {
    if (!mounted || _dialogOpen) {
      return;
    }
    _dialogOpen = true;
    await showNetworkRequiredDialog(
      context,
      message:
          'Siz offline modedasiz. Dastur ma’lumotlarini yangilab olishi uchun iltimos internetga ulaning.',
    );
    _dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
