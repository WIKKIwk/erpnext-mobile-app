import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminItemCreateScreen extends StatefulWidget {
  const AdminItemCreateScreen({super.key});

  @override
  State<AdminItemCreateScreen> createState() => _AdminItemCreateScreenState();
}

class _AdminItemCreateScreenState extends State<AdminItemCreateScreen> {
  final TextEditingController code = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController uom = TextEditingController(text: 'Kg');
  bool saving = false;
  SupplierItem? createdItem;

  @override
  void initState() {
    super.initState();
    _hydrateDefaultUom();
  }

  @override
  void dispose() {
    code.dispose();
    name.dispose();
    uom.dispose();
    super.dispose();
  }

  Future<void> _hydrateDefaultUom() async {
    try {
      final settings = await MobileApi.instance.adminSettings();
      if (!mounted) {
        return;
      }
      final currentValue = uom.text.trim();
      if (currentValue.isEmpty || currentValue == 'Kg') {
        final defaultUom = settings.defaultUom.trim();
        uom.text = defaultUom.isEmpty ? 'Kg' : defaultUom;
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final item = await MobileApi.instance.adminCreateItem(
        code: code.text.trim(),
        name: name.text.trim(),
        uom: uom.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        createdItem = item;
      });
      code.clear();
      name.clear();
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Item qo‘shish',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.settings),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (createdItem != null) ...[
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yaratildi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${createdItem!.name} • ${createdItem!.code}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: code,
            decoration: const InputDecoration(labelText: 'Item code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Item name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: uom,
            decoration: const InputDecoration(labelText: 'UOM'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : _save,
              child: Text(saving ? 'Yaratilmoqda...' : 'Item yaratish'),
            ),
          ),
        ],
      ),
    );
  }
}
