import '../../../core/security/state/security_controller.dart';
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
  final TextEditingController _pinController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_saving) {
      return;
    }
    final pin = _pinController.text.trim();
    setState(() {
      _error = null;
    });
    if (pin != widget.args.firstPin) {
      setState(() {
        _pinController.clear();
        _error = 'PIN bir xil emas. Qayta kiriting.';
      });
      return;
    }
    setState(() => _saving = true);
    try {
      await SecurityController.instance.savePinForCurrentUser(pin);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pinController.clear();
        _error = 'PIN saqlanmadi';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'PIN takrorlang',
      subtitle: '',
      controller: _pinController,
      actionLabel: 'Saqlash',
      onAction: _handleConfirm,
      errorText: _error,
      busy: _saving,
    );
  }
}
