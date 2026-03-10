import '../../../core/security/security_controller.dart';
import 'widgets/pin_entry_scaffold.dart';
import 'package:flutter/material.dart';

class PinSetupConfirmArgs {
  const PinSetupConfirmArgs({
    required this.firstPin,
  });

  final String firstPin;
}

class PinSetupConfirmScreen extends StatefulWidget {
  const PinSetupConfirmScreen({
    super.key,
    required this.args,
  });

  final PinSetupConfirmArgs args;

  @override
  State<PinSetupConfirmScreen> createState() => _PinSetupConfirmScreenState();
}

class _PinSetupConfirmScreenState extends State<PinSetupConfirmScreen> {
  String _pin = '';
  String? _error;
  bool _saving = false;

  Future<void> _handleDigit(String digit) async {
    if (_saving || _pin.length >= 4) {
      return;
    }
    setState(() {
      _pin = '$_pin$digit';
      _error = null;
    });
    if (_pin.length == 4) {
      if (_pin != widget.args.firstPin) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) {
          return;
        }
        setState(() {
          _pin = '';
          _error = 'PIN bir xil emas. Qayta kiriting.';
        });
        return;
      }

      setState(() => _saving = true);
      try {
        await SecurityController.instance.savePinForCurrentUser(_pin);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(true);
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _pin = '';
          _error = 'PIN saqlanmadi';
        });
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    }
  }

  void _handleBackspace() {
    if (_saving || _pin.isEmpty) {
      return;
    }
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'PIN takrorlang',
      subtitle: 'Oldingi 4 xonali PIN kodni qayta kiriting.',
      length: _pin.length,
      errorText: _error,
      onDigit: _handleDigit,
      onBackspace: _handleBackspace,
    );
  }
}
