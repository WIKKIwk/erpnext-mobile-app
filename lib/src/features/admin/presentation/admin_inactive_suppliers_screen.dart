import '../../../core/api/mobile_api.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class AdminInactiveSuppliersScreen extends StatefulWidget {
  const AdminInactiveSuppliersScreen({super.key});

  @override
  State<AdminInactiveSuppliersScreen> createState() =>
      _AdminInactiveSuppliersScreenState();
}

class _AdminInactiveSuppliersScreenState
    extends State<AdminInactiveSuppliersScreen> {
  late Future<List<AdminSupplier>> _future;
  String? _busyRef;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.adminInactiveSuppliers();
  }

  Future<void> _reload() async {
    final future = MobileApi.instance.adminInactiveSuppliers();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _restore(AdminSupplier item) async {
    setState(() => _busyRef = item.ref);
    try {
      await MobileApi.instance.adminRestoreSupplier(item.ref);
      await _reload();
    } finally {
      if (mounted) {
        setState(() => _busyRef = null);
      }
    }
  }

  Future<void> _unblock(AdminSupplier item) async {
    setState(() => _busyRef = item.ref);
    try {
      await MobileApi.instance.adminSetSupplierBlocked(
        ref: item.ref,
        blocked: false,
      );
      await _reload();
    } finally {
      if (mounted) {
        setState(() => _busyRef = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      leading: AppShellIconAction(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: 'Inactive Suppliers',
      subtitle: 'Bloklangan va chiqarilgan supplierlar.',
      child: FutureBuilder<List<AdminSupplier>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SoftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Inactive supplierlar yuklanmadi: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <AdminSupplier>[];
          if (items.isEmpty) {
            return Center(
              child: SoftCard(
                child: Text(
                  'Hozircha bloklangan yoki chiqarilgan supplier yo‘q.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final bool busy = _busyRef == item.ref;
                return SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (item.removed)
                            const _StatusChip(
                              label: 'Chiqarilgan',
                              color: Colors.white,
                            )
                          else if (item.blocked)
                            const _StatusChip(
                              label: 'Blocked',
                              color: Colors.white,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        item.code,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (item.removed)
                            Expanded(
                              child: FilledButton(
                                onPressed: busy ? null : () => _restore(item),
                                child: Text(
                                  busy ? 'Qaytarilmoqda...' : 'Qaytarish',
                                ),
                              ),
                            ),
                          if (item.removed && item.blocked)
                            const SizedBox(width: 12),
                          if (item.blocked && !item.removed)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy ? null : () => _unblock(item),
                                child: Text(
                                  busy ? 'Ochilmoqda...' : 'Blokdan ochish',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.cardBorder(context)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}
