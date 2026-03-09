import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/supplier_dock.dart';
import 'package:flutter/material.dart';

class SupplierItemPickerScreen extends StatefulWidget {
  const SupplierItemPickerScreen({super.key});

  @override
  State<SupplierItemPickerScreen> createState() =>
      _SupplierItemPickerScreenState();
}

class _SupplierItemPickerScreenState extends State<SupplierItemPickerScreen> {
  final TextEditingController controller = TextEditingController();
  late final Future<List<SupplierItem>> itemsFuture;

  @override
  void initState() {
    super.initState();
    itemsFuture = MobileApi.instance.supplierItems();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: 'Mahsulot tanlash',
      subtitle: 'Faqat sizga biriktirilgan itemlar ko‘rinadi.',
      bottom: const SupplierDock(
        activeTab: SupplierDockTab.home,
        centerActive: true,
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Kod yoki nom bo‘yicha qidiring',
              prefixIcon: Icon(Icons.search),
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
                  return Center(
                    child: SoftCard(
                      child: Text('Mahsulotlar yuklanmadi: ${snapshot.error}'),
                    ),
                  );
                }
                final query = controller.text.trim().toLowerCase();
                final allItems = snapshot.data ?? <SupplierItem>[];
                final filtered = allItems.where((item) {
                  if (query.isEmpty) {
                    return true;
                  }
                  return item.code.toLowerCase().contains(query) ||
                      item.name.toLowerCase().contains(query);
                }).toList();
                if (filtered.isEmpty) {
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
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0xFF1F1F1F),
                  ),
                  itemBuilder: (context, index) {
                    final SupplierItem item = filtered[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.supplierQty, arguments: item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.code,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.name),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${item.uom}  •  ${item.warehouse}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
