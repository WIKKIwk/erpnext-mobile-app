import 'dart:async';
import 'dart:convert';

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/session/state/app_session.dart';
import '../../../core/test_mode/test_mode_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/widgets/navigation/dock_gesture_overlay.dart';
import '../../../core/widgets/navigation/dock_system_bottom_inset.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../aparatchi/presentation/widgets/aparatchi_dock.dart';
import '../../aparatchi/presentation/widgets/aparatchi_navigation_drawer.dart';
import '../logic/apparatus_queue_state.dart';
import '../logic/production_map_chain.dart';
import '../logic/production_map_pechat_rules.dart';
import '../models/production_map_models.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_navigation_drawer.dart';
import 'widgets/admin_top_notice.dart';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum _OpenedOrderModule {
  move,
  sequence,
  orders,
}

const _moveUnassignedWarehouse = AdminWarehouse(
  warehouse: 'Tanlanmagan',
  parentWarehouse: 'production-map-unassigned',
);

bool _isMoveUnassignedApparatus(AdminWarehouse? apparatus) {
  return apparatus?.parentWarehouse == _moveUnassignedWarehouse.parentWarehouse;
}

String _openedOrderDisplayCode(ProductionMapDefinition map) {
  final code = map.code.trim();
  if (code.isNotEmpty) {
    return code;
  }
  final orderNumber = map.orderNumber.trim();
  if (orderNumber.isNotEmpty) {
    return orderNumber;
  }
  final id = map.id.trim();
  const prefix = 'zakaz-';
  if (id.startsWith(prefix)) {
    final suffix = id.substring(prefix.length).trim();
    if (suffix.isNotEmpty) {
      return suffix;
    }
  }
  return '';
}

String _openedOrderPrimaryTitle(ProductionMapDefinition map) {
  final title = map.title.trim();
  if (title.isNotEmpty) {
    return title;
  }
  final product = _openedOrderProductTitle(map);
  if (product.isNotEmpty) {
    return product;
  }
  return 'Zakaz';
}

String _openedOrderProductTitle(ProductionMapDefinition map) {
  for (final node in map.nodes) {
    final title = node.title.trim();
    if (node.kind == 'end' && title.isNotEmpty && title != map.title.trim()) {
      return title;
    }
  }
  return '';
}

String _openedOrderSubtitle(
  ProductionMapDefinition map, {
  bool includeApparatusCount = false,
}) {
  final productTitle = _openedOrderProductTitle(map);
  final apparatusCount =
      map.nodes.where((node) => node.kind == 'apparatus').length;
  return [
    if (productTitle.isNotEmpty) productTitle,
    if (map.productCode.trim().isNotEmpty) map.productCode.trim(),
    if (includeApparatusCount && apparatusCount > 0)
      '$apparatusCount ta aparat',
  ].join(' • ');
}

class AdminProductionMapOrdersScreen extends StatefulWidget {
  const AdminProductionMapOrdersScreen({
    super.key,
    this.readOnly = false,
    this.workerMode = false,
  });

  final bool readOnly;
  final bool workerMode;

  @override
  State<AdminProductionMapOrdersScreen> createState() =>
      _AdminProductionMapOrdersScreenState();
}

class _AdminProductionMapOrdersScreenState
    extends State<AdminProductionMapOrdersScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _openingRoute = false;
  bool _loading = true;
  bool _mapsRefreshInFlight = false;
  int _liveStreamGeneration = 0;
  StreamSubscription<String>? _liveStreamSubscription;
  final http.Client _liveHttpClient = http.Client();
  String _searchQuery = '';
  _OpenedOrderModule _module = _OpenedOrderModule.orders;
  AdminWarehouse? _selectedApparatus;
  AdminWarehouse? _moveTopApparatus;
  AdminWarehouse? _moveBottomApparatus;
  final Set<String> _selectedMoveOrderIds = {};
  List<ProductionMapSaved> _draggingMoveOrders = const [];
  AdminWarehouse? _draggingMoveSource;
  List<ProductionMapSaved> _orders = const [];
  List<AdminWarehouse> _apparatus = const [];
  final Map<String, List<String>> _sequenceByApparatus = {};
  final Map<String, Map<String, String>> _queueStatesByApparatus = {};
  bool _queueActionInFlight = false;

  @override
  void initState() {
    super.initState();
    if (widget.workerMode) {
      _tabController = TabController(length: 1, vsync: this);
    } else {
      _tabController = TabController(
        length: _modules.length,
        vsync: this,
        initialIndex: _modules.indexOf(_module).clamp(0, _modules.length - 1),
      );
      _tabController.addListener(_syncModuleFromTab);
    }
    if (widget.workerMode) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(_startWorkerLive());
    } else {
      unawaited(_refreshLive(initial: true));
    }
  }

  @override
  void dispose() {
    if (widget.workerMode) {
      WidgetsBinding.instance.removeObserver(this);
      _stopWorkerLiveStream();
      _liveHttpClient.close();
    }
    if (!widget.workerMode) {
      _tabController.removeListener(_syncModuleFromTab);
    }
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.workerMode && state == AppLifecycleState.resumed) {
      unawaited(_startWorkerLive());
    }
  }

  Future<void> _startWorkerLive() async {
    await _loadWorkerApparatus();
    if (!mounted) {
      return;
    }
    if (await TestModeController.instance.isEnabled()) {
      await _refreshLive(initial: true);
      return;
    }
    _stopWorkerLiveStream();
    _liveStreamGeneration++;
    unawaited(_runWorkerLiveStream(_liveStreamGeneration));
  }

  void _stopWorkerLiveStream() {
    _liveStreamGeneration++;
    final subscription = _liveStreamSubscription;
    _liveStreamSubscription = null;
    unawaited(subscription?.cancel());
  }

  Future<void> _runWorkerLiveStream(int generation) async {
    while (
        mounted && generation == _liveStreamGeneration && widget.workerMode) {
      try {
        await _connectWorkerLiveStreamOnce(generation);
      } catch (_) {
        if (!mounted || generation != _liveStreamGeneration) {
          return;
        }
        await _refreshLive(initial: _loading);
      }
      if (!mounted || generation != _liveStreamGeneration) {
        return;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _connectWorkerLiveStreamOnce(int generation) async {
    final response = await MobileApi.instance.adminProductionMapLiveConnect();
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw MobileApiException(
        code: 'production_map_live',
        message: 'Live ulanish ochilmadi',
        statusCode: response.statusCode,
      );
    }

    final completer = Completer<void>();
    final dataLines = <String>[];

    await _liveStreamSubscription?.cancel();
    _liveStreamSubscription = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (!mounted || generation != _liveStreamGeneration) {
          return;
        }
        if (line.isEmpty) {
          if (dataLines.isEmpty) {
            return;
          }
          final payloadText = dataLines.join('\n');
          dataLines.clear();
          final payload = jsonDecode(payloadText) as Map<String, dynamic>;
          if (payload['ok'] != true) {
            return;
          }
          _applyWorkerLiveSnapshot(
            AdminProductionMapLiveSnapshot.fromJson(payload),
          );
          return;
        }
        if (line.startsWith(':')) {
          return;
        }
        if (line.startsWith('data:')) {
          dataLines.add(line.substring(5).trimLeft());
        }
      },
      onError: (error, _) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      cancelOnError: true,
    );

    await completer.future;
  }

  Future<void> _loadWorkerApparatus() async {
    final apparatus = await MobileApi.instance.adminWarehouses(
      parent: 'aparat - A',
      limit: 200,
    );
    if (!mounted) {
      return;
    }
    if (widget.workerMode && apparatus.length != _apparatus.length) {
      _recreateWorkerTabController(apparatus);
    }
    setState(() {
      _apparatus = apparatus;
    });
  }

  void _applyWorkerLiveSnapshot(AdminProductionMapLiveSnapshot snapshot) {
    final orders = snapshot.maps
        .where((item) => item.map.id.trim().startsWith('zakaz-'))
        .toList(growable: false);
    setState(() {
      _orders = orders;
      _sequenceByApparatus
        ..clear()
        ..addAll(snapshot.sequences);
      _queueStatesByApparatus
        ..clear()
        ..addAll(snapshot.queueStates);
      _loading = false;
    });
  }

  Future<void> _refreshLive({bool initial = false}) async {
    if (widget.workerMode) {
      await _refreshMapsAndApparatus(initial: initial);
      await _refreshQueueSnapshot();
      return;
    }
    await Future.wait([
      _refreshMapsAndApparatus(initial: initial),
      _refreshQueueSnapshot(),
    ]);
  }

  Future<void> _refreshQueueSnapshot() async {
    try {
      final queueSnapshot = await _loadQueueSnapshot();
      if (!mounted) {
        return;
      }
      if (!_queueSnapshotChanged(queueSnapshot)) {
        return;
      }
      setState(() {
        _sequenceByApparatus
          ..clear()
          ..addAll(queueSnapshot.sequences);
        _queueStatesByApparatus
          ..clear()
          ..addAll(queueSnapshot.queueStates);
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _refreshMapsAndApparatus({bool initial = false}) async {
    if (!initial && _mapsRefreshInFlight) {
      return;
    }
    if (!initial) {
      _mapsRefreshInFlight = true;
    }
    try {
      final results = await Future.wait([
        MobileApi.instance.adminProductionMaps(),
        MobileApi.instance.adminWarehouses(
          parent: 'aparat - A',
          limit: 200,
        ),
      ]);
      if (!mounted) {
        return;
      }
      final maps = results[0] as List<ProductionMapSaved>;
      final apparatus = results[1] as List<AdminWarehouse>;
      final orders = maps
          .where((item) => item.map.id.trim().startsWith('zakaz-'))
          .toList(growable: false);
      if (!initial &&
          _ordersRevision(orders) == _ordersRevision(_orders) &&
          _apparatus.length == apparatus.length &&
          _apparatus.every(
            (item) => apparatus.any(
              (next) => next.warehouse == item.warehouse,
            ),
          )) {
        return;
      }
      if (widget.workerMode &&
          (initial || apparatus.length != _apparatus.length)) {
        _recreateWorkerTabController(apparatus);
      }
      setState(() {
        _orders = orders;
        _apparatus = apparatus;
        if (!widget.workerMode) {
          _selectedApparatus ??= apparatus.isEmpty ? null : apparatus.first;
          _syncMoveApparatusDefaults(apparatus);
        }
        if (initial) {
          _loading = false;
        }
      });
    } finally {
      _mapsRefreshInFlight = false;
    }
  }

  bool _queueSnapshotChanged(AdminApparatusQueueSnapshot snapshot) {
    if (_sequenceByApparatus.length != snapshot.sequences.length ||
        _queueStatesByApparatus.length != snapshot.queueStates.length) {
      return true;
    }
    for (final entry in snapshot.sequences.entries) {
      final current = _sequenceByApparatus[entry.key];
      if (current == null ||
          current.length != entry.value.length ||
          !_stringListsEqual(current, entry.value)) {
        return true;
      }
    }
    for (final entry in snapshot.queueStates.entries) {
      final current = _queueStatesByApparatus[entry.key];
      if (current == null || !_stringMapsEqual(current, entry.value)) {
        return true;
      }
    }
    return false;
  }

  bool _stringListsEqual(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  bool _stringMapsEqual(Map<String, String> left, Map<String, String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  int _ordersRevision(List<ProductionMapSaved> orders) {
    return Object.hashAll(
      orders.map(
        (item) => Object.hash(
          item.map.id,
          item.map.code,
          item.map.orderNumber,
          item.map.title,
          item.map.productCode,
          item.map.rollCount,
          item.map.widthMm,
          item.map.nodes.length,
          Object.hashAll(
            item.map.nodes.map(
              (node) => Object.hash(
                node.id,
                node.kind,
                node.title,
                node.alternativeGroupId,
                node.alternativeAssignedTitle,
              ),
            ),
          ),
          item.map.edges.length,
          Object.hashAll(
            item.map.edges.map(
              (edge) => Object.hash(edge.from, edge.to, edge.branch),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load() => _refreshLive(initial: true);

  List<_OpenedOrderModule> get _modules {
    return widget.workerMode
        ? const [_OpenedOrderModule.sequence]
        : _OpenedOrderModule.values;
  }

  void _recreateWorkerTabController(List<AdminWarehouse> apparatus) {
    final length = apparatus.isEmpty ? 1 : apparatus.length;
    final initialIndex = _initialWatchTabIndex(apparatus).clamp(0, length - 1);
    if (_tabController.length == length) {
      return;
    }
    _tabController.dispose();
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  int _initialWatchTabIndex(List<AdminWarehouse> apparatus) {
    final assigned = AppSession.instance.profile?.assignedApparatus
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty) ??
        const <String>[];
    for (final item in assigned) {
      final index = apparatus.indexWhere(
        (entry) => _apparatusTitlesMatch(entry.warehouse, item),
      );
      if (index >= 0) {
        return index;
      }
    }
    return 0;
  }

  bool _apparatusTitlesMatch(String left, String right) {
    return productionMapWarehouseTitlesMatch(left, right);
  }

  bool _isAssignedWatchApparatus(AdminWarehouse apparatus) {
    final title = apparatus.warehouse.trim();
    final assigned =
        AppSession.instance.profile?.assignedApparatus ?? const <String>[];
    return assigned.any((item) => _apparatusTitlesMatch(title, item));
  }

  Map<String, String> _queueStatesForApparatus(AdminWarehouse apparatus) {
    final title = apparatus.warehouse.trim();
    final direct = _queueStatesByApparatus[title];
    if (direct != null) {
      return direct;
    }
    final color = productionMapPechatColorCount(title);
    if (color != null) {
      for (final entry in _queueStatesByApparatus.entries) {
        if (productionMapPechatColorCount(entry.key) == color) {
          return entry.value;
        }
      }
    }
    return const {};
  }

  List<String> _sequenceOrderIdsForApparatus(AdminWarehouse apparatus) {
    final title = apparatus.warehouse.trim();
    final direct = _sequenceByApparatus[title];
    if (direct != null) {
      return direct;
    }
    final color = productionMapPechatColorCount(title);
    if (color != null) {
      for (final entry in _sequenceByApparatus.entries) {
        if (productionMapPechatColorCount(entry.key) == color) {
          return entry.value;
        }
      }
    }
    return const [];
  }

  Future<Map<String, String>?> _handleQueueAction({
    required AdminWarehouse apparatus,
    required ProductionMapSaved order,
    required String action,
  }) async {
    if (_queueActionInFlight) {
      return null;
    }
    final apparatusKey = apparatus.warehouse.trim();
    _queueActionInFlight = true;
    setState(() {});
    try {
      final states = await MobileApi.instance.adminApparatusQueueAction(
        apparatus: apparatusKey,
        orderId: order.map.id,
        action: action,
      );
      if (!mounted) {
        return null;
      }
      setState(() {
        _queueStatesByApparatus[apparatusKey] = states;
      });
      unawaited(_refreshLive());
      return states;
    } catch (error) {
      if (!mounted) {
        return null;
      }
      showAdminTopNotice(
        context,
        error is MobileApiException
            ? error.message
            : 'Navbat amali bajarilmadi',
      );
      return null;
    } finally {
      _queueActionInFlight = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<AdminApparatusQueueSnapshot> _loadQueueSnapshot() async {
    try {
      return await MobileApi.instance.adminProductionMapQueueSnapshot();
    } catch (_) {
      return const AdminApparatusQueueSnapshot(
        sequences: {},
        queueStates: {},
      );
    }
  }

  void _syncMoveApparatusDefaults(List<AdminWarehouse> source) {
    final pechat = source
        .where((item) => productionMapPechatColorCount(item.warehouse) != null)
        .toList(growable: false);
    final candidates = pechat.isEmpty ? source : pechat;
    if (candidates.isEmpty) {
      _moveTopApparatus = null;
      _moveBottomApparatus = null;
      return;
    }
    _moveTopApparatus ??= candidates.first;
    if (_moveBottomApparatus == null) {
      if (candidates.length > 1) {
        _moveBottomApparatus = candidates[1];
      } else {
        for (final item in source) {
          if (item.warehouse != candidates.first.warehouse) {
            _moveBottomApparatus = item;
            break;
          }
        }
      }
    }
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

  void _openOrder(ProductionMapSaved order) {
    Navigator.of(context).pushNamed(
      AppRoutes.adminProductionMapTest,
      arguments: order,
    );
  }

  void _showOrderDetail(ProductionMapSaved order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ReadOnlyOrderDetailSheet(order: order),
    );
  }

  void _showWatchOrderDetail({
    required AdminWarehouse apparatus,
    required ProductionMapSaved order,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ReadOnlyOrderDetailSheet(
        order: order,
        apparatus: apparatus,
        canManageQueue: _isAssignedWatchApparatus(apparatus),
        initialQueueStates: _queueStatesForApparatus(apparatus),
        queueStatesByApparatus: _queueStatesByApparatus,
        isOrderReadyForStation: (orderId) {
          final match = _orders
              .where((item) => item.map.id.trim() == orderId.trim())
              .cast<ProductionMapSaved?>()
              .firstWhere((item) => item != null, orElse: () => null);
          if (match == null) {
            return true;
          }
          return productionMapOrderReadyForStation(
            map: match.map,
            orderId: orderId,
            station: apparatus.warehouse.trim(),
            queueStatesByApparatus: _queueStatesByApparatus,
          );
        },
        sequenceOrderIds: _sequenceOrderIdsForApparatus(apparatus),
        visibleOrderIds: _ordersForApparatus(apparatus)
            .map((item) => item.map.id)
            .toList(growable: false),
        onQueueAction: _handleQueueAction,
      ),
    );
  }

  void _setModule(_OpenedOrderModule module) {
    if (_module != module) {
      setState(() => _module = module);
    }
    final index = _modules.indexOf(module);
    if (index < 0) {
      return;
    }
    if (_tabController.index != index) {
      _tabController.animateTo(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _pickSequenceApparatus() async {
    if (_apparatus.isEmpty) {
      return;
    }
    final picked = await showModalBottomSheet<AdminWarehouse>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ApparatusPickerSheet(
        apparatus: _apparatus,
        selected: _selectedApparatus,
        orderCountFor: (apparatus) => _ordersForApparatus(apparatus).length,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _selectedApparatus = picked);
  }

  void _syncModuleFromTab() {
    final module = _modules[_tabController.index];
    if (_module != module) {
      setState(() => _module = module);
    }
  }

  List<ProductionMapSaved> _visibleOrders() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _orders;
    }
    return _orders.where((order) {
      final map = order.map;
      final haystack = [
        _openedOrderDisplayCode(map),
        map.code,
        map.orderNumber,
        map.title,
        map.productCode,
        for (final node in map.nodes) node.title,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  List<ProductionMapSaved> _ordersForApparatus(AdminWarehouse apparatus) {
    final title = apparatus.warehouse.trim();
    final filtered = _orders.where((order) {
      final hasAlternative = _hasAlternativeApparatus(order.map);
      if (hasAlternative) {
        return _alternativeOrderAssignedToApparatus(order.map, apparatus);
      }
      return productionMapMapHasWorkStageForStation(
        map: order.map,
        station: title,
      );
    }).toList();
    final sequence = _sequenceOrderIdsForApparatus(apparatus);
    if (sequence.isEmpty) {
      return filtered;
    }
    final byId = {for (final order in filtered) order.map.id: order};
    return [
      for (final id in sequence)
        if (byId.containsKey(id)) byId.remove(id)!,
      ...byId.values,
    ];
  }

  List<ProductionMapSaved> _moveOrdersForApparatus({
    required AdminWarehouse source,
    required AdminWarehouse target,
  }) {
    if (_isMoveUnassignedApparatus(source)) {
      if (_isMoveUnassignedApparatus(target)) {
        return const [];
      }
      return _alternativeOrdersForApparatus(target);
    }
    if (_isMoveUnassignedApparatus(target)) {
      return _ordersForApparatus(source);
    }
    return _ordersForApparatus(source)
        .where(
          (order) => _canMoveOrderToApparatus(order, target, source: source),
        )
        .toList(growable: false);
  }

  Future<void> _reorderSelectedApparatusOrders(
      int oldIndex, int newIndex) async {
    if (widget.readOnly) {
      return;
    }
    final apparatus = _selectedApparatus;
    if (apparatus == null) {
      return;
    }
    final orders =
        List<ProductionMapSaved>.from(_ordersForApparatus(apparatus));
    if (oldIndex == newIndex) {
      return;
    }
    final previousOrderIds =
        orders.map((order) => order.map.id).toList(growable: false);
    final moved = orders.removeAt(oldIndex);
    orders.insert(newIndex, moved);
    final apparatusKey = apparatus.warehouse.trim();
    final orderIds =
        orders.map((order) => order.map.id).toList(growable: false);
    setState(() {
      _sequenceByApparatus[apparatusKey] = orderIds;
    });
    await _persistSequence(apparatusKey, orderIds, previousOrderIds);
  }

  Future<void> _persistSequence(
    String apparatus,
    List<String> orderIds,
    List<String> previousOrderIds,
  ) async {
    try {
      await MobileApi.instance.adminSaveProductionMapSequence(
        apparatus: apparatus,
        orderIds: orderIds,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sequenceByApparatus[apparatus] = previousOrderIds;
      });
      showAdminTopNotice(
        context,
        error is MobileApiException ? error.message : 'Ketma-ketlik saqlanmadi',
      );
    }
  }

  void _toggleMoveOrderSelection(String orderId) {
    if (widget.readOnly) {
      return;
    }
    final normalized = orderId.trim();
    setState(() {
      if (_selectedMoveOrderIds.contains(normalized)) {
        _selectedMoveOrderIds.remove(normalized);
      } else {
        _selectedMoveOrderIds.add(normalized);
      }
    });
  }

  _MoveDragPayload _buildMoveDragPayload({
    required ProductionMapSaved order,
    required AdminWarehouse source,
    required List<ProductionMapSaved> zoneOrders,
  }) {
    final orderId = order.map.id.trim();
    final selectedFromZone = zoneOrders
        .where(
          (item) => _selectedMoveOrderIds.contains(item.map.id.trim()),
        )
        .toList(growable: false);
    final orders = selectedFromZone.isNotEmpty &&
            selectedFromZone.any((item) => item.map.id.trim() == orderId)
        ? selectedFromZone
        : [order];
    return _MoveDragPayload(orders: orders, source: source);
  }

  Future<void> _moveOrdersBetweenApparatus({
    required List<ProductionMapSaved> orders,
    required AdminWarehouse from,
    required AdminWarehouse to,
  }) async {
    if (_isMoveUnassignedApparatus(from) && !_isMoveUnassignedApparatus(to)) {
      await _assignAlternativeOrdersToApparatus(
        orders: orders,
        apparatus: to,
      );
      return;
    }
    if (!_isMoveUnassignedApparatus(from) && _isMoveUnassignedApparatus(to)) {
      await _returnOrdersToUnassigned(
        orders: orders,
        source: from,
      );
      return;
    }
    if (widget.readOnly ||
        from.warehouse.trim() == to.warehouse.trim() ||
        _isMoveUnassignedApparatus(from) ||
        _isMoveUnassignedApparatus(to) ||
        orders.isEmpty) {
      return;
    }
    final blocked = orders.any(
      (order) => !_canMoveOrderToApparatus(order, to, source: from),
    );
    if (blocked) {
      showAdminTopNotice(context, 'Tanlangan zakazlar bu aparatga tushmaydi');
      return;
    }
    final orderIds = orders.map((order) => order.map.id.trim()).toSet();
    setState(() {
      _draggingMoveOrders = const [];
      _draggingMoveSource = null;
    });
    try {
      final saved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
        mapIds: orders.map((order) => order.map.id).toList(growable: false),
        fromApparatus: from.warehouse,
        toApparatus: to.warehouse,
      );
      if (!mounted) {
        return;
      }
      final savedById = {
        for (final item in saved) item.map.id.trim(): item,
      };
      if (savedById.length != orderIds.length ||
          !orderIds.every(savedById.containsKey)) {
        throw const MobileApiException(
          code: 'move_incomplete',
          message: 'Zakazlar to‘liq ko‘chirilmadi',
        );
      }
      setState(() {
        _selectedMoveOrderIds.removeAll(orderIds);
        _orders = [
          for (final item in _orders)
            if (savedById.containsKey(item.map.id.trim()))
              savedById[item.map.id.trim()]!
            else
              item,
        ];
      });
      showAdminTopNotice(
        context,
        orders.length == 1
            ? 'Zakaz ko‘chirildi'
            : '${orders.length} ta zakaz ko‘chirildi',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAdminTopNotice(
        context,
        error is MobileApiException ? error.message : 'Zakaz ko‘chirilmadi',
      );
      // Some orders may already be moved on the server; re-sync instead of
      // restoring a stale local state.
      await _load();
    }
  }

  Future<void> _returnOrdersToUnassigned({
    required List<ProductionMapSaved> orders,
    required AdminWarehouse source,
  }) async {
    if (widget.readOnly || orders.isEmpty) {
      return;
    }
    final converted = <MapEntry<ProductionMapSaved, ProductionMapDefinition>>[];
    for (final order in orders) {
      final map = _returnAssignedMapToAlternatives(order.map, source);
      if (map == null) {
        showAdminTopNotice(context, 'Bu zakaz tanlanmagan holatga qaytmaydi');
        return;
      }
      converted.add(MapEntry(order, map));
    }
    final orderIds = orders.map((order) => order.map.id.trim()).toSet();
    setState(() {
      _draggingMoveOrders = const [];
      _draggingMoveSource = null;
    });
    try {
      final saved = <ProductionMapSaved>[];
      for (final entry in converted) {
        saved.add(
          await MobileApi.instance.adminSaveProductionMap(entry.value),
        );
      }
      if (!mounted) {
        return;
      }
      final savedById = {
        for (final item in saved) item.map.id.trim(): item,
      };
      if (savedById.length != orderIds.length ||
          !orderIds.every(savedById.containsKey)) {
        throw const MobileApiException(
          code: 'move_incomplete',
          message: 'Zakazlar to‘liq tanlanmagan holatga qaytmadi',
        );
      }
      setState(() {
        _selectedMoveOrderIds.removeAll(orderIds);
        _orders = [
          for (final item in _orders)
            if (savedById.containsKey(item.map.id.trim()))
              savedById[item.map.id.trim()]!
            else
              item,
        ];
      });
      showAdminTopNotice(
        context,
        orders.length == 1
            ? 'Zakaz tanlanmagan holatga qaytarildi'
            : '${orders.length} ta zakaz tanlanmagan holatga qaytarildi',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAdminTopNotice(
        context,
        error is MobileApiException
            ? error.message
            : 'Zakaz tanlanmagan holatga qaytmadi',
      );
      await _load();
    }
  }

  ProductionMapDefinition? _returnAssignedMapToAlternatives(
    ProductionMapDefinition map,
    AdminWarehouse source,
  ) {
    final sourceTitle = source.warehouse.trim();
    final assignedGroupId = _assignedAlternativeGroupIdForApparatus(
      map,
      sourceTitle,
    );
    if (assignedGroupId == null) {
      return null;
    }
    return map.copyWith(
      nodes: [
        for (final node in map.nodes)
          node.alternativeGroupId.trim() == assignedGroupId
              ? node.copyWith(alternativeAssignedTitle: '')
              : node,
      ],
    );
  }

  Future<void> _assignAlternativeOrdersToApparatus({
    required List<ProductionMapSaved> orders,
    required AdminWarehouse apparatus,
  }) async {
    if (widget.readOnly || orders.isEmpty) {
      return;
    }
    final blocked = orders.any(
      (order) => !_isAlternativeOrderForApparatus(order, apparatus),
    );
    if (blocked) {
      showAdminTopNotice(context, 'Tanlangan zakazlar bu aparatga tushmaydi');
      return;
    }
    final orderIds = orders.map((order) => order.map.id.trim()).toSet();
    setState(() {
      _draggingMoveOrders = const [];
      _draggingMoveSource = null;
    });
    try {
      final saved = <ProductionMapSaved>[];
      for (final order in orders) {
        final assignedMap = _assignAlternativeMapToApparatus(
          order.map,
          apparatus,
        );
        saved.add(await MobileApi.instance.adminSaveProductionMap(assignedMap));
      }
      if (!mounted) {
        return;
      }
      final savedById = {
        for (final item in saved) item.map.id.trim(): item,
      };
      if (savedById.length != orderIds.length ||
          !orderIds.every(savedById.containsKey)) {
        throw const MobileApiException(
          code: 'move_incomplete',
          message: 'Zakazlar to‘liq biriktirilmadi',
        );
      }
      setState(() {
        _selectedMoveOrderIds.removeAll(orderIds);
        _orders = [
          for (final item in _orders)
            if (savedById.containsKey(item.map.id.trim()))
              savedById[item.map.id.trim()]!
            else
              item,
        ];
      });
      showAdminTopNotice(
        context,
        orders.length == 1
            ? 'Zakaz aparatga biriktirildi'
            : '${orders.length} ta zakaz aparatga biriktirildi',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAdminTopNotice(
        context,
        error is MobileApiException ? error.message : 'Zakaz biriktirilmadi',
      );
      await _load();
    }
  }

  ProductionMapDefinition _assignAlternativeMapToApparatus(
    ProductionMapDefinition map,
    AdminWarehouse apparatus,
  ) {
    final targetTitle = apparatus.warehouse.trim();
    final targetNode = map.nodes
        .where((node) {
          return node.kind == 'apparatus' &&
              node.alternativeGroupId.trim().isNotEmpty &&
              productionMapWarehouseTitlesMatch(node.title, targetTitle);
        })
        .cast<ProductionMapNode?>()
        .firstWhere(
          (node) => node != null,
          orElse: () => null,
        );
    if (targetNode == null) {
      return map;
    }
    final groupId = targetNode.alternativeGroupId.trim();
    return map.copyWith(
      nodes: [
        for (final node in map.nodes)
          node.alternativeGroupId.trim() == groupId
              ? node.copyWith(alternativeAssignedTitle: targetTitle)
              : node,
      ],
    );
  }

  int? _orderPechatColorCount(ProductionMapSaved order) {
    return productionMapOrderPechatColorCount(
      order.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.title),
    );
  }

  bool _canMoveOrderToApparatus(
    ProductionMapSaved order,
    AdminWarehouse target, {
    required AdminWarehouse source,
  }) {
    if (_isMoveUnassignedApparatus(source)) {
      return !_isMoveUnassignedApparatus(target) &&
          _isAlternativeOrderForApparatus(order, target);
    }
    if (_isMoveUnassignedApparatus(target)) {
      return _returnAssignedMapToAlternatives(order.map, source) != null;
    }
    final colorCount = productionMapPechatColorCount(target.warehouse);
    if (colorCount == null) {
      return true;
    }
    final sourceColorCount = productionMapPechatColorCount(source.warehouse) ??
        _orderPechatColorCount(order);
    return productionMapPechatCanMoveOrder(
      apparatusColorCount: colorCount,
      rollCount: order.map.rollCount,
      widthMm: order.map.widthMm,
      sourceApparatusColorCount: sourceColorCount,
    );
  }

  Future<void> _pickMoveApparatus({required bool top}) async {
    final anchor = top ? _moveBottomApparatus : _moveTopApparatus;
    final unassignedOrderCount =
        anchor == null || _isMoveUnassignedApparatus(anchor)
            ? 0
            : _alternativeOrdersForApparatus(anchor).length;
    final picked = await showModalBottomSheet<AdminWarehouse>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ApparatusPickerSheet(
        apparatus: _apparatus,
        selected: top ? _moveTopApparatus : _moveBottomApparatus,
        orderCountFor: (apparatus) => _ordersForApparatus(apparatus).length,
        showUnassigned: anchor != null && !_isMoveUnassignedApparatus(anchor),
        unassignedOrderCount: unassignedOrderCount,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (top) {
        _moveTopApparatus = picked;
      } else {
        _moveBottomApparatus = picked;
      }
    });
  }

  List<ProductionMapSaved> _alternativeOrdersForApparatus(
    AdminWarehouse apparatus,
  ) {
    return _orders
        .where((order) =>
            _isAlternativeOrderForApparatus(order, apparatus) &&
            !_alternativeOrderIsAssigned(order.map))
        .toList(growable: false);
  }

  bool _isAlternativeOrderForApparatus(
    ProductionMapSaved order,
    AdminWarehouse apparatus,
  ) {
    return order.map.nodes.any((node) {
      return node.kind == 'apparatus' &&
          node.alternativeGroupId.trim().isNotEmpty &&
          productionMapWarehouseTitlesMatch(node.title, apparatus.warehouse);
    });
  }

  bool _hasAlternativeApparatus(ProductionMapDefinition map) {
    return map.nodes.any(
      (node) =>
          node.kind == 'apparatus' && node.alternativeGroupId.trim().isNotEmpty,
    );
  }

  bool _alternativeOrderIsAssigned(ProductionMapDefinition map) {
    return map.nodes.any(
      (node) =>
          node.kind == 'apparatus' &&
          node.alternativeGroupId.trim().isNotEmpty &&
          node.alternativeAssignedTitle.trim().isNotEmpty,
    );
  }

  bool _alternativeOrderAssignedToApparatus(
    ProductionMapDefinition map,
    AdminWarehouse apparatus,
  ) {
    final title = apparatus.warehouse.trim();
    return map.nodes.any(
      (node) =>
          node.kind == 'apparatus' &&
          node.alternativeGroupId.trim().isNotEmpty &&
          productionMapWarehouseTitlesMatch(
            node.alternativeAssignedTitle,
            title,
          ),
    );
  }

  String? _assignedAlternativeGroupIdForApparatus(
    ProductionMapDefinition map,
    String apparatusTitle,
  ) {
    for (final node in map.nodes) {
      if (node.kind == 'apparatus' &&
          node.alternativeGroupId.trim().isNotEmpty &&
          productionMapWarehouseTitlesMatch(
            node.alternativeAssignedTitle,
            apparatusTitle,
          )) {
        return node.alternativeGroupId.trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 136.0;
    final workerTitle = () {
      final name = AppSession.instance.profile?.displayName.trim() ?? '';
      if (name.isNotEmpty) {
        return name;
      }
      return userRoleLabel(UserRole.aparatchi);
    }();
    return AppShell(
      drawer: widget.workerMode
          ? AparatchiNavigationDrawer(
              selectedIndex: 0,
              onNavigate: _openDrawerRoute,
            )
          : AdminNavigationDrawer(
              selectedIndex: 0,
              selectedRouteName: AppRoutes.adminProductionMapOrders,
              onNavigate: _openDrawerRoute,
            ),
      title: widget.workerMode ? workerTitle : 'reja menu',
      subtitle: widget.workerMode ? 'Kuzatish' : '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      bottom: widget.workerMode
          ? const AparatchiDock(activeTab: AparatchiDockTab.home)
          : AdminDock(
              activeTab: AdminDockTab.home,
              showPrimaryFab: _module != _OpenedOrderModule.sequence &&
                  _module != _OpenedOrderModule.move,
            ),
      bottomDockFadeStrength: null,
      contentPadding: EdgeInsets.zero,
      child: _loading
          ? const Center(child: AppLoadingIndicator())
          : widget.workerMode
              ? _buildWorkerWatchBody(bottomPadding)
              : Column(
                  children: [
                    if (_modules.length > 1)
                      TabBar(
                        controller: _tabController,
                        onTap: (index) => _setModule(_modules[index]),
                        tabs: [
                          for (final module in _modules)
                            Tab(text: _moduleLabel(module)),
                        ],
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          for (final module in _modules)
                            switch (module) {
                              _OpenedOrderModule.orders => _OrdersModulePage(
                                  bottomPadding: bottomPadding,
                                  searchController: _searchController,
                                  orders: _orders,
                                  visibleOrders: _visibleOrders(),
                                  onSearchChanged: (value) {
                                    setState(() => _searchQuery = value);
                                  },
                                  onSearchClear: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  onTapOrder:
                                      widget.readOnly ? null : _openOrder,
                                ),
                              _OpenedOrderModule.sequence =>
                                _SequenceModulePage(
                                  bottomPadding: bottomPadding,
                                  apparatus: _selectedApparatus,
                                  orders: _selectedApparatus == null
                                      ? const []
                                      : _ordersForApparatus(
                                          _selectedApparatus!),
                                  readOnly: widget.readOnly,
                                  onPickApparatus: _pickSequenceApparatus,
                                  onReorder: (oldIndex, newIndex) {
                                    unawaited(
                                      _reorderSelectedApparatusOrders(
                                        oldIndex,
                                        newIndex,
                                      ),
                                    );
                                  },
                                  onTapOrder: widget.readOnly
                                      ? _showOrderDetail
                                      : _openOrder,
                                ),
                              _OpenedOrderModule.move => _MoveModulePage(
                                  topApparatus: _moveTopApparatus,
                                  bottomApparatus: _moveBottomApparatus,
                                  topOrders: _moveTopApparatus == null ||
                                          _moveBottomApparatus == null
                                      ? const []
                                      : _moveOrdersForApparatus(
                                          source: _moveTopApparatus!,
                                          target: _moveBottomApparatus!,
                                        ),
                                  bottomOrders: _moveTopApparatus == null ||
                                          _moveBottomApparatus == null
                                      ? const []
                                      : _moveOrdersForApparatus(
                                          source: _moveBottomApparatus!,
                                          target: _moveTopApparatus!,
                                        ),
                                  selectedOrderIds: _selectedMoveOrderIds,
                                  draggingOrders: _draggingMoveOrders,
                                  draggingSource: _draggingMoveSource,
                                  canMoveTo: (order, target, source) =>
                                      _canMoveOrderToApparatus(
                                    order,
                                    target,
                                    source: source,
                                  ),
                                  onPickTop: () =>
                                      _pickMoveApparatus(top: true),
                                  onPickBottom: () =>
                                      _pickMoveApparatus(top: false),
                                  onToggleSelect: _toggleMoveOrderSelection,
                                  buildDragPayload: _buildMoveDragPayload,
                                  onDragStarted: (payload) {
                                    setState(() {
                                      _draggingMoveOrders = payload.orders;
                                      _draggingMoveSource = payload.source;
                                    });
                                  },
                                  onDragEnded: () {
                                    setState(() {
                                      _draggingMoveOrders = const [];
                                      _draggingMoveSource = null;
                                    });
                                  },
                                  onMove: _moveOrdersBetweenApparatus,
                                ),
                            },
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildWorkerWatchBody(double bottomPadding) {
    if (_apparatus.isEmpty) {
      return const Center(
        child: _EmptyOpenedOrders(message: 'Aparatlar topilmadi'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: [
            for (final item in _apparatus)
              Tab(
                text: productionMapPechatTabLabel(item.warehouse),
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final item in _apparatus)
                _AparatchiWatchSequencePage(
                  apparatus: item,
                  orders: _ordersForApparatus(item),
                  bottomPadding: bottomPadding,
                  isAssigned: _isAssignedWatchApparatus(item),
                  queueStates: _queueStatesForApparatus(item),
                  onTapOrder: (order) => _showWatchOrderDetail(
                    apparatus: item,
                    order: order,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _moduleLabel(_OpenedOrderModule module) {
    return switch (module) {
      _OpenedOrderModule.orders => 'Zakazlar',
      _OpenedOrderModule.sequence => 'Ketma-ketlik',
      _OpenedOrderModule.move => 'Ko‘chirish',
    };
  }
}

class _OrdersModulePage extends StatelessWidget {
  const _OrdersModulePage({
    required this.bottomPadding,
    required this.searchController,
    required this.orders,
    required this.visibleOrders,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onTapOrder,
  });

  final double bottomPadding;
  final TextEditingController searchController;
  final List<ProductionMapSaved> orders;
  final List<ProductionMapSaved> visibleOrders;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final ValueChanged<ProductionMapSaved>? onTapOrder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
      children: [
        _OpenedOrderSearchField(
          controller: searchController,
          onChanged: onSearchChanged,
          onClear: onSearchClear,
        ),
        if (orders.isEmpty)
          const _EmptyOpenedOrders(message: 'Ochilgan zakaz yo‘q')
        else if (visibleOrders.isEmpty)
          const _EmptyOpenedOrders(message: 'Zakaz topilmadi')
        else
          _OpenedOrderList(
            orders: visibleOrders,
            onTapOrder: onTapOrder,
          ),
      ],
    );
  }
}

class _AparatchiWatchSequencePage extends StatelessWidget {
  const _AparatchiWatchSequencePage({
    required this.apparatus,
    required this.orders,
    required this.bottomPadding,
    required this.isAssigned,
    required this.queueStates,
    required this.onTapOrder,
  });

  final AdminWarehouse apparatus;
  final List<ProductionMapSaved> orders;
  final double bottomPadding;
  final bool isAssigned;
  final Map<String, String> queueStates;
  final ValueChanged<ProductionMapSaved> onTapOrder;

  Color? _cardBackground(ApparatusQueueOrderState state) {
    return switch (state) {
      ApparatusQueueOrderState.inProgress => const Color(0xFFFFECB3),
      ApparatusQueueOrderState.completed => const Color(0xFFC8E6C9),
      ApparatusQueueOrderState.pending => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      children: [
        if (isAssigned)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Sizning aparatingiz',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (orders.isEmpty)
          _EmptyOpenedOrders(
            message: '${apparatus.warehouse} uchun zakaz yo‘q',
          )
        else
          for (var index = 0; index < orders.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index < orders.length - 1 ? 8 : 0,
              ),
              child: _SequenceOrderRow(
                slot: M3SegmentVerticalSlot.top,
                borderRadiusOverride: BorderRadius.circular(
                  M3SegmentedListGeometry.cornerLarge,
                ),
                backgroundColor: _cardBackground(
                  apparatusQueueOrderStateFromRaw(
                    queueStates[orders[index].map.id.trim()],
                  ),
                ),
                order: orders[index],
                index: index,
                readOnly: true,
                onTap: () => onTapOrder(orders[index]),
              ),
            ),
      ],
    );
  }
}

class _SequenceModulePage extends StatelessWidget {
  const _SequenceModulePage({
    required this.bottomPadding,
    required this.apparatus,
    required this.orders,
    required this.readOnly,
    required this.onPickApparatus,
    required this.onReorder,
    required this.onTapOrder,
  });

  final double bottomPadding;
  final AdminWarehouse? apparatus;
  final List<ProductionMapSaved> orders;
  final bool readOnly;
  final VoidCallback onPickApparatus;
  final ReorderCallback onReorder;
  final ValueChanged<ProductionMapSaved>? onTapOrder;

  @override
  Widget build(BuildContext context) {
    final selected = apparatus;
    final list = selected == null
        ? const <Widget>[]
        : orders.isEmpty
            ? <Widget>[
                _EmptyOpenedOrders(
                  message: '${selected.warehouse} uchun zakaz yo‘q',
                ),
              ]
            : readOnly
                ? [
                    for (var index = 0; index < orders.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index < orders.length - 1
                              ? M3SegmentedListGeometry.gap
                              : 0,
                        ),
                        child: _SequenceOrderRow(
                          slot: M3SegmentedListGeometry
                              .standaloneListSlotForIndex(
                            index,
                            orders.length,
                          ),
                          order: orders[index],
                          index: index,
                          readOnly: true,
                          onTap: onTapOrder == null
                              ? null
                              : () => onTapOrder!(orders[index]),
                        ),
                      ),
                  ]
                : [
                    for (var index = 0; index < orders.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index < orders.length - 1
                              ? M3SegmentedListGeometry.gap
                              : 0,
                        ),
                        child: _SequenceOrderRow(
                          slot: M3SegmentedListGeometry
                              .standaloneListSlotForIndex(
                            index,
                            orders.length,
                          ),
                          order: orders[index],
                          index: index,
                          readOnly: false,
                          onTap: onTapOrder == null
                              ? null
                              : () => onTapOrder!(orders[index]),
                        ),
                      ),
                  ];

    if (!readOnly && selected != null && orders.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _SequenceApparatusSelector(
              selected: selected,
              onTap: onPickApparatus,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              key: ValueKey(
                'sequence-list-${selected.warehouse}-'
                '${orders.map((order) => order.map.id).join(',')}',
              ),
              padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
              buildDefaultDragHandles: false,
              itemCount: orders.length,
              onReorderItem: onReorder,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  key: ValueKey(
                    'sequence-${selected.warehouse}-${order.map.id}',
                  ),
                  padding: EdgeInsets.only(
                    bottom: index < orders.length - 1
                        ? M3SegmentedListGeometry.gap
                        : 0,
                  ),
                  child: _SequenceOrderRow(
                    slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
                      index,
                      orders.length,
                    ),
                    order: order,
                    index: index,
                    readOnly: false,
                    onTap: onTapOrder == null ? null : () => onTapOrder!(order),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      children: [
        _SequenceApparatusSelector(
          selected: selected,
          onTap: onPickApparatus,
        ),
        if (selected == null)
          const _EmptyOpenedOrders(message: 'Avval aparat tanlang')
        else
          ...list,
      ],
    );
  }
}

class _SequenceApparatusSelector extends StatelessWidget {
  const _SequenceApparatusSelector({
    required this.selected,
    required this.onTap,
  });

  final AdminWarehouse? selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final selectedTitle = selected?.warehouse.trim() ?? '';
    final hasValue = selectedTitle.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        label: 'Aparatlar',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: InputDecorator(
            isFocused: false,
            decoration: InputDecoration(
              labelText: 'Aparatlar',
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              prefixIcon: Icon(
                Icons.precision_manufacturing_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Text(
              hasValue ? selectedTitle : 'Tanlang',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveModulePage extends StatefulWidget {
  const _MoveModulePage({
    required this.topApparatus,
    required this.bottomApparatus,
    required this.topOrders,
    required this.bottomOrders,
    required this.selectedOrderIds,
    required this.draggingOrders,
    required this.draggingSource,
    required this.canMoveTo,
    required this.onPickTop,
    required this.onPickBottom,
    required this.onToggleSelect,
    required this.buildDragPayload,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onMove,
  });

  final AdminWarehouse? topApparatus;
  final AdminWarehouse? bottomApparatus;
  final List<ProductionMapSaved> topOrders;
  final List<ProductionMapSaved> bottomOrders;
  final Set<String> selectedOrderIds;
  final List<ProductionMapSaved> draggingOrders;
  final AdminWarehouse? draggingSource;
  final bool Function(
    ProductionMapSaved order,
    AdminWarehouse target,
    AdminWarehouse source,
  ) canMoveTo;
  final VoidCallback onPickTop;
  final VoidCallback onPickBottom;
  final ValueChanged<String> onToggleSelect;
  final _MoveDragPayload Function({
    required ProductionMapSaved order,
    required AdminWarehouse source,
    required List<ProductionMapSaved> zoneOrders,
  }) buildDragPayload;
  final ValueChanged<_MoveDragPayload> onDragStarted;
  final VoidCallback onDragEnded;
  final Future<void> Function({
    required List<ProductionMapSaved> orders,
    required AdminWarehouse from,
    required AdminWarehouse to,
  }) onMove;

  @override
  State<_MoveModulePage> createState() => _MoveModulePageState();
}

class _MoveModulePageState extends State<_MoveModulePage> {
  double _topZoneRatio = 0.5;

  AdminWarehouse? get topApparatus => widget.topApparatus;
  AdminWarehouse? get bottomApparatus => widget.bottomApparatus;
  List<ProductionMapSaved> get topOrders => widget.topOrders;
  List<ProductionMapSaved> get bottomOrders => widget.bottomOrders;
  Set<String> get selectedOrderIds => widget.selectedOrderIds;
  List<ProductionMapSaved> get draggingOrders => widget.draggingOrders;
  AdminWarehouse? get draggingSource => widget.draggingSource;
  bool Function(
    ProductionMapSaved order,
    AdminWarehouse target,
    AdminWarehouse source,
  ) get canMoveTo => widget.canMoveTo;
  VoidCallback get onPickTop => widget.onPickTop;
  VoidCallback get onPickBottom => widget.onPickBottom;
  ValueChanged<String> get onToggleSelect => widget.onToggleSelect;
  _MoveDragPayload Function({
    required ProductionMapSaved order,
    required AdminWarehouse source,
    required List<ProductionMapSaved> zoneOrders,
  }) get buildDragPayload => widget.buildDragPayload;
  ValueChanged<_MoveDragPayload> get onDragStarted => widget.onDragStarted;
  VoidCallback get onDragEnded => widget.onDragEnded;
  Future<void> Function({
    required List<ProductionMapSaved> orders,
    required AdminWarehouse from,
    required AdminWarehouse to,
  }) get onMove => widget.onMove;

  void _resizeMoveZones(double delta, double availableHeight) {
    if (!availableHeight.isFinite || availableHeight <= 0) {
      return;
    }
    final next = (_topZoneRatio + delta / availableHeight).clamp(0.24, 0.76);
    if (next == _topZoneRatio) {
      return;
    }
    setState(() => _topZoneRatio = next);
  }

  @override
  Widget build(BuildContext context) {
    final top = topApparatus;
    final bottom = bottomApparatus;
    if (top == null || bottom == null) {
      return const _EmptyOpenedOrders(message: 'Ko‘chirish uchun aparat yo‘q');
    }
    final viewMetrics = MediaQueryData.fromView(View.of(context));
    final dockInset = dockLayoutBottomInset(
      viewMetrics,
      thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
    );
    final bottomInset = 60 + dockInset;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height * 0.7;
          final topFlex = (_topZoneRatio.clamp(0.24, 0.76) * 1000).round();
          final bottomFlex = 1000 - topFlex;
          return Column(
            children: [
              Expanded(
                flex: topFlex,
                child: Column(
                  children: [
                    _MoveApparatusHeader(
                      key: const ValueKey('move-top-apparatus-picker'),
                      apparatus: top,
                      alignment: Alignment.centerLeft,
                      onTap: onPickTop,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _MoveDropZone(
                        apparatus: top,
                        orders: topOrders,
                        selectedOrderIds: selectedOrderIds,
                        draggingOrders: draggingOrders,
                        draggingSource: draggingSource,
                        canMoveTo: canMoveTo,
                        onToggleSelect: onToggleSelect,
                        buildDragPayload: buildDragPayload,
                        onDragStarted: onDragStarted,
                        onDragEnded: onDragEnded,
                        onMove: onMove,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _MoveBoundary(
                  apparatus: bottom,
                  onTap: onPickBottom,
                  onVerticalDragUpdate: (delta) {
                    _resizeMoveZones(delta, availableHeight);
                  },
                ),
              ),
              Expanded(
                flex: bottomFlex,
                child: _MoveDropZone(
                  apparatus: bottom,
                  orders: bottomOrders,
                  selectedOrderIds: selectedOrderIds,
                  draggingOrders: draggingOrders,
                  draggingSource: draggingSource,
                  canMoveTo: canMoveTo,
                  onToggleSelect: onToggleSelect,
                  buildDragPayload: buildDragPayload,
                  onDragStarted: onDragStarted,
                  onDragEnded: onDragEnded,
                  onMove: onMove,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MoveDropZone extends StatelessWidget {
  const _MoveDropZone({
    required this.apparatus,
    required this.orders,
    required this.selectedOrderIds,
    required this.draggingOrders,
    required this.draggingSource,
    required this.canMoveTo,
    required this.onToggleSelect,
    required this.buildDragPayload,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onMove,
  });

  final AdminWarehouse apparatus;
  final List<ProductionMapSaved> orders;
  final Set<String> selectedOrderIds;
  final List<ProductionMapSaved> draggingOrders;
  final AdminWarehouse? draggingSource;
  final bool Function(
    ProductionMapSaved order,
    AdminWarehouse target,
    AdminWarehouse source,
  ) canMoveTo;
  final ValueChanged<String> onToggleSelect;
  final _MoveDragPayload Function({
    required ProductionMapSaved order,
    required AdminWarehouse source,
    required List<ProductionMapSaved> zoneOrders,
  }) buildDragPayload;
  final ValueChanged<_MoveDragPayload> onDragStarted;
  final VoidCallback onDragEnded;
  final Future<void> Function({
    required List<ProductionMapSaved> orders,
    required AdminWarehouse from,
    required AdminWarehouse to,
  }) onMove;

  @override
  Widget build(BuildContext context) {
    final draggingIds = {
      for (final order in draggingOrders) order.map.id.trim(),
    };
    final dragSource = draggingSource;
    final isDropTarget = dragSource != null &&
        dragSource.warehouse.trim() != apparatus.warehouse.trim();
    final blocked = isDropTarget &&
        draggingOrders.isNotEmpty &&
        draggingOrders.any(
          (order) => !canMoveTo(order, apparatus, dragSource),
        );
    return DragTarget<_MoveDragPayload>(
      onWillAcceptWithDetails: (details) {
        if (details.data.source.warehouse.trim() ==
            apparatus.warehouse.trim()) {
          return false;
        }
        return details.data.orders.every(
          (order) => canMoveTo(order, apparatus, details.data.source),
        );
      },
      onAcceptWithDetails: (details) {
        onMove(
          orders: details.data.orders,
          from: details.data.source,
          to: apparatus,
        );
      },
      builder: (context, candidate, rejected) {
        final showBlocked = blocked || rejected.isNotEmpty;
        final zoneBody = orders.isEmpty
            ? _MoveEmptyZone(apparatus: apparatus)
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderId = order.map.id.trim();
                  final isDragging = draggingIds.contains(orderId);
                  final slot =
                      M3SegmentedListGeometry.standaloneListSlotForIndex(
                    index,
                    orders.length,
                  );
                  if (isDragging) {
                    return const AnimatedSize(
                      duration: Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox.shrink(),
                    );
                  }
                  final payload = buildDragPayload(
                    order: order,
                    source: apparatus,
                    zoneOrders: orders,
                  );
                  return Padding(
                    key: ValueKey(
                      'move-order-${apparatus.warehouse}-${order.map.id}',
                    ),
                    padding: EdgeInsets.only(
                      bottom: index < orders.length - 1
                          ? M3SegmentedListGeometry.gap
                          : 0,
                    ),
                    child: _MoveOrderTile(
                      order: order,
                      source: apparatus,
                      index: index,
                      slot: slot,
                      selected: selectedOrderIds.contains(orderId),
                      payload: payload,
                      onToggleSelect: () => onToggleSelect(orderId),
                      onDragStarted: () => onDragStarted(payload),
                      onDragEnded: onDragEnded,
                    ),
                  );
                },
              );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: showBlocked
                ? ImageFiltered(
                    key: const ValueKey('move-zone-blocked'),
                    imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Opacity(
                      opacity: 0.42,
                      child: IgnorePointer(
                        child: zoneBody,
                      ),
                    ),
                  )
                : KeyedSubtree(
                    key: const ValueKey('move-zone-active'),
                    child: zoneBody,
                  ),
          ),
        );
      },
    );
  }
}

class _MoveApparatusHeader extends StatelessWidget {
  const _MoveApparatusHeader({
    super.key,
    required this.apparatus,
    required this.alignment,
    required this.onTap,
  });

  final AdminWarehouse apparatus;
  final Alignment alignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: alignment,
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.precision_manufacturing_rounded,
                  size: 16,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    apparatus.warehouse,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: scheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveBoundary extends StatelessWidget {
  const _MoveBoundary({
    required this.apparatus,
    required this.onTap,
    required this.onVerticalDragUpdate,
  });

  final AdminWarehouse apparatus;
  final VoidCallback onTap;
  final ValueChanged<double> onVerticalDragUpdate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Listener(
      key: const ValueKey('move-boundary-apparatus-picker'),
      behavior: HitTestBehavior.opaque,
      onPointerMove: (event) => onVerticalDragUpdate(event.delta.dy),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Expanded(child: Divider(color: scheme.outlineVariant)),
            IgnorePointer(
              child: _MoveApparatusHeader(
                apparatus: apparatus,
                alignment: Alignment.center,
                onTap: onTap,
              ),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
          ],
        ),
      ),
    );
  }
}

class _MoveOrderTile extends StatelessWidget {
  const _MoveOrderTile({
    required this.order,
    required this.source,
    required this.index,
    required this.slot,
    required this.selected,
    required this.payload,
    required this.onToggleSelect,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final ProductionMapSaved order;
  final AdminWarehouse source;
  final int index;
  final M3SegmentVerticalSlot slot;
  final bool selected;
  final _MoveDragPayload payload;
  final VoidCallback onToggleSelect;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final feedbackRadius = BorderRadius.circular(
          M3SegmentedListGeometry.cornerLarge,
        );
        final scheme = Theme.of(context).colorScheme;
        final batchCount = payload.orders.length;
        return _MoveOrderCard(
          order: order,
          index: index,
          slot: slot,
          selected: selected,
          onToggleSelect: onToggleSelect,
          trailing: LongPressDraggable<_MoveDragPayload>(
            data: payload,
            axis: Axis.vertical,
            childWhenDragging: const SizedBox.shrink(),
            dragAnchorStrategy: (_, handleContext, position) {
              final box = handleContext.findRenderObject()! as RenderBox;
              final local = box.globalToLocal(position);
              return Offset(cardWidth - 28, local.dy);
            },
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: cardWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MoveOrderCard(
                      order: order,
                      index: index,
                      slot: M3SegmentVerticalSlot.top,
                      selected: selected,
                      borderRadiusOverride: feedbackRadius,
                    ),
                    if (batchCount > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '$batchCount ta zakaz',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            onDragStarted: onDragStarted,
            onDragEnd: (_) => onDragEnded(),
            onDraggableCanceled: (_, __) => onDragEnded(),
            child: _MoveDragHandle(
              color: scheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

class _MoveDragPayload {
  const _MoveDragPayload({
    required this.orders,
    required this.source,
  });

  final List<ProductionMapSaved> orders;
  final AdminWarehouse source;
}

class _MoveOrderCard extends StatelessWidget {
  const _MoveOrderCard({
    required this.order,
    required this.index,
    required this.slot,
    this.selected = false,
    this.onToggleSelect,
    this.trailing,
    this.borderRadiusOverride,
  });

  final ProductionMapSaved order;
  final int index;
  final M3SegmentVerticalSlot slot;
  final bool selected;
  final VoidCallback? onToggleSelect;
  final Widget? trailing;
  final BorderRadius? borderRadiusOverride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _OpenedOrderCardRow(
      slot: slot,
      order: order,
      onTap: onToggleSelect,
      borderRadiusOverride: borderRadiusOverride,
      leading: _OpenedOrderIndexBadge(
        index: index,
        selected: selected,
        onTap: onToggleSelect,
      ),
      trailing: trailing ?? _MoveDragHandle(color: scheme.onSurfaceVariant),
    );
  }
}

class _MoveDragHandle extends StatelessWidget {
  const _MoveDragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(
        Icons.drag_handle_rounded,
        color: color,
      ),
    );
  }
}

class _MoveEmptyZone extends StatelessWidget {
  const _MoveEmptyZone({required this.apparatus});

  final AdminWarehouse apparatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = _isMoveUnassignedApparatus(apparatus)
        ? 'Tanlanmagan zakaz yo‘q'
        : '${apparatus.warehouse} uchun zakaz yo‘q';
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ApparatusPickerSheet extends StatelessWidget {
  const _ApparatusPickerSheet({
    required this.apparatus,
    this.selected,
    this.orderCountFor,
    this.showUnassigned = false,
    this.unassignedOrderCount = 0,
  });

  final List<AdminWarehouse> apparatus;
  final AdminWarehouse? selected;
  final int Function(AdminWarehouse apparatus)? orderCountFor;
  final bool showUnassigned;
  final int unassignedOrderCount;

  @override
  Widget build(BuildContext context) {
    final sheetHeight =
        (MediaQuery.sizeOf(context).height * 0.52).clamp(360.0, 520.0);
    return SafeArea(
      child: SizedBox(
        height: sheetHeight.toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Aparat tanlang',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ApparatusPickerList(
                apparatus: apparatus,
                selected: selected,
                orderCountFor: orderCountFor,
                showUnassigned: showUnassigned,
                unassignedOrderCount: unassignedOrderCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApparatusPickerList extends StatelessWidget {
  const _ApparatusPickerList({
    required this.apparatus,
    this.selected,
    this.orderCountFor,
    this.showUnassigned = false,
    this.unassignedOrderCount = 0,
  });

  final List<AdminWarehouse> apparatus;
  final AdminWarehouse? selected;
  final int Function(AdminWarehouse apparatus)? orderCountFor;
  final bool showUnassigned;
  final int unassignedOrderCount;

  @override
  Widget build(BuildContext context) {
    final itemCount = apparatus.length + (showUnassigned ? 1 : 0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        M3SegmentSpacedColumn(
          children: [
            if (showUnassigned)
              _ApparatusRow(
                slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
                  0,
                  itemCount,
                ),
                apparatus: _moveUnassignedWarehouse,
                selected: _isMoveUnassignedApparatus(selected),
                orderCount: unassignedOrderCount,
                onTap: () =>
                    Navigator.of(context).pop(_moveUnassignedWarehouse),
              ),
            for (var index = 0; index < apparatus.length; index++)
              _ApparatusRow(
                slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
                  index + (showUnassigned ? 1 : 0),
                  itemCount,
                ),
                apparatus: apparatus[index],
                selected: selected?.warehouse == apparatus[index].warehouse,
                orderCount: orderCountFor?.call(apparatus[index]) ?? 0,
                onTap: () => Navigator.of(context).pop(apparatus[index]),
              ),
          ],
        ),
      ],
    );
  }
}

class _OpenedOrderSearchField extends StatelessWidget {
  const _OpenedOrderSearchField({
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
              hintText: 'Ochilgan zakaz qidirish',
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

class _OpenedOrderList extends StatelessWidget {
  const _OpenedOrderList({
    required this.orders,
    required this.onTapOrder,
  });

  final List<ProductionMapSaved> orders;
  final ValueChanged<ProductionMapSaved>? onTapOrder;

  @override
  Widget build(BuildContext context) {
    return M3SegmentSpacedColumn(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (var index = 0; index < orders.length; index++)
          _OpenedOrderRow(
            slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
              index,
              orders.length,
            ),
            order: orders[index],
            onTap: onTapOrder == null ? null : () => onTapOrder!(orders[index]),
          ),
      ],
    );
  }
}

class _OpenedOrderCardRow extends StatelessWidget {
  const _OpenedOrderCardRow({
    required this.slot,
    required this.order,
    required this.leading,
    required this.trailing,
    this.onTap,
    this.includeApparatusCount = false,
    this.borderRadiusOverride,
    this.backgroundColor,
  });

  final M3SegmentVerticalSlot slot;
  final ProductionMapSaved order;
  final Widget leading;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool includeApparatusCount;
  final BorderRadius? borderRadiusOverride;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final map = order.map;
    final subtitle = _openedOrderSubtitle(
      map,
      includeApparatusCount: includeApparatusCount,
    );

    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: M3SegmentedListGeometry.cornerRadiusForSlot(slot),
      borderRadiusOverride: borderRadiusOverride,
      backgroundColor: backgroundColor,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OpenedOrderTitleLine(
                    map: map,
                    theme: theme,
                    scheme: scheme,
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
            trailing,
          ],
        ),
      ),
    );
  }
}

class _OpenedOrderTitleLine extends StatelessWidget {
  const _OpenedOrderTitleLine({
    required this.map,
    required this.theme,
    required this.scheme,
    this.titleStyle,
    this.codeStyle,
  });

  final ProductionMapDefinition map;
  final ThemeData theme;
  final ColorScheme scheme;
  final TextStyle? titleStyle;
  final TextStyle? codeStyle;

  @override
  Widget build(BuildContext context) {
    final code = _openedOrderDisplayCode(map);
    final title = _openedOrderPrimaryTitle(map);
    final resolvedTitleStyle = titleStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final resolvedCodeStyle = codeStyle ??
        theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        );
    if (code.isEmpty) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: resolvedTitleStyle,
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: code,
            style: resolvedCodeStyle,
          ),
          TextSpan(
            text: ' • ',
            style: resolvedCodeStyle?.copyWith(
              color: scheme.outline,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: title,
            style: resolvedTitleStyle,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _OpenedOrderIndexBadge extends StatelessWidget {
  const _OpenedOrderIndexBadge({
    required this.index,
    this.selected = false,
    this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badge = SizedBox.square(
      dimension: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
    if (onTap == null) {
      return badge;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: badge,
      ),
    );
  }
}

class _OpenedOrderTreeBadge extends StatelessWidget {
  const _OpenedOrderTreeBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.account_tree_outlined,
          color: scheme.onPrimaryContainer,
          size: 16,
        ),
      ),
    );
  }
}

class _OpenedOrderRow extends StatelessWidget {
  const _OpenedOrderRow({
    required this.slot,
    required this.order,
    required this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final ProductionMapSaved order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _OpenedOrderCardRow(
      slot: slot,
      order: order,
      onTap: onTap,
      includeApparatusCount: true,
      leading: const _OpenedOrderTreeBadge(),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _ApparatusRow extends StatelessWidget {
  const _ApparatusRow({
    required this.slot,
    required this.apparatus,
    required this.selected,
    required this.orderCount,
    required this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final AdminWarehouse apparatus;
  final bool selected;
  final int orderCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = M3SegmentedListGeometry.borderRadius(
      slot,
      M3SegmentedListGeometry.cornerRadiusForSlot(slot),
    );
    return Material(
      color:
          selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 32,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.surface.withValues(alpha: 0.72)
                        : scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.precision_manufacturing_rounded,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onPrimaryContainer,
                    size: 17,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apparatus.warehouse,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$orderCount ta zakaz',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
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

class _SequenceOrderRow extends StatelessWidget {
  const _SequenceOrderRow({
    required this.slot,
    required this.order,
    required this.index,
    required this.readOnly,
    required this.onTap,
    this.borderRadiusOverride,
    this.backgroundColor,
  });

  final M3SegmentVerticalSlot slot;
  final ProductionMapSaved order;
  final int index;
  final bool readOnly;
  final VoidCallback? onTap;
  final BorderRadius? borderRadiusOverride;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _OpenedOrderCardRow(
      slot: slot,
      order: order,
      onTap: onTap,
      borderRadiusOverride: borderRadiusOverride,
      backgroundColor: backgroundColor,
      leading: _OpenedOrderIndexBadge(index: index),
      trailing: readOnly
          ? const SizedBox(width: 8)
          : ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
    );
  }
}

class _EmptyOpenedOrders extends StatelessWidget {
  const _EmptyOpenedOrders({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 0),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ReadOnlyOrderDetailSheet extends StatefulWidget {
  const _ReadOnlyOrderDetailSheet({
    required this.order,
    this.apparatus,
    this.canManageQueue = false,
    this.initialQueueStates = const {},
    this.queueStatesByApparatus = const {},
    this.isOrderReadyForStation,
    this.sequenceOrderIds = const [],
    this.visibleOrderIds = const [],
    this.onQueueAction,
  });

  final ProductionMapSaved order;
  final AdminWarehouse? apparatus;
  final bool canManageQueue;
  final Map<String, String> initialQueueStates;
  final Map<String, Map<String, String>> queueStatesByApparatus;
  final bool Function(String orderId)? isOrderReadyForStation;
  final List<String> sequenceOrderIds;
  final List<String> visibleOrderIds;
  final Future<Map<String, String>?> Function({
    required AdminWarehouse apparatus,
    required ProductionMapSaved order,
    required String action,
  })? onQueueAction;

  @override
  State<_ReadOnlyOrderDetailSheet> createState() =>
      _ReadOnlyOrderDetailSheetState();
}

class _ReadOnlyOrderDetailSheetState extends State<_ReadOnlyOrderDetailSheet> {
  late Map<String, String> _queueStates;
  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    _queueStates = Map<String, String>.from(widget.initialQueueStates);
  }

  @override
  void didUpdateWidget(covariant _ReadOnlyOrderDetailSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_actionInFlight) {
      return;
    }
    final apparatus = widget.apparatus?.warehouse.trim() ?? '';
    if (apparatus.isEmpty) {
      return;
    }
    final nextStates = _queueStatesForStation(
      apparatus,
      widget.queueStatesByApparatus,
    );
    if (!mapEquals(_queueStates, nextStates)) {
      setState(() => _queueStates = Map<String, String>.from(nextStates));
    }
  }

  Map<String, String> _queueStatesForStation(
    String station,
    Map<String, Map<String, String>> queueStatesByApparatus,
  ) {
    final direct = queueStatesByApparatus[station];
    if (direct != null) {
      return direct;
    }
    for (final entry in queueStatesByApparatus.entries) {
      if (productionMapWarehouseTitlesMatch(entry.key, station)) {
        return entry.value;
      }
    }
    return const {};
  }

  Future<void> _runQueueAction(String action) async {
    final apparatus = widget.apparatus;
    final onQueueAction = widget.onQueueAction;
    if (apparatus == null || onQueueAction == null || _actionInFlight) {
      return;
    }
    setState(() => _actionInFlight = true);
    final states = await onQueueAction(
      apparatus: apparatus,
      order: widget.order,
      action: action,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _actionInFlight = false;
      if (states != null) {
        _queueStates = states;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final map = widget.order.map;
    final steps = _linearNodes(map);
    final orderId = map.id.trim();
    final station = widget.apparatus?.warehouse.trim() ?? '';
    final queueState = apparatusQueueOrderStateFromRaw(_queueStates[orderId]);
    final chainReady = station.isEmpty ||
        productionMapOrderReadyForStation(
          map: map,
          orderId: orderId,
          station: station,
          queueStatesByApparatus: widget.queueStatesByApparatus,
        );
    final previousStage = station.isEmpty
        ? null
        : productionMapPreviousWorkStageStation(map: map, station: station);
    final actionableId = widget.canManageQueue
        ? firstActionableQueueOrderId(
            sequence: widget.sequenceOrderIds.isNotEmpty
                ? widget.sequenceOrderIds
                : widget.visibleOrderIds,
            states: _queueStates,
            visibleOrderIds: widget.visibleOrderIds,
            isOrderReady: widget.isOrderReadyForStation,
          )
        : null;
    final isActionable = actionableId == orderId;
    final showStart = isActionable &&
        chainReady &&
        queueState == ApparatusQueueOrderState.pending;
    final showComplete =
        isActionable && queueState == ApparatusQueueOrderState.inProgress;
    final showWaitingForPrevious = widget.canManageQueue &&
        !chainReady &&
        queueState == ApparatusQueueOrderState.pending &&
        previousStage != null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _OpenedOrderTitleLine(
              map: map,
              theme: theme,
              scheme: scheme,
              titleStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              codeStyle: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            _DetailCard(
              children: [
                if (_openedOrderDisplayCode(map).isNotEmpty)
                  _DetailRow(
                    label: 'Zakaz kodi',
                    value: _openedOrderDisplayCode(map),
                  ),
                if (map.orderNumber.trim().isNotEmpty)
                  _DetailRow(label: 'Zakaz raqami', value: map.orderNumber),
                _DetailRow(label: 'Mahsulot', value: _productTitle(map)),
                if (map.productCode.trim().isNotEmpty)
                  _DetailRow(label: 'Kod', value: map.productCode),
              ],
            ),
            if (showStart || showComplete) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _actionInFlight
                    ? null
                    : () => unawaited(
                          _runQueueAction(showStart ? 'start' : 'complete'),
                        ),
                child: Text(showStart ? 'Boshlash' : 'Tugatish'),
              ),
            ],
            if (showWaitingForPrevious) ...[
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Oldingi bosqich tugallanguncha kutilmoqda: $previousStage',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Ketma-ketlik',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    for (var index = 0; index < steps.length; index++)
                      _SequenceStepTile(
                        node: steps[index],
                        index: index,
                        isLast: index == steps.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _productTitle(ProductionMapDefinition map) {
    for (final node in map.nodes) {
      final title = node.title.trim();
      if (node.kind == 'end' && title.isNotEmpty && title != map.title.trim()) {
        return title;
      }
    }
    return map.title;
  }

  List<ProductionMapNode> _linearNodes(ProductionMapDefinition map) {
    final byId = {for (final node in map.nodes) node.id: node};
    final byFrom = <String, List<ProductionMapEdge>>{};
    for (final edge in map.edges) {
      byFrom.putIfAbsent(edge.from, () => <ProductionMapEdge>[]).add(edge);
    }
    final start = map.nodes
        .where((node) => node.kind == 'start')
        .map((node) => node.id)
        .cast<String?>()
        .firstWhere((id) => id != null, orElse: () => null);
    if (start == null || !byId.containsKey(start)) {
      return map.nodes;
    }
    final result = <ProductionMapNode>[];
    final seen = <String>{};
    var current = start;
    while (seen.add(current)) {
      final node = byId[current];
      if (node != null) {
        result.add(node);
      }
      final next = byFrom[current]
          ?.map((edge) => edge.to)
          .where((id) => byId.containsKey(id))
          .cast<String?>()
          .firstWhere((id) => id != null, orElse: () => null);
      if (next == null) {
        break;
      }
      current = next;
    }
    return result.isEmpty ? map.nodes : result;
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(children: children),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SequenceStepTile extends StatelessWidget {
  const _SequenceStepTile({
    required this.node,
    required this.index,
    required this.isLast,
  });

  final ProductionMapNode node;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = switch (node.kind) {
      'start' => Icons.play_arrow_rounded,
      'apparatus' => Icons.precision_manufacturing_rounded,
      'kk_product' => Icons.inventory_2_outlined,
      'end' => Icons.flag_rounded,
      _ => Icons.account_tree_outlined,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              SizedBox.square(
                dimension: 34,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: scheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.title.trim().isEmpty
                        ? 'Qadam ${index + 1}'
                        : node.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _kindLabel(node.kind),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _kindLabel(String kind) {
    return switch (kind) {
      'start' => 'Boshlanish',
      'apparatus' => 'Aparat',
      'kk_product' => 'KK li mahsulot',
      'end' => 'Yakun',
      _ => kind,
    };
  }
}
