import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminSupplierCreateScreen extends StatefulWidget {
  const AdminSupplierCreateScreen({super.key});

  @override
  State<AdminSupplierCreateScreen> createState() =>
      _AdminSupplierCreateScreenState();
}

class _AdminSupplierCreateScreenState extends State<AdminSupplierCreateScreen> {
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
      await MobileApi.instance.adminCreateSupplier(
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
      title: 'Supplier qo‘shish',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.suppliers),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Supplier name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            decoration: const InputDecoration(labelText: 'Supplier phone'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : _create,
              child: Text(saving ? 'Qo‘shilmoqda...' : 'Supplier qo‘shish'),
            ),
          ),
        ],
      ),
    );
  }
}
