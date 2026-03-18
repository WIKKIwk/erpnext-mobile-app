import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SupplierItemPickerScreen extends StatefulWidget {
  const SupplierItemPickerScreen({super.key});

  @override
  State<SupplierItemPickerScreen> createState() =>
      _SupplierItemPickerScreenState();
}

class _SupplierItemPickerScreenState extends State<SupplierItemPickerScreen>
    with WidgetsBindingObserver {
  final TextEditingController controller = TextEditingController();
  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late Future<List<SupplierItem>> itemsFuture;
  List<SupplierItem> _visibleItems = const <SupplierItem>[];
  List<SupplierItem> _pendingTargetItems = const <SupplierItem>[];
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    itemsFuture = MobileApi.instance.supplierItems();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.supplierItems();
    setState(() {
      itemsFuture = future;
    });
    await future;
  }

  bool _matchesQuery(SupplierItem item, String query) {
    if (query.isEmpty) {
      return true;
    }
    return item.name.toLowerCase().contains(query);
  }

  bool _sameItemOrder(List<SupplierItem> left, List<SupplierItem> right) {
    if (left.length != right.length) {
      return false;
    }
    for (int index = 0; index < left.length; index++) {
      if (left[index].code != right[index].code) {
        return false;
      }
    }
    return true;
  }

  void _scheduleVisibleItemSync(List<SupplierItem> targetItems) {
    _pendingTargetItems = targetItems;
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      _syncVisibleItems(_pendingTargetItems);
    });
  }

  void _syncVisibleItems(List<SupplierItem> targetItems) {
    final listState = _listKey.currentState;
    if (listState == null) {
      if (!_sameItemOrder(_visibleItems, targetItems)) {
        setState(() {
          _visibleItems = List<SupplierItem>.from(targetItems);
          if (targetItems.isNotEmpty) {
            _listKey = GlobalKey<AnimatedListState>();
          }
        });
      }
      return;
    }

    final targetCodes = targetItems.map((item) => item.code).toSet();

    for (int index = _visibleItems.length - 1; index >= 0; index--) {
      final current = _visibleItems[index];
      if (targetCodes.contains(current.code)) {
        continue;
      }
      final removed = _visibleItems.removeAt(index);
      listState.removeItem(
        index,
        (context, animation) =>
            _animatedRow(item: removed, animation: animation),
        duration: AppMotion.medium,
      );
    }

    for (int index = 0; index < targetItems.length; index++) {
      final target = targetItems[index];
      if (index < _visibleItems.length &&
          _visibleItems[index].code == target.code) {
        continue;
      }
      _visibleItems.insert(index, target);
      listState.insertItem(index, duration: AppMotion.medium);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Widget _animatedRow({
    required SupplierItem item,
    required Animation<double> animation,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasizedDecelerate,
      reverseCurve: AppMotion.emphasizedAccelerate,
    );
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        axisAlignment: -1,
        child: _SupplierItemRow(
          item: item,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.supplierQty,
            arguments: item,
          ),
        ),
      ),
    );
  }

  double _cardHeight() {
    if (_visibleItems.isEmpty) {
      return 1;
    }
    const double rowHeight = 64;
    const double dividerHeight = 1;
    return (_visibleItems.length * rowHeight) +
        math.max(0, _visibleItems.length - 1) * dividerHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: 'Mahsulot tanlash',
      subtitle: '',
      contentPadding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      bottom: const SupplierDock(
        activeTab: null,
        centerActive: true,
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Nom bo‘yicha qidiring',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SupplierItem>>(
              future: itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: [
                        const SizedBox(height: 120),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mahsulotlar yuklanmadi',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _reload,
                                  child: const Text('Qayta urinish'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final query = controller.text.trim().toLowerCase();
                final allItems = snapshot.data ?? <SupplierItem>[];
                final filtered = allItems
                    .where((item) => _matchesQuery(item, query))
                    .toList();
                if (!_sameItemOrder(_visibleItems, filtered)) {
                  _scheduleVisibleItemSync(filtered);
                }
                final shouldShowListCard =
                    filtered.isNotEmpty || _visibleItems.isNotEmpty;
                if (!shouldShowListCard) {
                  return Center(
                    child: SoftCard(
                      child: Text(
                        query.isEmpty
                            ? 'Bu supplierga item biriktirilmagan.'
                            : 'Qidiruv bo‘yicha item topilmadi.',
                      ),
                    ),
                  );
                }
                return AppRefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    children: [
                      Card.filled(
                        key: const ValueKey('supplier-item-card'),
                        margin: EdgeInsets.zero,
                        color: scheme.surfaceContainerLow,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: AnimatedSize(
                          duration: AppMotion.medium,
                          curve: AppMotion.emphasizedDecelerate,
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: _cardHeight(),
                            child: AnimatedList(
                              key: _listKey,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              initialItemCount: _visibleItems.length,
                              itemBuilder: (context, index, animation) {
                                return Column(
                                  children: [
                                    _animatedRow(
                                      item: _visibleItems[index],
                                      animation: animation,
                                    ),
                                    if (index != _visibleItems.length - 1)
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        indent: 18,
                                        endIndent: 18,
                                        color: AppTheme.cardBorder(context)
                                            .withValues(alpha: 0.55),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierItemRow extends StatelessWidget {
  const _SupplierItemRow({
    required this.item,
    required this.onTap,
  });

  final SupplierItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.name.isEmpty ? item.code : item.name,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
