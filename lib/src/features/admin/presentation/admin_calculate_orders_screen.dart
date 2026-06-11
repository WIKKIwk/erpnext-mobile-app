import '../../../app/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../state/calculate_order_store.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_navigation_drawer.dart';
import 'widgets/admin_top_notice.dart';
import 'package:flutter/material.dart';

class AdminCalculateOrdersScreen extends StatefulWidget {
  const AdminCalculateOrdersScreen({super.key});

  @override
  State<AdminCalculateOrdersScreen> createState() =>
      _AdminCalculateOrdersScreenState();
}

class _AdminCalculateOrdersScreenState
    extends State<AdminCalculateOrdersScreen> {
  final _searchController = TextEditingController();
  bool _openingRoute = false;
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await CalculateOrderTemplateStore.instance.load();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
  }

  void _openDrawerRoute(String routeName) {
    if (_openingRoute) {
      return;
    }
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) {
      return;
    }
    _openingRoute = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  void _openTemplate(CalculateOrderTemplate template) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.adminCalculate,
      (route) => false,
      arguments: template,
    );
  }

  Future<void> _deleteTemplate(CalculateOrderTemplate template) async {
    await CalculateOrderTemplateStore.instance.delete(template.id);
    if (!mounted) {
      return;
    }
    showAdminTopNotice(context, 'Zakaz o‘chirildi');
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  List<CalculateOrderTemplate> _visibleTemplates(
    List<CalculateOrderTemplate> templates,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return templates;
    }
    return templates.where((template) {
      final haystack = [
        template.code,
        template.name,
        template.customer,
        template.customerRef,
        template.product,
        template.itemCode,
        template.status,
        template.color,
        template.firstLayerMaterial,
        template.firstLayerMicron,
        template.secondLayerMaterial,
        template.secondLayerMicron,
        template.thirdLayerMaterial,
        template.thirdLayerMicron,
        template.note,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    return AppShell(
      drawer: AdminNavigationDrawer(
        selectedIndex: 0,
        selectedRouteName: AppRoutes.adminCalculateOrders,
        onNavigate: _openDrawerRoute,
      ),
      title: 'Tezkor zakazlar',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      bottomDockFadeStrength: null,
      contentPadding: EdgeInsets.zero,
      child: _loading
          ? const Center(child: AppLoadingIndicator())
          : AnimatedBuilder(
              animation: CalculateOrderTemplateStore.instance,
              builder: (context, _) {
                final templates =
                    CalculateOrderTemplateStore.instance.templates;
                final visibleTemplates = _visibleTemplates(templates);
                return ListView(
                  padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
                  children: [
                    _OrderSearchField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
                    if (templates.isEmpty)
                      const _EmptyOrders(message: 'Saqlangan zakaz yo‘q')
                    else if (visibleTemplates.isEmpty)
                      const _EmptyOrders(message: 'Zakaz topilmadi')
                    else
                      _OrderListModule(
                        templates: visibleTemplates,
                        onTapTemplate: _openTemplate,
                        onDeleteTemplate: _deleteTemplate,
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _OrderSearchField extends StatelessWidget {
  const _OrderSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final hasText = controller.text.trim().isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Zakaz qidirish',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: hasText
                  ? IconButton(
                      tooltip: 'Tozalash',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: scheme.surfaceContainer,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderListModule extends StatelessWidget {
  const _OrderListModule({
    required this.templates,
    required this.onTapTemplate,
    required this.onDeleteTemplate,
  });

  final List<CalculateOrderTemplate> templates;
  final ValueChanged<CalculateOrderTemplate> onTapTemplate;
  final ValueChanged<CalculateOrderTemplate> onDeleteTemplate;

  @override
  Widget build(BuildContext context) {
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (int index = 0; index < templates.length; index++)
          _OrderRow(
            slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
              index,
              templates.length,
            ),
            template: templates[index],
            onTap: () => onTapTemplate(templates[index]),
            onDelete: () => onDeleteTemplate(templates[index]),
          ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.slot,
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  final M3SegmentVerticalSlot slot;
  final CalculateOrderTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = [
      if (template.customer.trim().isNotEmpty) template.customer.trim(),
      if (template.product.trim().isNotEmpty) template.product.trim(),
      if (template.widthMm > 0) '${_fmt(template.widthMm)} mm',
      if (template.wastePercent >= 0) 'Atxod ${_fmt(template.wastePercent)}%',
    ].join(' • ');
    final radius = M3SegmentedListGeometry.borderRadius(
      slot,
      M3SegmentedListGeometry.cornerRadiusForSlot(slot),
    );
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 30,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calculate_outlined,
                    color: scheme.onPrimaryContainer,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _orderTitle(template),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'O‘chirish',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        message,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _orderTitle(CalculateOrderTemplate template) {
  final name = template.name.trim().isEmpty
      ? template.product.trim()
      : template.name.trim();
  return name.isEmpty ? 'Zakaz' : name;
}

String _fmt(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
