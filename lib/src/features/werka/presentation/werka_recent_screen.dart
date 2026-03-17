import '../../../app/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import '../state/werka_store.dart';
import 'werka_customer_issue_customer_screen.dart';
import 'werka_unannounced_supplier_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaRecentScreen extends StatefulWidget {
  const WerkaRecentScreen({
    super.key,
    this.loader,
  });

  final Future<List<DispatchRecord>> Function()? loader;

  @override
  State<WerkaRecentScreen> createState() => _WerkaRecentScreenState();
}

class _WerkaRecentScreenState extends State<WerkaRecentScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.loader == null) {
      WerkaStore.instance.bootstrapHistory();
    }
  }

  bool _usesCustomerFlow(DispatchRecord record) {
    return record.eventType.startsWith('customer_delivery_');
  }

  Future<void> _repeat(DispatchRecord record) async {
    if (_usesCustomerFlow(record)) {
      await Navigator.of(context).pushNamed(
        AppRoutes.werkaCustomerIssueCustomer,
        arguments: WerkaCustomerIssuePrefillArgs(
          customerRef: record.supplierRef,
          customerName: record.supplierName,
          itemCode: record.itemCode,
          itemName: record.itemName,
          qty: record.sentQty,
          uom: record.uom,
        ),
      );
      return;
    }
    await Navigator.of(context).pushNamed(
      AppRoutes.werkaUnannouncedSupplier,
      arguments: WerkaUnannouncedPrefillArgs(
        supplierRef: record.supplierRef,
        supplierName: record.supplierName,
        itemCode: record.itemCode,
        itemName: record.itemName,
        qty: record.sentQty,
        uom: record.uom,
      ),
    );
  }

  String _headline(DispatchRecord record) {
    return record.itemCode.trim().isEmpty ? record.itemName : record.itemCode;
  }

  String _subline(DispatchRecord record) {
    return '${record.supplierName} • ${record.itemName}';
  }

  String _metric(DispatchRecord record) {
    final sent = '${record.sentQty.toStringAsFixed(0)} ${record.uom}';
    if (_usesCustomerFlow(record)) {
      return '$sent customerga yuborilgan';
    }
    return '$sent supplierdan qabul qilingan';
  }

  String _actionLabel(DispatchRecord record) {
    return _usesCustomerFlow(record) ? 'Yana jo‘natish' : 'Yana qayd qilish';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: WerkaStore.instance,
      builder: (context, _) => Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.shellStart(context),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Avvalgi harakatni prefill bilan qayta ishlating',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
                  child: _buildBody(theme),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 24, 0),
            child: WerkaDock(activeTab: WerkaDockTab.recent),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final store = WerkaStore.instance;
    final items = widget.loader == null ? store.historyItems : _testItems;
    if (widget.loader == null && store.loadingHistory && !store.loadedHistory) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.loader == null && store.historyError != null && !store.loadedHistory) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          _RecentMessageCard(
            title: 'Recent yuklanmadi',
            body: '${store.historyError}',
            actionLabel: 'Qayta urinish',
            onPressed: WerkaStore.instance.refreshHistory,
          ),
        ],
      );
    }
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 110),
        children: const [
          _RecentInfoCard(
            title: 'Hali repeat qilish uchun recent harakat yo‘q.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = items[index];
        return _WerkaRecentCard(
          headline: _headline(record),
          subline: _subline(record),
          metric: _metric(record),
          createdLabel: record.createdLabel,
          highlight: record.highlight,
          actionLabel: _actionLabel(record),
          onRepeat: () => _repeat(record),
        );
      },
    );
  }

  List<DispatchRecord> get _testItems => _cachedTestItems ?? const <DispatchRecord>[];

  List<DispatchRecord>? _cachedTestItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.loader != null && _cachedTestItems == null) {
      widget.loader!().then((items) {
        if (!mounted) return;
        setState(() {
          _cachedTestItems = items;
        });
      });
    }
  }
}

class _RecentMessageCard extends StatelessWidget {
  const _RecentMessageCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentInfoCard extends StatelessWidget {
  const _RecentInfoCard({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(title, style: theme.textTheme.titleMedium),
      ),
    );
  }
}

class _WerkaRecentCard extends StatelessWidget {
  const _WerkaRecentCard({
    required this.headline,
    required this.subline,
    required this.metric,
    required this.createdLabel,
    required this.highlight,
    required this.actionLabel,
    required this.onRepeat,
  });

  final String headline;
  final String subline;
  final String metric;
  final String createdLabel;
  final String highlight;
  final String actionLabel;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    headline,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: onRepeat,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  createdLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (highlight.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                highlight,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
