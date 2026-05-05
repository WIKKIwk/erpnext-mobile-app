import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/search/search_normalizer.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierItemPickerScreen extends StatefulWidget {
  const SupplierItemPickerScreen({super.key});

  @override
  State<SupplierItemPickerScreen> createState() =>
      _SupplierItemPickerScreenState();
}

class _SupplierItemPickerScreenState extends State<SupplierItemPickerScreen>
    with WidgetsBindingObserver {
  final TextEditingController controller = TextEditingController();
  late Future<List<SupplierItem>> itemsFuture;

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
    return searchMatches(
      query,
      [
        item.name,
        item.code,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppShell(
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
                  return const Center(child: AppLoadingIndicator());
                }

                if (snapshot.hasError) {
                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      children: [
                        AppRetryState(onRetry: _reload),
                      ],
                    ),
                  );
                }

                final query = controller.text.trim();
                final allItems = snapshot.data ?? <SupplierItem>[];
                final filtered = allItems
                    .where((item) => _matchesQuery(item, query))
                    .toList();

                if (filtered.isEmpty) {
                  return AppRefreshIndicator(
                    onRefresh: _reload,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              child: Text(
                                query.isEmpty
                                    ? 'Bu supplierga item biriktirilmagan.'
                                    : 'Mahsulot topilmadi.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            switchInCurve: AppMotion.emphasizedDecelerate,
                            switchOutCurve: AppMotion.emphasizedAccelerate,
                            transitionBuilder: (child, animation) {
                              final slide = Tween<Offset>(
                                begin: const Offset(0, 0.03),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: slide,
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey(
                                filtered.map((item) => item.code).join('|'),
                              ),
                              children: [
                                for (int index = 0;
                                    index < filtered.length;
                                    index++) ...[
                                  _SupplierItemRow(
                                    item: filtered[index],
                                    delay: Duration(milliseconds: index * 24),
                                    onTap: () =>
                                        Navigator.of(context).pushNamed(
                                      AppRoutes.supplierQty,
                                      arguments: filtered[index],
                                    ),
                                  ),
                                  if (index != filtered.length - 1)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 18,
                                      endIndent: 18,
                                      color: AppTheme.cardBorder(context)
                                          .withValues(alpha: 0.55),
                                    ),
                                ],
                              ],
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
    this.delay = Duration.zero,
  });

  final SupplierItem item;
  final VoidCallback onTap;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return SmoothAppear(
      delay: delay,
      offset: const Offset(0, 8),
      duration: AppMotion.medium,
      child: Material(
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
