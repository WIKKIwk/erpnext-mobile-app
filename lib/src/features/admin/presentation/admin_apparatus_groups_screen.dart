import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_navigation_drawer.dart';
import 'widgets/admin_top_notice.dart';
import 'package:flutter/material.dart';

class AdminApparatusGroupsScreen extends StatefulWidget {
  const AdminApparatusGroupsScreen({super.key});

  @override
  State<AdminApparatusGroupsScreen> createState() =>
      _AdminApparatusGroupsScreenState();
}

class _AdminApparatusGroupsScreenState
    extends State<AdminApparatusGroupsScreen> {
  final TextEditingController _name = TextEditingController();
  List<AdminWarehouse> _apparatus = const [];
  List<AdminApparatusGroup> _groups = const [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      MobileApi.instance.adminApparatusGroups(),
      MobileApi.instance.adminWarehouses(parent: 'aparat - A', limit: 200),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _groups = results[0] as List<AdminApparatusGroup>;
      _apparatus = results[1] as List<AdminWarehouse>;
      _loading = false;
    });
  }

  void _editGroup(AdminApparatusGroup group) {
    setState(() {
      _name.text = group.name;
      _selected
        ..clear()
        ..addAll(group.apparatus.map((item) => item.trim()));
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _selected.isEmpty || _saving) {
      showAdminTopNotice(context, 'Guruh nomi va aparatlar kerak');
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await MobileApi.instance.adminSaveApparatusGroup(
        AdminApparatusGroup(
          name: name,
          apparatus: _selected.toList(growable: false),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        final key = saved.name.toLowerCase();
        final next = [
          for (final group in _groups)
            if (group.name.toLowerCase() != key) group,
          saved,
        ]..sort((left, right) => left.name.compareTo(right.name));
        _groups = next;
        _name.clear();
        _selected.clear();
      });
      showAdminTopNotice(context, 'Aparat guruhi saqlandi');
    } catch (_) {
      if (mounted) {
        showAdminTopNotice(context, 'Aparat guruhi saqlanmadi');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 112;
    return AppShell(
      title: 'Aparat guruhlari',
      subtitle: '',
      drawer: AdminNavigationDrawer(
        selectedIndex: 0,
        selectedRouteName: AppRoutes.adminApparatusGroups,
        onNavigate: (route) =>
            Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false),
      ),
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      child: _loading
          ? const Center(child: AppLoadingIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(12, 10, 12, bottomPadding),
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Guruh nomi',
                    hintText: 'pechat',
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in _apparatus)
                  CheckboxListTile(
                    value: _selected.contains(item.warehouse),
                    title: Text(item.warehouse),
                    dense: true,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(item.warehouse);
                        } else {
                          _selected.remove(item.warehouse);
                        }
                      });
                    },
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saqlanmoqda...' : 'Saqlash'),
                ),
                const SizedBox(height: 20),
                for (final group in _groups)
                  ListTile(
                    title: Text(group.name),
                    subtitle: Text('${group.apparatus.length} ta aparat'),
                    trailing: const Icon(Icons.edit_rounded),
                    onTap: () => _editGroup(group),
                  ),
              ],
            ),
    );
  }
}
