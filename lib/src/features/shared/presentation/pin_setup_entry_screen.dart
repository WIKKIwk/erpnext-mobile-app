import '../../../app/app_router.dart';
import 'pin_setup_confirm_screen.dart';
import 'widgets/pin_entry_scaffold.dart';
import 'package:flutter/material.dart';

class PinSetupEntryScreen extends StatefulWidget {
  const PinSetupEntryScreen({super.key});

  @override
  State<PinSetupEntryScreen> createState() => _PinSetupEntryScreenState();
}

class _PinSetupEntryScreenState extends State<PinSetupEntryScreen> {
  String _pin = '';

  Future<void> _handleDigit(String digit) async {
    if (_pin.length >= 4) {
      return;
    }
    setState(() {
      _pin = '$_pin$digit';
    });
    if (_pin.length == 4) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) {
        return;
      }
      final result = await Navigator.of(context).pushNamed(
        AppRoutes.pinSetupConfirm,
        arguments: PinSetupConfirmArgs(firstPin: _pin),
      );
      if (!mounted) {
        return;
      }
      if (result == true) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _pin = '';
        });
      }
    }
  }

  void _handleBackspace() {
    if (_pin.isEmpty) {
      return;
    }
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'PIN kiriting',
      subtitle: 'App uchun 4 xonali PIN kod yarating.',
      length: _pin.length,
      onDigit: _handleDigit,
      onBackspace: _handleBackspace,
    );
  }
}
