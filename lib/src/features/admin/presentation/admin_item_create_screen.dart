import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/display/common_widgets.dart';
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
  final TextEditingController itemGroup = TextEditingController();
  final TextEditingController uom = TextEditingController(text: 'Kg');
  final Future<List<String>> itemGroupsFuture =
      MobileApi.instance.adminItemGroups();
  bool saving = false;
  bool groupMenuOpen = false;
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
    itemGroup.dispose();
    uom.dispose();
    super.dispose();
  }

  void _toggleGroupMenu(bool open) {
    if (groupMenuOpen == open) {
      return;
    }
    setState(() => groupMenuOpen = open);
  }

  void _selectGroup(String group) {
    if (itemGroup.text.trim() == group) {
      _toggleGroupMenu(false);
      return;
    }
    setState(() {
      itemGroup.text = group;
      groupMenuOpen = false;
    });
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

  void _syncItemGroupSelection(List<String> groups) {
    final current = itemGroup.text.trim();
    if (current.isNotEmpty && groups.contains(current)) {
      return;
    }
    final fallback = groups.contains('All Item Groups')
        ? 'All Item Groups'
        : (groups.isNotEmpty ? groups.first : '');
    if (fallback.isNotEmpty) {
      itemGroup.text = fallback;
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final item = await MobileApi.instance.adminCreateItem(
        code: code.text.trim(),
        name: name.text.trim(),
        uom: uom.text.trim(),
        itemGroup: itemGroup.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        createdItem = item;
      });
      code.clear();
      name.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item yaratildi: ${item.code}')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item yaratilmadi: $error')),
        );
      }
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
          FutureBuilder<List<String>>(
            future: itemGroupsFuture,
            builder: (context, snapshot) {
              final groups = snapshot.data ?? const <String>[];
              if (snapshot.connectionState == ConnectionState.done &&
                  !snapshot.hasError) {
                _syncItemGroupSelection(groups);
              }
              final selectedGroup =
                  itemGroup.text.trim().isEmpty ? null : itemGroup.text.trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Item group',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 6),
                  _TapBox(
                    onTap: snapshot.connectionState == ConnectionState.done &&
                            !snapshot.hasError &&
                            !saving
                        ? () => _toggleGroupMenu(!groupMenuOpen)
                        : null,
                    borderRadius: 14,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedGroup ?? 'Group tanlang',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: selectedGroup == null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.expand_more_rounded,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: groupMenuOpen
                        ? Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              borderRadius: BorderRadius.zero,
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                right: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                top: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                                bottom: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                                ),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int index = 0;
                                    index < groups.length;
                                    index++) ...[
                                  if (index > 0)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  Material(
                                    color: groups[index] == selectedGroup
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.55)
                                        : Colors.transparent,
                                    child: InkWell(
                                      onTap: saving
                                          ? null
                                          : () => _selectGroup(groups[index]),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 13,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                groups[index],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface,
                                                    ),
                                              ),
                                            ),
                                            if (groups[index] == selectedGroup)
                                              Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
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

class _TapBox extends StatelessWidget {
  const _TapBox({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
