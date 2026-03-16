import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/cache/json_cache_store.dart';
import '../../../core/notifications/refresh_hub.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/models/app_models.dart';
import 'werka_customer_issue_customer_screen.dart';
import 'werka_unannounced_supplier_screen.dart';
import 'widgets/werka_dock.dart';
import 'package:flutter/material.dart';

class WerkaRecentScreen extends StatefulWidget {
  const WerkaRecentScreen({super.key});

  @override
  State<WerkaRecentScreen> createState() => _WerkaRecentScreenState();
}

class _WerkaRecentScreenState extends State<WerkaRecentScreen> {
  static const String _cacheKey = 'cache_werka_recent';

  final List<DispatchRecord> _items = <DispatchRecord>[];
  bool _loading = true;
  String? _loadError;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _prime();
    RefreshHub.instance.addListener(_handlePushRefresh);
  }

  @override
  void dispose() {
    RefreshHub.instance.removeListener(_handlePushRefresh);
    super.dispose();
  }

  Future<void> _prime() async {
    final raw = await JsonCacheStore.instance.readList(_cacheKey);
    if (raw != null && mounted) {
      setState(() {
        _items
          ..clear()
          ..addAll(raw.map((item) => DispatchRecord.fromJson(item)));
      });
    }
    await _reload(showSpinner: _items.isEmpty);
  }

  void _handlePushRefresh() {
    if (!mounted || RefreshHub.instance.topic != 'werka') {
      return;
    }
    if (_refreshVersion == RefreshHub.instance.version) {
      return;
    }
    _refreshVersion = RefreshHub.instance.version;
    _reload(showSpinner: false);
  }

  Future<void> _reload({required bool showSpinner}) async {
    if (mounted) {
      setState(() {
        if (showSpinner) {
          _loading = true;
        }
        _loadError = null;
      });
    }
    try {
      final items = await MobileApi.instance.werkaHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _loading = false;
      });
      await JsonCacheStore.instance.writeList(
        _cacheKey,
        items.map((item) => item.toJson()).toList(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadError = '$error';
      });
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
    final scheme = theme.colorScheme;

    return Scaffold(
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
                child: RefreshIndicator.adaptive(
                  onRefresh: () => _reload(showSpinner: false),
                  child: _buildBody(theme, scheme),
                ),
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
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme scheme) {
    if (_loading && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_loadError != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent yuklanmadi',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_loadError!),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _reload(showSpinner: true),
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          Card.filled(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Hali repeat qilish uchun recent harakat yo‘q.',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Card.filled(
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              for (int index = 0; index < _items.length; index++) ...[
                _WerkaRecentRow(
                  record: _items[index],
                  headline: _headline(_items[index]),
                  subline: _subline(_items[index]),
                  metric: _metric(_items[index]),
                  actionLabel: _actionLabel(_items[index]),
                  onRepeat: () => _repeat(_items[index]),
                ),
                if (index != _items.length - 1)
                  const Divider(height: 1, thickness: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WerkaRecentRow extends StatelessWidget {
  const _WerkaRecentRow({
    required this.record,
    required this.headline,
    required this.subline,
    required this.metric,
    required this.actionLabel,
    required this.onRepeat,
  });

  final DispatchRecord record;
  final String headline;
  final String subline;
  final String metric;
  final String actionLabel;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
              FilledButton.tonal(
                onPressed: onRepeat,
                style: FilledButton.styleFrom(
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
                record.createdLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (record.highlight.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.highlight,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
