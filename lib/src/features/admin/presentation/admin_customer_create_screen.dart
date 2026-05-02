import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminCustomerCreateScreen extends StatefulWidget {
  const AdminCustomerCreateScreen({super.key});

  @override
  State<AdminCustomerCreateScreen> createState() =>
      _AdminCustomerCreateScreenState();
}

class _AdminCustomerCreateScreenState extends State<AdminCustomerCreateScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => saving = true);
    try {
      await MobileApi.instance.adminCreateCustomer(
        name: name.text.trim(),
        phone: phone.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Customer qo‘shish',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Customer name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            decoration: const InputDecoration(labelText: 'Customer phone'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : _create,
              child: Text(saving ? 'Qo‘shilmoqda...' : 'Customer qo‘shish'),
            ),
          ),
        ],
      ),
    );
  }
}
