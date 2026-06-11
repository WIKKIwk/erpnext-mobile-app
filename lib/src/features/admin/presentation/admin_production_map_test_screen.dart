import 'dart:async';
import 'dart:math' as math;

import '../../../app/app_router.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../shared/models/app_models.dart';
import '../../werka/presentation/widgets/m3_picker_sheet.dart';
import '../logic/production_map_pechat_rules.dart';
import '../models/production_map_models.dart';
import '../state/calculate_order_store.dart';
import 'widgets/admin_create_hub_sheet.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_top_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _maxLaminatsiyaRubberSizeMm = 1050;

String productionMapBranchDisplayLabel(String branch) {
  return switch (branch.trim().toLowerCase()) {
    'true' => 'Shunda',
    'false' => 'Aks holda',
    _ => branch,
  };
}

bool productionMapCanCreateEdge(
  ProductionMapNode from,
  ProductionMapNode to,
) {
  final hasKkProduct = from.kind == 'kk_product' || to.kind == 'kk_product';
  if (!hasKkProduct) {
    return true;
  }
  return (from.kind == 'kk_product' && to.kind == 'apparatus') ||
      (from.kind == 'apparatus' && to.kind == 'kk_product');
}

bool productionMapApparatusMatchesOrder(
  AdminWarehouse apparatus,
  ProductionMapOrderContext? orderContext,
) {
  if (productionMapIsLaminatsiyaApparatus(apparatus.warehouse) &&
      !_productionMapLaminatsiyaMatchesOrder(orderContext)) {
    return false;
  }
  final apparatusColorCount =
      productionMapPechatColorCount(apparatus.warehouse);
  if (apparatusColorCount == null) {
    return true;
  }
  final context = orderContext;
  if (context == null) {
    return true;
  }
  final recommended = productionMapRecommendedPechatColorCount(
    rollCount: context.rollCount,
    widthMm: context.widthMm,
  );
  if (recommended == null) {
    return context.rollCount == null && context.widthMm == null;
  }
  return productionMapPechatCanHandleOrder(
    apparatusColorCount: apparatusColorCount,
    rollCount: context.rollCount,
    widthMm: context.widthMm,
  );
}

bool _productionMapLaminatsiyaMatchesOrder(
  ProductionMapOrderContext? orderContext,
) {
  final widthMm = orderContext?.widthMm;
  if (widthMm == null || widthMm <= 0) {
    return true;
  }
  return productionMapRubberSizeFromWidth(widthMm) <=
      _maxLaminatsiyaRubberSizeMm;
}

const _formulaVariables = [
  _FormulaVariable(label: 'Buyurtma miqdori', token: 'order_qty'),
  _FormulaVariable(label: 'CPP kg', token: 'cpp_kg'),
  _FormulaVariable(label: 'Natija kg', token: 'result_kg'),
];

String _formulaDisplayText(String expression) {
  var text = expression;
  for (final variable in _formulaVariables) {
    text = text.replaceAllMapped(
      RegExp('\\b${RegExp.escape(variable.token)}\\b'),
      (_) => variable.label,
    );
  }
  return text;
}

String _formulaInternalText(String expression) {
  var text = expression;
  for (final variable in _formulaVariables) {
    text = text.replaceAll(
      RegExp(variable.label, caseSensitive: false),
      variable.token,
    );
  }
  return text;
}

class _FormulaVariable {
  const _FormulaVariable({
    required this.label,
    required this.token,
  });

  final String label;
  final String token;
}

class _FormulaAutocompleteController extends TextEditingController {
  _FormulaAutocompleteController({required String text}) : super(text: text);

  _FormulaVariable? get suggestion {
    final prefix = _currentSegment().trim().toLowerCase();
    if (prefix.length < 2) {
      return null;
    }
    for (final variable in _formulaVariables) {
      if (variable.label.toLowerCase().startsWith(prefix) ||
          variable.token.toLowerCase().startsWith(prefix)) {
        return variable;
      }
    }
    return null;
  }

  String get ghostCompletion {
    final active = suggestion;
    if (active == null) {
      return '';
    }
    final cursor = _cursor;
    if (cursor != text.length) {
      return '';
    }
    final prefix = _currentSegment().trim();
    if (prefix.isEmpty) {
      return '';
    }
    if (active.label.toLowerCase().startsWith(prefix.toLowerCase())) {
      return active.label.substring(prefix.length);
    }
    if (active.token.toLowerCase().startsWith(prefix.toLowerCase())) {
      return active.label;
    }
    return '';
  }

  int get _cursor {
    final selection = this.selection;
    return selection.isValid ? selection.baseOffset : text.length;
  }

  int segmentStart() {
    var start = _cursor.clamp(0, text.length);
    while (start > 0 && !'+-*/()<>!=&|,'.contains(text[start - 1])) {
      start--;
    }
    return start;
  }

  String _currentSegment() {
    final cursor = _cursor.clamp(0, text.length);
    return text.substring(segmentStart(), cursor);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final ghost = ghostCompletion;
    if (ghost.isEmpty) {
      return TextSpan(style: baseStyle, text: text);
    }
    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(text: text),
        TextSpan(
          text: ghost,
          style: baseStyle.copyWith(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.42),
          ),
        ),
      ],
    );
  }
}

class AdminProductionMapTestScreen extends StatefulWidget {
  const AdminProductionMapTestScreen({
    super.key,
    this.orderContext,
    this.savedMap,
  });

  final ProductionMapOrderContext? orderContext;
  final ProductionMapDefinition? savedMap;

  @override
  State<AdminProductionMapTestScreen> createState() =>
      _AdminProductionMapTestScreenState();
}

class ProductionMapOrderContext {
  const ProductionMapOrderContext({
    this.templateId = '',
    this.orderCode = '',
    required this.orderName,
    required this.productName,
    required this.itemCode,
    this.rollCount,
    this.widthMm,
    this.templateDraft,
  });

  final String templateId;
  final String orderCode;
  final String orderName;
  final String productName;
  final String itemCode;
  final double? rollCount;
  final double? widthMm;
  final CalculateOrderTemplate? templateDraft;
}

class _AdminProductionMapTestScreenState
    extends State<AdminProductionMapTestScreen> {
  static const _nodeGap = 18.0;
  static const _nodeStepX = 280.0;
  static const _nodeStepY = 132.0;
  static const _minNodeX = 24.0;
  static const _minNodeY = 24.0;
  static const _maxNodeX = 1600.0;
  static const _maxNodeY = 3200.0;

  late final bool _orderMode;
  late final List<ProductionMapNode> nodes;
  late final List<ProductionMapEdge> edges;

  int _nextNodeIndex = 1;
  String? _connectingFromNodeID;
  String _connectingFromBranch = '';
  Offset? _connectionPreviewEnd;
  bool _mapToolsMenuOpen = false;
  bool _savingMap = false;
  late String _orderNumber;
  CalculateOrderTemplate? _templateDraft;
  CalculateOrderTemplate? _lastSavedTemplate;
  List<AdminApparatusGroup> _apparatusGroups = const [];

  @override
  void initState() {
    super.initState();
    final savedMap = widget.savedMap;
    _orderMode = widget.orderContext != null ||
        (savedMap?.id.trim().startsWith('zakaz-') ?? false);
    nodes = savedMap != null
        ? List<ProductionMapNode>.from(savedMap.nodes)
        : _orderMode
            ? _orderFlowNodes(widget.orderContext!)
            : _defaultTestNodes();
    edges = savedMap != null
        ? List<ProductionMapEdge>.from(savedMap.edges)
        : _orderMode
            ? _orderFlowEdges()
            : _defaultTestEdges();
    _orderNumber = savedMap?.orderNumber.trim() ?? '';
    _templateDraft = widget.orderContext?.templateDraft;
    unawaited(_loadApparatusGroups());
  }

  Future<void> _loadApparatusGroups() async {
    try {
      final groups = await MobileApi.instance.adminApparatusGroups();
      if (mounted) {
        setState(() => _apparatusGroups = groups);
      }
    } catch (_) {
      return;
    }
  }

  List<ProductionMapNode> _defaultTestNodes() {
    return [
      const ProductionMapNode(
        id: 'start',
        kind: 'start',
        title: 'Start',
        x: 420,
        y: 32,
      ),
      const ProductionMapNode(
        id: 'cpp_calc',
        kind: 'formula',
        title: 'CPP hisob',
        x: 420,
        y: 164,
        formula: ProductionFormula(
          target: 'cpp_kg',
          expression: 'order_qty * 1.08',
        ),
      ),
      const ProductionMapNode(
        id: 'qty_check',
        kind: 'condition',
        title: 'Katta partiyami?',
        x: 420,
        y: 296,
        formula: ProductionFormula(
          target: '',
          expression: 'order_qty >= 100',
        ),
      ),
      const ProductionMapNode(
        id: 'end',
        kind: 'end',
        title: 'End',
        x: 420,
        y: 520,
      ),
    ];
  }

  List<ProductionMapEdge> _defaultTestEdges() {
    return [
      const ProductionMapEdge(from: 'start', to: 'cpp_calc'),
      const ProductionMapEdge(from: 'cpp_calc', to: 'qty_check'),
    ];
  }

  List<ProductionMapNode> _orderFlowNodes(ProductionMapOrderContext context) {
    final orderName =
        context.orderName.trim().isEmpty ? 'Zakaz' : context.orderName.trim();
    final productName = context.productName.trim().isEmpty
        ? 'Mahsulot'
        : context.productName.trim();
    return [
      const ProductionMapNode(
        id: 'start',
        kind: 'start',
        title: 'Start',
        x: 420,
        y: 32,
      ),
      ProductionMapNode(
        id: 'order',
        kind: 'task',
        title: orderName,
        roleCode: 'zakaz',
        x: 420,
        y: 164,
      ),
      ProductionMapNode(
        id: 'end',
        kind: 'end',
        title: productName,
        itemCode: context.itemCode,
        x: 420,
        y: 296,
      ),
    ];
  }

  List<ProductionMapEdge> _orderFlowEdges() {
    return [
      const ProductionMapEdge(from: 'start', to: 'order'),
      const ProductionMapEdge(from: 'order', to: 'end'),
    ];
  }

  Future<void> _saveMap() async {
    if (_savingMap) {
      return;
    }
    final orderNumber = _orderMode ? await _resolveOrderNumberForSave() : null;
    if (_orderMode && orderNumber == null) {
      return;
    }
    setState(() => _savingMap = true);
    try {
      final definition = _currentMapDefinition(orderNumber: orderNumber);
      final draft = _templateDraft;
      if (draft != null) {
        // Single server-side operation: map + zakaz saved together.
        final result = await MobileApi.instance.adminSaveProductionMapWithOrder(
          map: definition,
          template: draft,
        );
        if (!mounted) {
          return;
        }
        _lastSavedTemplate = result.template;
        _templateDraft = result.template ?? draft;
        final savedTemplate = result.template;
        if (savedTemplate != null) {
          CalculateOrderTemplateStore.instance.remember(savedTemplate);
        }
        if (orderNumber != null) {
          _orderNumber = orderNumber;
        }
        showAdminTopNotice(context, 'Production map va zakaz saqlandi');
      } else {
        await MobileApi.instance.adminSaveProductionMap(definition);
        if (!mounted) {
          return;
        }
        if (orderNumber != null) {
          _orderNumber = orderNumber;
        }
        showAdminTopNotice(context, 'Production map saqlandi');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAdminTopNotice(
        context,
        error is MobileApiException
            ? error.message
            : 'Production map saqlanmadi',
      );
    } finally {
      if (mounted) {
        setState(() => _savingMap = false);
      }
    }
  }

  bool get _orderNumberLocked =>
      RegExp(r'^\d{4}$').hasMatch(_orderNumber.trim());

  Future<String?> _resolveOrderNumberForSave() async {
    if (_orderNumberLocked) {
      return _orderNumber.trim();
    }
    return _requestOrderNumber();
  }

  Future<String?> _requestOrderNumber() {
    // Uniqueness is enforced server-side on save (duplicate_order_number);
    // the dialog only checks the 4-digit format.
    return showDialog<String>(
      context: context,
      builder: (context) => _ProductionMapOrderNumberDialog(
        initialValue: _orderNumber,
      ),
    );
  }

  ProductionMapDefinition _currentMapDefinition({String? orderNumber}) {
    final context = widget.orderContext;
    final savedMap = widget.savedMap;
    final normalizedOrderNumber = (orderNumber ?? _orderNumber).trim();
    final title = context == null
        ? (savedMap?.title.trim().isNotEmpty ?? false)
            ? savedMap!.title.trim()
            : 'Production map test'
        : (context.orderName.trim().isEmpty
            ? 'Zakaz'
            : context.orderName.trim());
    final productCode = context == null
        ? (savedMap?.productCode.trim().isNotEmpty ?? false)
            ? savedMap!.productCode.trim()
            : 'production-map-test'
        : _firstNonEmpty([
            context.itemCode,
            context.productName,
            context.orderName,
            context.templateId,
          ]);
    return ProductionMapDefinition(
      id: _orderMode
          ? ((savedMap?.id.trim().isNotEmpty ?? false)
              ? savedMap!.id.trim()
              : _zakazMapId(normalizedOrderNumber, context: context))
          : (context == null
              ? (savedMap?.id.trim().isNotEmpty ?? false)
                  ? savedMap!.id.trim()
                  : 'production-map-test'
              : _orderMapId(context, normalizedOrderNumber)),
      productCode: productCode,
      title: title,
      code: _orderMode && normalizedOrderNumber.isNotEmpty
          ? normalizedOrderNumber
          : _firstNonEmpty([
              context?.orderCode ?? '',
              savedMap?.code ?? '',
            ]),
      orderNumber: normalizedOrderNumber,
      // Re-saving an opened zakaz must keep its pechat constraints.
      rollCount: context?.rollCount ?? savedMap?.rollCount,
      widthMm: context?.widthMm ?? savedMap?.widthMm,
      nodes: List<ProductionMapNode>.unmodifiable(nodes),
      edges: List<ProductionMapEdge>.unmodifiable(edges),
    );
  }

  String _zakazMapId(
    String orderNumber, {
    ProductionMapOrderContext? context,
  }) {
    if (RegExp(r'^\d{4}$').hasMatch(orderNumber)) {
      return 'zakaz-$orderNumber';
    }
    if (context != null) {
      return _orderMapId(context, orderNumber);
    }
    return 'production-map-test';
  }

  String _orderMapId(ProductionMapOrderContext context, String orderNumber) {
    if (RegExp(r'^\d{4}$').hasMatch(orderNumber)) {
      return 'zakaz-$orderNumber';
    }
    final source = _firstNonEmpty([
      context.templateId,
      context.orderName,
      context.productName,
      context.itemCode,
    ]);
    return 'zakaz-${_slug(source)}';
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return 'zakaz';
  }

  String _slug(String value) {
    final lower = value.trim().toLowerCase();
    final buffer = StringBuffer();
    var lastDash = false;
    for (final unit in lower.codeUnits) {
      final isLetter = unit >= 97 && unit <= 122;
      final isDigit = unit >= 48 && unit <= 57;
      if (isLetter || isDigit) {
        buffer.writeCharCode(unit);
        lastDash = false;
      } else if (!lastDash) {
        buffer.write('-');
        lastDash = true;
      }
    }
    final slug = buffer.toString().replaceAll(RegExp('^-+|-+\$'), '');
    return slug.isEmpty ? 'zakaz' : slug;
  }

  void _addNode(String kind) {
    final id = '${kind}_${_nextNodeIndex++}';
    setState(() {
      if (kind == 'condition') {
        _addConditionBranch(id);
      } else if (kind == 'kk_product') {
        _addDetachedNode(_newNode(id, kind));
      } else {
        _insertBeforeEnd(_newNode(id, kind));
      }
    });
    if (_orderMode && kind == 'task') {
      final index = nodes.indexWhere((node) => node.id == id);
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_editNode(index));
          }
        });
      }
    }
  }

  Future<void> _addApparatusGroup(AdminApparatusGroup group) async {
    final groupNames =
        group.apparatus.map((item) => item.trim().toLowerCase()).toSet();
    final warehouses = await MobileApi.instance.adminWarehouses(
      parent: 'aparat - A',
      limit: 200,
    );
    final compatible = warehouses
        .where((warehouse) =>
            groupNames.contains(warehouse.warehouse.trim().toLowerCase()))
        .where((warehouse) => productionMapApparatusMatchesOrder(
              warehouse,
              widget.orderContext,
            ))
        .toList(growable: false);
    if (!mounted) {
      return;
    }
    if (compatible.isEmpty) {
      showAdminTopNotice(context, 'Mos aparat topilmadi');
      return;
    }
    final picked = await showModalBottomSheet<_ApparatusGroupPickResult>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) => _ApparatusGroupPickerSheet(
        group: group,
        apparatus: compatible,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (picked.skip) {
        _insertAlternativeApparatusNodes(group, compatible);
      } else if (picked.apparatus != null) {
        final id = 'apparatus_${_nextNodeIndex++}';
        _insertBeforeEnd(
          _newNode(id, 'apparatus')
              .copyWith(title: picked.apparatus!.warehouse),
        );
      }
    });
  }

  void _insertAlternativeApparatusNodes(
    AdminApparatusGroup group,
    List<AdminWarehouse> apparatus,
  ) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    if (endIndex <= 0 || apparatus.isEmpty) {
      return;
    }
    final previous = nodes[endIndex - 1];
    final end = nodes[endIndex];
    final groupId = 'alt_${group.name.trim().toLowerCase()}_$_nextNodeIndex';
    final y = previous.y + _nodeStepY;
    final created = <ProductionMapNode>[];
    for (var index = 0; index < apparatus.length; index++) {
      final id = 'apparatus_${_nextNodeIndex++}';
      created.add(
        ProductionMapNode(
          id: id,
          kind: 'apparatus',
          title: apparatus[index].warehouse,
          alternativeGroupId: groupId,
          alternativeGroupLabel: group.name,
          x: previous.x + index * _ProductionMapCanvas._nodeSize.width,
          y: y,
        ),
      );
    }
    nodes.insertAll(endIndex, created);
    edges.removeWhere((edge) => edge.from == previous.id && edge.to == end.id);
    for (final node in created) {
      edges
        ..add(ProductionMapEdge(from: previous.id, to: node.id))
        ..add(ProductionMapEdge(from: node.id, to: end.id));
    }
    _pushEndDown();
  }

  ProductionMapNode _newNode(String id, String kind) {
    final end = nodes.firstWhere((node) => node.kind == 'end');
    return switch (kind) {
      'apparatus' => ProductionMapNode(
          id: id,
          kind: 'apparatus',
          title: 'Aparat tanlang',
          x: end.x,
          y: end.y - 132,
        ),
      'formula' => ProductionMapNode(
          id: id,
          kind: 'formula',
          title: 'Hisob kitob',
          x: end.x,
          y: end.y - 132,
          formula: const ProductionFormula(
            target: 'result_kg',
            expression: 'order_qty',
          ),
        ),
      'kk_product' => ProductionMapNode(
          id: id,
          kind: 'kk_product',
          title: 'KK li mahsulot tanlang',
          x: end.x,
          y: end.y + _nodeStepY,
        ),
      _ => ProductionMapNode(
          id: id,
          kind: 'task',
          title: _orderMode ? 'Stansiya tanlang' : 'Ishlov jarayoni',
          roleCode: 'worker',
          x: end.x,
          y: end.y - 132,
        ),
    };
  }

  void _insertBeforeEnd(ProductionMapNode node) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    final previous = nodes[endIndex - 1];
    final end = nodes[endIndex];
    final placedNode = _placeNode(
      node.copyWith(
        x: previous.x,
        y: previous.y + _nodeStepY,
      ),
      ignoreIds: {end.id},
    );
    nodes.insert(endIndex, placedNode);
    edges.removeWhere((edge) => edge.from == previous.id && edge.to == end.id);
    edges
      ..add(ProductionMapEdge(from: previous.id, to: placedNode.id))
      ..add(ProductionMapEdge(from: placedNode.id, to: end.id));
    _pushEndDown();
  }

  void _addDetachedNode(ProductionMapNode node) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    final placedNode = _placeNode(node);
    nodes.insert(endIndex < 0 ? nodes.length : endIndex, placedNode);
  }

  void _addConditionBranch(String id) {
    final endIndex = nodes.indexWhere((item) => item.kind == 'end');
    final previous = nodes[endIndex - 1];
    final end = nodes[endIndex];
    final condition = _placeNode(
      ProductionMapNode(
        id: id,
        kind: 'condition',
        title: 'Shart',
        x: previous.x,
        y: previous.y + _nodeStepY,
        formula: const ProductionFormula(
          target: '',
          expression: 'order_qty >= 100',
        ),
      ),
      ignoreIds: {end.id},
    );
    nodes.insert(endIndex, condition);
    edges.removeWhere((edge) => edge.from == previous.id && edge.to == end.id);
    edges.add(ProductionMapEdge(from: previous.id, to: condition.id));
    _pushEndDown();
  }

  void _pushEndDown() {
    final endIndex = nodes.indexWhere((node) => node.kind == 'end');
    final end = nodes[endIndex];
    final deepest = nodes
        .where((node) => node.id != end.id)
        .map((node) => node.y)
        .fold<double>(end.y, (max, y) => y > max ? y : max);
    nodes[endIndex] = _placeNode(
      end.copyWith(y: deepest + _nodeStepY),
      ignoreIds: {end.id},
    );
  }

  void _moveNode(String nodeID, Offset delta) {
    final index = nodes.indexWhere((node) => node.id == nodeID);
    if (index < 0) {
      return;
    }
    final node = nodes[index];
    setState(() {
      final position = _clampNodePosition(Offset(node.x, node.y) + delta);
      nodes[index] = node.copyWith(x: position.dx, y: position.dy);
      _resolveNodeOverlaps(anchorID: nodeID);
    });
  }

  void _startConnection(String nodeID, [String branch = '']) {
    setState(() {
      _connectingFromNodeID = nodeID;
      _connectingFromBranch = branch.trim().toLowerCase();
      _connectionPreviewEnd = null;
    });
  }

  void _updateConnectionPreview(Offset canvasPosition) {
    if (_connectingFromNodeID == null) {
      return;
    }
    setState(() => _connectionPreviewEnd = canvasPosition);
  }

  void _finishConnection(Offset canvasPosition) {
    final fromID = _connectingFromNodeID;
    final branchKey = _connectingFromBranch;
    setState(() {
      _connectingFromNodeID = null;
      _connectingFromBranch = '';
      _connectionPreviewEnd = null;
      if (fromID == null) {
        return;
      }
      final target = _nodeAt(canvasPosition, exceptID: fromID);
      if (target == null) {
        return;
      }
      final source = nodes.firstWhere(
        (node) => node.id == fromID,
        orElse: () => target,
      );
      if (!_canCreateEdge(source, target)) {
        return;
      }
      final exists = edges.any((edge) =>
          edge.from == fromID &&
          edge.to == target.id &&
          edge.branch.trim().toLowerCase() == branchKey);
      if (!exists) {
        if (branchKey.isNotEmpty) {
          edges.removeWhere((edge) =>
              edge.from == fromID &&
              edge.branch.trim().toLowerCase() == branchKey);
        }
        edges.add(
          ProductionMapEdge(from: fromID, to: target.id, branch: branchKey),
        );
      }
    });
  }

  bool _canCreateEdge(ProductionMapNode from, ProductionMapNode to) {
    return productionMapCanCreateEdge(from, to);
  }

  void _cancelConnection() {
    setState(() {
      _connectingFromNodeID = null;
      _connectingFromBranch = '';
      _connectionPreviewEnd = null;
    });
  }

  void _removeEdge(ProductionMapEdge edge) {
    setState(() {
      edges.removeWhere(
        (item) =>
            item.from == edge.from &&
            item.to == edge.to &&
            item.branch == edge.branch,
      );
    });
  }

  ProductionMapNode? _nodeAt(Offset position, {required String exceptID}) {
    for (final node in nodes.reversed) {
      if (node.id == exceptID) {
        continue;
      }
      final rect = Rect.fromLTWH(
        node.x,
        node.y,
        _ProductionMapCanvas._nodeSize.width,
        _ProductionMapCanvas._nodeSize.height,
      );
      if (rect.contains(position)) {
        return node;
      }
    }
    return null;
  }

  ProductionMapNode _placeNode(
    ProductionMapNode node, {
    Set<String> ignoreIds = const {},
    List<ProductionMapNode> extraNodes = const [],
  }) {
    final position = _firstFreePosition(
      Offset(node.x, node.y),
      nodeID: node.id,
      ignoreIds: ignoreIds,
      extraNodes: extraNodes,
    );
    return node.copyWith(x: position.dx, y: position.dy);
  }

  Offset _firstFreePosition(
    Offset preferred, {
    required String nodeID,
    Set<String> ignoreIds = const {},
    List<ProductionMapNode> extraNodes = const [],
  }) {
    final origin = _clampNodePosition(preferred);
    final tried = <String>{};
    for (var row = 0; row < 80; row++) {
      for (final column in const [0, -1, 1, -2, 2, -3, 3, -4, 4]) {
        final position = _clampNodePosition(
          Offset(
            origin.dx + column * _nodeStepX,
            origin.dy + row * _nodeStepY,
          ),
        );
        final key = '${position.dx}:${position.dy}';
        if (!tried.add(key)) {
          continue;
        }
        if (!_positionOverlapsAny(
          position,
          nodeID: nodeID,
          ignoreIds: ignoreIds,
          extraNodes: extraNodes,
        )) {
          return position;
        }
      }
    }
    return origin;
  }

  void _resolveNodeOverlaps({required String anchorID}) {
    for (var pass = 0; pass < 80; pass++) {
      var moved = false;
      for (var a = 0; a < nodes.length; a++) {
        for (var b = a + 1; b < nodes.length; b++) {
          final separation = _overlapSeparation(nodes[a], nodes[b]);
          if (separation == Offset.zero) {
            continue;
          }
          moved = true;
          if (nodes[a].id == anchorID) {
            _moveNodeByIndex(b, separation);
          } else if (nodes[b].id == anchorID) {
            _moveNodeByIndex(a, -separation);
          } else {
            _moveNodeByIndex(a, -separation / 2);
            _moveNodeByIndex(b, separation / 2);
          }
        }
      }
      if (!moved) {
        _repackRemainingOverlaps(anchorID: anchorID);
        return;
      }
    }
    _repackRemainingOverlaps(anchorID: anchorID);
  }

  Offset _overlapSeparation(ProductionMapNode a, ProductionMapNode b) {
    final aRect = _collisionRectAt(Offset(a.x, a.y));
    final bRect = _collisionRectAt(Offset(b.x, b.y));
    if (!aRect.overlaps(bRect)) {
      return Offset.zero;
    }
    final overlapX =
        math.min(aRect.right - bRect.left, bRect.right - aRect.left);
    final overlapY =
        math.min(aRect.bottom - bRect.top, bRect.bottom - aRect.top);
    if (overlapX <= 0 || overlapY <= 0) {
      return Offset.zero;
    }
    if (overlapX <= overlapY) {
      final direction = bRect.center.dx >= aRect.center.dx ? 1.0 : -1.0;
      return Offset((overlapX + 0.5) * direction, 0);
    }
    final direction = bRect.center.dy >= aRect.center.dy ? 1.0 : -1.0;
    return Offset(0, (overlapY + 0.5) * direction);
  }

  void _moveNodeByIndex(int index, Offset delta) {
    final node = nodes[index];
    final position = _clampNodePosition(Offset(node.x, node.y) + delta);
    nodes[index] = node.copyWith(x: position.dx, y: position.dy);
  }

  void _repackRemainingOverlaps({required String anchorID}) {
    for (var pass = 0; pass < nodes.length; pass++) {
      var changed = false;
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        if (node.id == anchorID || !_nodeOverlapsAny(node)) {
          continue;
        }
        final position = _firstFreePosition(
          Offset(node.x, node.y),
          nodeID: node.id,
        );
        if (position.dx != node.x || position.dy != node.y) {
          nodes[i] = node.copyWith(x: position.dx, y: position.dy);
          changed = true;
        }
      }
      if (!changed) {
        return;
      }
    }
  }

  bool _nodeOverlapsAny(ProductionMapNode node) {
    return _positionOverlapsAny(
      Offset(node.x, node.y),
      nodeID: node.id,
    );
  }

  Offset _clampNodePosition(Offset position) {
    return Offset(
      position.dx.clamp(_minNodeX, _maxNodeX).toDouble(),
      position.dy.clamp(_minNodeY, _maxNodeY).toDouble(),
    );
  }

  bool _positionOverlapsAny(
    Offset position, {
    required String nodeID,
    Set<String> ignoreIds = const {},
    List<ProductionMapNode> extraNodes = const [],
  }) {
    final candidate = _collisionRectAt(position);
    for (final node in [...nodes, ...extraNodes]) {
      if (node.id == nodeID || ignoreIds.contains(node.id)) {
        continue;
      }
      if (candidate.overlaps(_collisionRectAt(Offset(node.x, node.y)))) {
        return true;
      }
    }
    return false;
  }

  Rect _collisionRectAt(Offset position) {
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      _ProductionMapCanvas._nodeSize.width,
      _ProductionMapCanvas._nodeSize.height,
    ).inflate(_nodeGap / 2);
  }

  bool _isOrderProductTask(ProductionMapNode node) {
    return node.kind == 'task' &&
        (node.id.trim() == 'order' || node.roleCode.trim() == 'zakaz');
  }

  bool _isStationTask(ProductionMapNode node) {
    return node.kind == 'task' && !_isOrderProductTask(node);
  }

  Future<AdminWarehouse?> _pickStationWarehouse({String? title}) async {
    return showModalBottomSheet<AdminWarehouse>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      sheetAnimationStyle: kM3PickerSheetAnimation,
      builder: (context) {
        return M3AsyncPickerSheet<AdminWarehouse>(
          title: title ?? 'Stansiya tanlang',
          hintText: 'Aparat qidiring',
          pageSize: 50,
          cacheKey: 'production-map:station-warehouses'
              ':${_apparatusFilterCacheSuffix()}',
          loadPage: (query, offset, limit) async {
            final warehouses = await MobileApi.instance.adminWarehouses(
              query: query,
              parent: 'aparat - A',
              limit: 200,
            );
            return warehouses
                .where((warehouse) => productionMapApparatusMatchesOrder(
                      warehouse,
                      widget.orderContext,
                    ))
                .skip(offset)
                .take(limit)
                .toList(growable: false);
          },
          itemTitle: (item) => item.warehouse,
          itemSubtitle: (item) =>
              item.company.trim().isEmpty ? 'Aparat' : item.company,
          onSelected: (item) => Navigator.of(context).pop(item),
        );
      },
    );
  }

  Future<void> _editNode(int index) async {
    if (index < 0) {
      return;
    }
    final node = nodes[index];
    if (node.kind == 'apparatus') {
      final picked = await showModalBottomSheet<AdminWarehouse>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.32),
        sheetAnimationStyle: kM3PickerSheetAnimation,
        builder: (context) {
          return M3AsyncPickerSheet<AdminWarehouse>(
            title: 'Aparat tanlang',
            hintText: 'Aparat qidiring',
            pageSize: 50,
            cacheKey: 'production-map:apparatus-warehouses'
                ':${_apparatusFilterCacheSuffix()}',
            loadPage: (query, offset, limit) async {
              final warehouses = await MobileApi.instance.adminWarehouses(
                query: query,
                parent: 'aparat - A',
                limit: 200,
              );
              return warehouses
                  .where((warehouse) => productionMapApparatusMatchesOrder(
                        warehouse,
                        widget.orderContext,
                      ))
                  .skip(offset)
                  .take(limit)
                  .toList(growable: false);
            },
            itemTitle: (item) => item.warehouse,
            itemSubtitle: (item) =>
                item.company.trim().isEmpty ? 'Aparat' : item.company,
            onSelected: (item) => Navigator.of(context).pop(item),
          );
        },
      );
      if (picked == null || !mounted) {
        return;
      }
      setState(() => nodes[index] = node.copyWith(title: picked.warehouse));
      return;
    }
    if (_isStationTask(node)) {
      final picked = await _pickStationWarehouse(title: 'Ishlov stansiyasi');
      if (picked == null || !mounted) {
        return;
      }
      setState(() => nodes[index] = node.copyWith(title: picked.warehouse));
      return;
    }
    if (node.kind == 'kk_product') {
      final picked = await showModalBottomSheet<SupplierItem>(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.32),
        sheetAnimationStyle: kM3PickerSheetAnimation,
        builder: (context) {
          return M3AsyncPickerSheet<SupplierItem>(
            title: 'KK li mahsulot tanlang',
            hintText: 'Mahsulot qidiring',
            pageSize: 80,
            cacheKey: 'production-map:kk-products',
            loadPage: (query, offset, limit) {
              return MobileApi.instance.gscaleItemsPage(
                query: query,
                offset: offset,
                limit: limit,
              );
            },
            itemTitle: (item) =>
                item.name.trim().isEmpty ? item.code : item.name,
            itemSubtitle: (item) => item.code,
            onSelected: (item) => Navigator.of(context).pop(item),
          );
        },
      );
      if (picked == null || !mounted) {
        return;
      }
      setState(() {
        nodes[index] = node.copyWith(
          title: picked.name.trim().isEmpty ? picked.code : picked.name.trim(),
          itemCode: picked.code,
        );
      });
      return;
    }
    final edited = await showModalBottomSheet<ProductionMapNode>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) => _NodeEditSheet(node: node),
    );
    if (edited == null || !mounted) {
      return;
    }
    setState(() => nodes[index] = edited);
  }

  String _apparatusFilterCacheSuffix() {
    final context = widget.orderContext;
    if (context == null) {
      return 'all';
    }
    final recommended = productionMapRecommendedPechatColorCount(
      rollCount: context.rollCount,
      widthMm: context.widthMm,
    );
    return [
      context.rollCount?.toStringAsFixed(0) ?? 'x',
      context.widthMm?.toStringAsFixed(0) ?? 'x',
      recommended?.toString() ?? 'none',
    ].join('-');
  }

  void _deleteNode(int index) {
    final node = nodes[index];
    if (node.kind == 'start' || node.kind == 'end') {
      return;
    }
    setState(() {
      nodes.removeAt(index);
      edges.removeWhere((edge) => edge.from == node.id || edge.to == node.id);
    });
  }

  void _toggleMapToolsMenu() {
    setState(() => _mapToolsMenuOpen = !_mapToolsMenuOpen);
  }

  void _closeMapToolsMenu() {
    if (!_mapToolsMenuOpen) {
      return;
    }
    setState(() => _mapToolsMenuOpen = false);
  }

  void _runMapToolAction(VoidCallback action) {
    _closeMapToolsMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        action();
      }
    });
  }

  List<AdminFabMenuAction> _mapToolActions() {
    if (_orderMode) {
      final groupActions = [
        for (final group in _apparatusGroups)
          if (_apparatusGroupMatchesOrder(group))
            AdminFabMenuAction(
              title: group.name,
              icon: Icons.precision_manufacturing_rounded,
              onTap: () => _runMapToolAction(() {
                unawaited(_addApparatusGroup(group));
              }),
            ),
      ];
      return [
        if (groupActions.isEmpty)
          AdminFabMenuAction(
            title: 'Aparat',
            icon: Icons.precision_manufacturing_rounded,
            onTap: () => _runMapToolAction(() => _addNode('apparatus')),
          )
        else
          ...groupActions,
        AdminFabMenuAction(
          title: 'Ishlov',
          icon: Icons.engineering_rounded,
          onTap: () => _runMapToolAction(() => _addNode('task')),
        ),
        AdminFabMenuAction(
          title: 'kk li mahsulot',
          icon: Icons.inventory_2_rounded,
          onTap: () => _runMapToolAction(() => _addNode('kk_product')),
        ),
      ];
    }
    return [
      AdminFabMenuAction(
        title: 'Ishlov',
        icon: Icons.engineering_rounded,
        onTap: () => _runMapToolAction(() => _addNode('task')),
      ),
      AdminFabMenuAction(
        title: 'Aparat',
        icon: Icons.precision_manufacturing_rounded,
        onTap: () => _runMapToolAction(() => _addNode('apparatus')),
      ),
      AdminFabMenuAction(
        title: 'kk li mahsulot',
        icon: Icons.inventory_2_rounded,
        onTap: () => _runMapToolAction(() => _addNode('kk_product')),
      ),
      AdminFabMenuAction(
        title: 'Formula',
        icon: Icons.functions_rounded,
        onTap: () => _runMapToolAction(() => _addNode('formula')),
      ),
      AdminFabMenuAction(
        title: 'Condition',
        icon: Icons.call_split_rounded,
        onTap: () => _runMapToolAction(() => _addNode('condition')),
      ),
    ];
  }

  bool _apparatusGroupMatchesOrder(AdminApparatusGroup group) {
    return group.apparatus.any(
      (apparatus) => productionMapApparatusMatchesOrder(
        AdminWarehouse(
          warehouse: apparatus,
          parentWarehouse: 'aparat - A',
        ),
        widget.orderContext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fabBottom = MediaQuery.viewPaddingOf(context).bottom + 92.0;
    // System back (swipe) must also return the saved template to the caller.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop(_lastSavedTemplate);
        }
      },
      child: _buildShell(context, scheme, fabBottom),
    );
  }

  Widget _buildShell(
      BuildContext context, ColorScheme scheme, double fabBottom) {
    return AppShell(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () {
          final nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop(_lastSavedTemplate);
          } else {
            nav.pushNamedAndRemoveUntil(
              AppRoutes.adminHome,
              (route) => false,
            );
          }
        },
      ),
      title: 'Production map test',
      subtitle: '',
      nativeTopBar: true,
      nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
      actions: [
        if (_orderMode)
          AppShellIconAction(
            key: const ValueKey('production-map-save'),
            icon:
                _savingMap ? Icons.hourglass_top_rounded : Icons.save_outlined,
            onTap: _saveMap,
          ),
      ],
      contentPadding: EdgeInsets.zero,
      animateOnEnter: false,
      bottom: const AdminDock(activeTab: AdminDockTab.home),
      child: ColoredBox(
        color: scheme.surface,
        child: Stack(
          children: [
            Positioned.fill(
              child: _ProductionMapCanvas(
                nodes: nodes,
                edges: edges,
                connectingFromNodeID: _connectingFromNodeID,
                connectingFromBranch: _connectingFromBranch,
                connectionPreviewEnd: _connectionPreviewEnd,
                onNodeTap: (node) => _editNode(nodes.indexOf(node)),
                onNodeDelete: (node) => _deleteNode(nodes.indexOf(node)),
                onNodeMoved: _moveNode,
                onConnectionStart: _startConnection,
                onConnectionUpdate: _updateConnectionPreview,
                onConnectionEnd: _finishConnection,
                onConnectionCancel: _cancelConnection,
                onEdgeDelete: _removeEdge,
              ),
            ),
            if (_mapToolsMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeMapToolsMenu,
                  child: ColoredBox(
                    color: scheme.scrim.withValues(alpha: 0.16),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              bottom: fabBottom,
              child: AdminFabActionMenu(
                open: _mapToolsMenuOpen,
                actions: _mapToolActions(),
                onToggle: _toggleMapToolsMenu,
                closedLabel: 'Element qo‘shish',
                openLabel: 'Yopish',
                closedIcon: Icons.add_rounded,
                alignEnd: false,
                columns: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlainActionButton extends StatefulWidget {
  const _PlainActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_PlainActionButton> createState() => _PlainActionButtonState();
}

class _PlainActionButtonState extends State<_PlainActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onTap != null;
    final background = scheme.primary;
    final foreground = scheme.onPrimary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: scheme.onPrimary.withValues(alpha: 0.12),
            highlightColor: scheme.onPrimary.withValues(alpha: 0.08),
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel:
                enabled ? () => setState(() => _pressed = false) : null,
            onTap: widget.onTap,
            child: Opacity(
              opacity: enabled ? 1 : 0.48,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: foreground, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissibleBottomSheetFrame extends StatelessWidget {
  const _DismissibleBottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.height * 0.9,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductionMapOrderNumberDialog extends StatefulWidget {
  const _ProductionMapOrderNumberDialog({
    required this.initialValue,
  });

  final String initialValue;

  @override
  State<_ProductionMapOrderNumberDialog> createState() =>
      _ProductionMapOrderNumberDialogState();
}

class _ApparatusGroupPickResult {
  const _ApparatusGroupPickResult({
    this.apparatus,
    this.skip = false,
  });

  final AdminWarehouse? apparatus;
  final bool skip;
}

class _ApparatusGroupPickerSheet extends StatelessWidget {
  const _ApparatusGroupPickerSheet({
    required this.group,
    required this.apparatus,
  });

  final AdminApparatusGroup group;
  final List<AdminWarehouse> apparatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    const _ApparatusGroupPickResult(skip: true),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in apparatus)
              Card(
                margin: const EdgeInsets.only(bottom: 6),
                elevation: 0,
                color: scheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: const Icon(Icons.precision_manufacturing_rounded),
                  title: Text(item.warehouse),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(
                    _ApparatusGroupPickResult(apparatus: item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductionMapOrderNumberDialogState
    extends State<_ProductionMapOrderNumberDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      setState(() => _errorText = '4 xonali raqam kiriting');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Zakaz raqami',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey(
                          'production-map-order-number-close',
                        ),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('production-map-order-number-field'),
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 4,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: '4 xonali zakaz raqami',
                      counterText: '',
                      errorText: _errorText,
                    ),
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('production-map-confirm-save'),
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Saqlash'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductionMapCanvas extends StatefulWidget {
  const _ProductionMapCanvas({
    required this.nodes,
    required this.edges,
    required this.connectingFromNodeID,
    required this.connectingFromBranch,
    required this.connectionPreviewEnd,
    required this.onNodeTap,
    required this.onNodeDelete,
    required this.onNodeMoved,
    required this.onConnectionStart,
    required this.onConnectionUpdate,
    required this.onConnectionEnd,
    required this.onConnectionCancel,
    required this.onEdgeDelete,
  });

  static const _minCanvasSize = Size(1180, 900);
  static const _nodeSize = Size(260, 60);

  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;
  final String? connectingFromNodeID;
  final String connectingFromBranch;
  final Offset? connectionPreviewEnd;
  final ValueChanged<ProductionMapNode> onNodeTap;
  final ValueChanged<ProductionMapNode> onNodeDelete;
  final void Function(String nodeID, Offset delta) onNodeMoved;
  final void Function(String nodeID, String branch) onConnectionStart;
  final ValueChanged<Offset> onConnectionUpdate;
  final ValueChanged<Offset> onConnectionEnd;
  final VoidCallback onConnectionCancel;
  final ValueChanged<ProductionMapEdge> onEdgeDelete;

  @override
  State<_ProductionMapCanvas> createState() => _ProductionMapCanvasState();
}

class _ProductionMapCanvasState extends State<_ProductionMapCanvas> {
  final _canvasKey = GlobalKey();
  late final TransformationController _transformController;
  bool _didSetInitialTransform = false;
  Offset? _lastConnectionPosition;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canvasSize = _canvasSizeFor(widget.nodes);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _scheduleInitialTransform(
              viewportSize: constraints.biggest,
              canvasSize: canvasSize,
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPaperPainter(scheme: scheme),
                  ),
                ),
                InteractiveViewer(
                  transformationController: _transformController,
                  constrained: false,
                  minScale: 0.45,
                  maxScale: 2.4,
                  boundaryMargin: const EdgeInsets.all(760),
                  child: SizedBox(
                    key: _canvasKey,
                    width: canvasSize.width,
                    height: canvasSize.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          width: canvasSize.width,
                          height: canvasSize.height,
                          child: CustomPaint(
                            size: canvasSize,
                            painter: _MapCanvasPainter(
                              nodes: widget.nodes,
                              edges: widget.edges,
                              connectionFromNodeID: widget.connectingFromNodeID,
                              connectionFromBranch: widget.connectingFromBranch,
                              connectionPreviewEnd: widget.connectionPreviewEnd,
                              nodeSize: _ProductionMapCanvas._nodeSize,
                              scheme: scheme,
                            ),
                          ),
                        ),
                        for (final edge in widget.edges)
                          if (_edgeActionPosition(edge) case final position?)
                            Positioned(
                              left: position.dx - 13,
                              top: position.dy - 13,
                              child: _EdgeDeleteButton(
                                edge: edge,
                                onTap: () => widget.onEdgeDelete(edge),
                              ),
                            ),
                        for (final node in widget.nodes)
                          Positioned(
                            left: node.x,
                            top: node.y,
                            width: _ProductionMapCanvas._nodeSize.width,
                            child: _MapNodeVisual(
                              node: node,
                              borderRadius: _nodeBorderRadius(node),
                              onTap: () => widget.onNodeTap(node),
                              onDragUpdate: (details) {
                                final scale = _transformController.value
                                    .getMaxScaleOnAxis();
                                widget.onNodeMoved(
                                  node.id,
                                  details.delta / scale,
                                );
                              },
                              onDelete:
                                  node.kind == 'start' || node.kind == 'end'
                                      ? null
                                      : () => widget.onNodeDelete(node),
                              onConnectionDragStart: (globalPosition) {
                                final canvasPosition = _globalToCanvas(
                                  globalPosition,
                                );
                                _lastConnectionPosition = canvasPosition;
                                widget.onConnectionStart(node.id, '');
                                widget.onConnectionUpdate(canvasPosition);
                              },
                              onConnectionDragUpdate: (globalPosition) {
                                final canvasPosition = _globalToCanvas(
                                  globalPosition,
                                );
                                _lastConnectionPosition = canvasPosition;
                                widget.onConnectionUpdate(canvasPosition);
                              },
                              onConnectionDragEnd: () {
                                final position = _lastConnectionPosition;
                                _lastConnectionPosition = null;
                                if (position == null) {
                                  widget.onConnectionCancel();
                                  return;
                                }
                                widget.onConnectionEnd(position);
                              },
                              onConnectionDragCancel: () {
                                _lastConnectionPosition = null;
                                widget.onConnectionCancel();
                              },
                              floating: false,
                              highlighted:
                                  widget.connectingFromNodeID == node.id,
                            ),
                          ),
                        for (final node in widget.nodes)
                          if (node.kind == 'condition') ...[
                            Positioned(
                              left: _branchButtonLeft(node, 'true'),
                              top: _branchButtonTop(node),
                              child: _BranchAddButton(
                                branch: 'true',
                                onConnectionDragStart: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionStart(node.id, 'true');
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragUpdate: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragEnd: () {
                                  final position = _lastConnectionPosition;
                                  _lastConnectionPosition = null;
                                  if (position == null) {
                                    widget.onConnectionCancel();
                                    return;
                                  }
                                  widget.onConnectionEnd(position);
                                },
                                onConnectionDragCancel: () {
                                  _lastConnectionPosition = null;
                                  widget.onConnectionCancel();
                                },
                              ),
                            ),
                            Positioned(
                              left: _branchButtonLeft(node, 'false'),
                              top: _branchButtonTop(node),
                              child: _BranchAddButton(
                                branch: 'false',
                                onConnectionDragStart: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionStart(node.id, 'false');
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragUpdate: (globalPosition) {
                                  final canvasPosition =
                                      _globalToCanvas(globalPosition);
                                  _lastConnectionPosition = canvasPosition;
                                  widget.onConnectionUpdate(canvasPosition);
                                },
                                onConnectionDragEnd: () {
                                  final position = _lastConnectionPosition;
                                  _lastConnectionPosition = null;
                                  if (position == null) {
                                    widget.onConnectionCancel();
                                    return;
                                  }
                                  widget.onConnectionEnd(position);
                                },
                                onConnectionDragCancel: () {
                                  _lastConnectionPosition = null;
                                  widget.onConnectionCancel();
                                },
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _scheduleInitialTransform({
    required Size viewportSize,
    required Size canvasSize,
  }) {
    if (_didSetInitialTransform || viewportSize.isEmpty) {
      return;
    }
    _didSetInitialTransform = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _transformController.value = _initialTransform(
        viewportSize: viewportSize,
        canvasSize: canvasSize,
      );
    });
  }

  Offset _globalToCanvas(Offset globalPosition) {
    final context = _canvasKey.currentContext;
    if (context == null) {
      return Offset.zero;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return Offset.zero;
    }
    return box.globalToLocal(globalPosition);
  }

  Matrix4 _initialTransform({
    required Size viewportSize,
    required Size canvasSize,
  }) {
    final bounds = _nodeBounds();
    if (bounds == null) {
      return Matrix4.identity();
    }
    const padding = 56.0;
    final scaleToFitWidth = viewportSize.width / (bounds.width + padding * 2);
    final readableScale = scaleToFitWidth.clamp(0.88, 1.08);
    final dx = viewportSize.width / 2 - bounds.center.dx * readableScale;
    final dy = padding - bounds.top * readableScale;
    final minDx = viewportSize.width - canvasSize.width * readableScale;
    final minDy = viewportSize.height - canvasSize.height * readableScale;
    final maxDx = math.max(minDx, padding);
    final maxDy = math.max(minDy, padding);
    return Matrix4.identity()
      ..setEntry(0, 0, readableScale)
      ..setEntry(1, 1, readableScale)
      ..setEntry(0, 3, dx.clamp(minDx, maxDx))
      ..setEntry(1, 3, dy.clamp(minDy, maxDy));
  }

  Rect? _nodeBounds() {
    Rect? bounds;
    for (final node in widget.nodes) {
      final rect = Rect.fromLTWH(
        node.x,
        node.y,
        _ProductionMapCanvas._nodeSize.width,
        _ProductionMapCanvas._nodeSize.height,
      );
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds;
  }

  Size _canvasSizeFor(List<ProductionMapNode> nodes) {
    var maxX = _ProductionMapCanvas._minCanvasSize.width;
    var maxY = _ProductionMapCanvas._minCanvasSize.height;
    for (final node in nodes) {
      final right = node.x + _ProductionMapCanvas._nodeSize.width + 320;
      final bottom = node.y + _ProductionMapCanvas._nodeSize.height + 360;
      if (right > maxX) {
        maxX = right;
      }
      if (bottom > maxY) {
        maxY = bottom;
      }
    }
    return Size(maxX, maxY);
  }

  double _branchButtonLeft(ProductionMapNode node, String branch) {
    const buttonWidth = _BranchAddButton.width;
    final left = switch (branch) {
      'true' => node.x - buttonWidth / 2,
      'false' =>
        node.x + _ProductionMapCanvas._nodeSize.width - buttonWidth / 2,
      _ => node.x,
    };
    return math.max(8, left);
  }

  double _branchButtonTop(ProductionMapNode node) {
    return node.y +
        _ProductionMapCanvas._nodeSize.height / 2 -
        _BranchAddButton.height / 2;
  }

  Offset? _edgeActionPosition(ProductionMapEdge edge) {
    final from = _nodeByID(edge.from);
    final to = _nodeByID(edge.to);
    if (from == null || to == null) {
      return null;
    }
    final fromRect = _nodeRect(from);
    final toRect = _nodeRect(to);
    final branchKey = edge.branch.trim().toLowerCase();
    final start = _startAnchor(from, branchKey, toRect.center);
    final end = _edgeAnchor(toRect, fromRect.center);
    return Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
  }

  ProductionMapNode? _nodeByID(String id) {
    for (final node in widget.nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  Rect _nodeRect(ProductionMapNode node) {
    return Rect.fromLTWH(
      node.x,
      node.y,
      _ProductionMapCanvas._nodeSize.width,
      _ProductionMapCanvas._nodeSize.height,
    );
  }

  BorderRadius _nodeBorderRadius(ProductionMapNode node) {
    final groupId = node.alternativeGroupId.trim();
    if (groupId.isEmpty) {
      return BorderRadius.circular(28);
    }
    final group = widget.nodes
        .where((item) => item.alternativeGroupId.trim() == groupId)
        .toList()
      ..sort((left, right) => left.x.compareTo(right.x));
    if (group.length <= 1) {
      return BorderRadius.circular(28);
    }
    final index = group.indexWhere((item) => item.id == node.id);
    const outer = Radius.circular(28);
    const inner = Radius.circular(2);
    if (index <= 0) {
      return const BorderRadius.horizontal(left: outer, right: inner);
    }
    if (index == group.length - 1) {
      return const BorderRadius.horizontal(left: inner, right: outer);
    }
    return BorderRadius.circular(2);
  }

  Offset _startAnchor(
    ProductionMapNode node,
    String branchKey,
    Offset fallbackToward,
  ) {
    final rect = _nodeRect(node);
    if (node.kind != 'condition') {
      return _externalPortCenter(rect, fallbackToward);
    }
    return switch (branchKey) {
      'true' => Offset(rect.left, rect.center.dy),
      'false' => Offset(rect.right, rect.center.dy),
      _ => _externalPortCenter(rect, fallbackToward),
    };
  }

  Offset _externalPortCenter(Rect rect, Offset toward) {
    final anchor = _edgeAnchor(rect, toward);
    final vector = anchor - rect.center;
    final distance = vector.distance;
    if (distance == 0) {
      return anchor;
    }
    return anchor + vector / distance * _MapCanvasPainter.portRadius;
  }

  Offset _edgeAnchor(Rect rect, Offset toward) {
    final center = rect.center;
    final dx = toward.dx - center.dx;
    final dy = toward.dy - center.dy;
    if (dx == 0 && dy == 0) {
      return center;
    }
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;
    final ratio = math.max(dx.abs() / halfWidth, dy.abs() / halfHeight);
    return Offset(center.dx + dx / ratio, center.dy + dy / ratio);
  }
}

class _BranchAddButton extends StatelessWidget {
  const _BranchAddButton({
    required this.branch,
    required this.onConnectionDragStart,
    required this.onConnectionDragUpdate,
    required this.onConnectionDragEnd,
    required this.onConnectionDragCancel,
  });

  static const width = 34.0;
  static const height = 34.0;

  final String branch;
  final ValueChanged<Offset> onConnectionDragStart;
  final ValueChanged<Offset> onConnectionDragUpdate;
  final VoidCallback onConnectionDragEnd;
  final VoidCallback onConnectionDragCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final branchKey = branch.trim().toLowerCase();
    final color = switch (branchKey) {
      'true' => scheme.primaryContainer,
      'false' => scheme.errorContainer,
      _ => scheme.secondaryContainer,
    };
    final foreground = switch (branchKey) {
      'true' => scheme.onPrimaryContainer,
      'false' => scheme.onErrorContainer,
      _ => scheme.onSecondaryContainer,
    };
    return Tooltip(
      message:
          '${productionMapBranchDisplayLabel(branch)} yo‘liga qo‘l tortish',
      child: SizedBox(
        key: ValueKey('production-map-branch-add-$branch'),
        width: width,
        height: height,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) =>
              onConnectionDragStart(details.globalPosition),
          onPanUpdate: (details) =>
              onConnectionDragUpdate(details.globalPosition),
          onPanEnd: (_) => onConnectionDragEnd(),
          onPanCancel: onConnectionDragCancel,
          child: Material(
            color: color,
            borderRadius: BorderRadius.circular(99),
            elevation: 2,
            shadowColor: scheme.shadow.withValues(alpha: 0.18),
            clipBehavior: Clip.antiAlias,
            child: Icon(Icons.add_link_rounded, size: 18, color: foreground),
          ),
        ),
      ),
    );
  }
}

class _EdgeDeleteButton extends StatelessWidget {
  const _EdgeDeleteButton({
    required this.edge,
    required this.onTap,
  });

  final ProductionMapEdge edge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final branchKey = edge.branch.trim().toLowerCase();
    final color = switch (branchKey) {
      'true' => scheme.primary,
      'false' => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
    return Tooltip(
      message: 'Yo‘lni uzish',
      child: Material(
        key: ValueKey(
            'production-map-edge-delete-${edge.from}-${edge.to}-${edge.branch}'),
        color: scheme.surface,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: scheme.shadow.withValues(alpha: 0.16),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 26,
            child: Icon(
              Icons.close_rounded,
              size: 17,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPaperPainter extends CustomPainter {
  const _GridPaperPainter({required this.scheme});

  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size, scheme);
  }

  @override
  bool shouldRepaint(covariant _GridPaperPainter oldDelegate) {
    return oldDelegate.scheme != scheme;
  }
}

void _paintGrid(Canvas canvas, Size size, ColorScheme scheme) {
  final gridColor = scheme.brightness == Brightness.dark
      ? scheme.onSurface.withValues(alpha: 0.24)
      : scheme.outlineVariant.withValues(alpha: 0.42);
  final paint = Paint()
    ..color = gridColor
    ..strokeWidth = 1;
  for (var x = 0.0; x <= size.width; x += 40) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }
  for (var y = 0.0; y <= size.height; y += 40) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
}

class _MapCanvasPainter extends CustomPainter {
  const _MapCanvasPainter({
    required this.nodes,
    required this.edges,
    required this.connectionFromNodeID,
    required this.connectionFromBranch,
    required this.connectionPreviewEnd,
    required this.nodeSize,
    required this.scheme,
  });

  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;
  final String? connectionFromNodeID;
  final String connectionFromBranch;
  final Offset? connectionPreviewEnd;
  final Size nodeSize;
  final ColorScheme scheme;

  static const portRadius = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final byID = {
      for (final node in nodes) node.id: node,
    };
    for (final edge in edges) {
      final from = byID[edge.from];
      final to = byID[edge.to];
      if (from == null || to == null) {
        continue;
      }
      _paintEdge(canvas, from, to, edge.branch);
    }
    final previewFromID = connectionFromNodeID;
    final previewEnd = connectionPreviewEnd;
    if (previewFromID != null && previewEnd != null) {
      final from = byID[previewFromID];
      if (from != null) {
        _paintPreviewEdge(canvas, from, previewEnd, connectionFromBranch);
      }
    }
  }

  void _paintEdge(
    Canvas canvas,
    ProductionMapNode from,
    ProductionMapNode to,
    String branch,
  ) {
    final fromRect = _nodeRect(from);
    final toRect = _nodeRect(to);
    final branchKey = branch.trim().toLowerCase();
    final start = _startAnchor(from, branchKey, toRect.center);
    final end = _edgeAnchor(toRect, fromRect.center);
    final path = _elasticPath(
      start: start,
      end: end,
      startOrigin: fromRect.center,
      endOrigin: toRect.center,
    );
    final color = switch (branchKey) {
      'true' => scheme.primary,
      'false' => scheme.error,
      _ => scheme.onSurfaceVariant,
    };
    final paint = Paint()
      ..color = color.withValues(alpha: 0.76)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    _paintStartPort(canvas, from, branchKey, start, color);
    _paintArrow(canvas, end, start, color);
    if (branchKey.isNotEmpty) {
      _paintBranchLabel(
        canvas,
        Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 16),
        productionMapBranchDisplayLabel(branchKey),
        color,
      );
    }
  }

  void _paintPreviewEdge(
    Canvas canvas,
    ProductionMapNode from,
    Offset previewEnd,
    String branch,
  ) {
    final branchKey = branch.trim().toLowerCase();
    final start = _startAnchor(from, branchKey, previewEnd);
    final path = _elasticPath(
      start: start,
      end: previewEnd,
      startOrigin: _nodeRect(from).center,
      endOrigin: previewEnd,
    );
    final color = switch (branchKey) {
      'true' => scheme.primary,
      'false' => scheme.error,
      _ => scheme.primary,
    };
    final paint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
    _paintStartPort(canvas, from, branchKey, start, color);
    canvas.drawCircle(previewEnd, 7, Paint()..color = color);
    if (branchKey.isNotEmpty) {
      _paintBranchLabel(
        canvas,
        Offset((start.dx + previewEnd.dx) / 2,
            (start.dy + previewEnd.dy) / 2 - 16),
        productionMapBranchDisplayLabel(branchKey),
        color,
      );
    }
  }

  Rect _nodeRect(ProductionMapNode node) {
    return Rect.fromLTWH(node.x, node.y, nodeSize.width, nodeSize.height);
  }

  Offset _startAnchor(
    ProductionMapNode node,
    String branchKey,
    Offset fallbackToward,
  ) {
    final rect = _nodeRect(node);
    if (node.kind != 'condition') {
      return _externalPortCenter(rect, fallbackToward);
    }
    return switch (branchKey) {
      'true' => Offset(rect.left, rect.center.dy),
      'false' => Offset(rect.right, rect.center.dy),
      _ => _externalPortCenter(rect, fallbackToward),
    };
  }

  Offset _externalPortCenter(Rect rect, Offset toward) {
    final anchor = _edgeAnchor(rect, toward);
    final vector = anchor - rect.center;
    final distance = vector.distance;
    if (distance == 0) {
      return anchor;
    }
    return anchor + vector / distance * portRadius;
  }

  Offset _edgeAnchor(Rect rect, Offset toward) {
    final center = rect.center;
    final dx = toward.dx - center.dx;
    final dy = toward.dy - center.dy;
    if (dx == 0 && dy == 0) {
      return center;
    }
    final halfWidth = rect.width / 2;
    final halfHeight = rect.height / 2;
    final ratio = math.max(dx.abs() / halfWidth, dy.abs() / halfHeight);
    return Offset(center.dx + dx / ratio, center.dy + dy / ratio);
  }

  Path _elasticPath({
    required Offset start,
    required Offset end,
    required Offset startOrigin,
    required Offset endOrigin,
  }) {
    final distance = (end - start).distance;
    final handle = (distance * 0.42).clamp(54.0, 190.0);
    final startTangent = _normalizedOr(start - startOrigin, end - start);
    final endTangent = _normalizedOr(end - endOrigin, start - end);
    final control1 = start + startTangent * handle;
    final control2 = end + endTangent * handle;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        end.dx,
        end.dy,
      );
  }

  Offset _normalizedOr(Offset value, Offset fallback) {
    if (value.distance > 0.001) {
      return value / value.distance;
    }
    if (fallback.distance > 0.001) {
      return fallback / fallback.distance;
    }
    return const Offset(1, 0);
  }

  void _paintStartPort(
    Canvas canvas,
    ProductionMapNode node,
    String branchKey,
    Offset center,
    Color color,
  ) {
    if (node.kind == 'condition' && branchKey.isNotEmpty) {
      return;
    }
    canvas.drawCircle(
      center,
      portRadius,
      Paint()
        ..color = scheme.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      portRadius,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintArrow(Canvas canvas, Offset tip, Offset tail, Color color) {
    final angle = math.atan2(tip.dy - tail.dy, tip.dx - tail.dx);
    const arrowSize = 12.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - math.cos(angle - math.pi / 6) * arrowSize,
        tip.dy - math.sin(angle - math.pi / 6) * arrowSize,
      )
      ..lineTo(
        tip.dx - math.cos(angle + math.pi / 6) * arrowSize,
        tip.dy - math.sin(angle + math.pi / 6) * arrowSize,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintBranchLabel(
    Canvas canvas,
    Offset center,
    String label,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: scheme.onPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 18,
      height: textPainter.height + 10,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(99));
    canvas.drawRRect(rrect, Paint()..color = color);
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return true;
  }
}

class _MapNodeVisual extends StatelessWidget {
  const _MapNodeVisual({
    required this.node,
    required this.borderRadius,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDelete,
    required this.onConnectionDragStart,
    required this.onConnectionDragUpdate,
    required this.onConnectionDragEnd,
    required this.onConnectionDragCancel,
    required this.floating,
    required this.highlighted,
  });

  final ProductionMapNode node;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback? onDelete;
  final ValueChanged<Offset> onConnectionDragStart;
  final ValueChanged<Offset> onConnectionDragUpdate;
  final VoidCallback onConnectionDragEnd;
  final VoidCallback onConnectionDragCancel;
  final bool floating;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: '${node.title} node',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onPanUpdate: onDragUpdate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _backgroundFor(node, scheme),
            borderRadius: borderRadius,
            border: highlighted
                ? Border.all(color: scheme.primary, width: 2)
                : null,
            boxShadow: floating
                ? [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.surface.withValues(alpha: 0.55),
                  child: Icon(_iconFor(node.kind), size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitleFor(node),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _labelFor(node.kind),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  key: ValueKey('production-map-node-connect-${node.id}'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) =>
                      onConnectionDragStart(details.globalPosition),
                  onPanUpdate: (details) =>
                      onConnectionDragUpdate(details.globalPosition),
                  onPanEnd: (_) => onConnectionDragEnd(),
                  onPanCancel: onConnectionDragCancel,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add_link_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String kind) {
    return switch (kind) {
      'apparatus' => Icons.precision_manufacturing_rounded,
      'kk_product' => Icons.inventory_2_rounded,
      'formula' => Icons.functions_rounded,
      'condition' => Icons.call_split_rounded,
      'task' => Icons.engineering_rounded,
      'end' => Icons.flag_rounded,
      _ => Icons.play_arrow_rounded,
    };
  }

  Color _backgroundFor(ProductionMapNode node, ColorScheme scheme) {
    if (node.kind == 'apparatus' &&
        node.alternativeAssignedTitle.trim().isNotEmpty &&
        productionMapWarehouseTitlesMatch(
          node.title,
          node.alternativeAssignedTitle,
        )) {
      return Colors.green.shade100;
    }
    return _colorFor(node.kind, scheme);
  }

  String _labelFor(String kind) {
    return switch (kind) {
      'apparatus' => 'aparat',
      'kk_product' => 'kk',
      'formula' => 'formula',
      'condition' => 'if',
      'task' => 'ishlov',
      'end' => 'end',
      _ => 'start',
    };
  }

  String _subtitleFor(ProductionMapNode node) {
    final formula = node.formula;
    if (formula != null) {
      if (node.kind == 'condition') {
        return formula.expression;
      }
      return '${formula.target} = ${formula.expression}';
    }
    if (node.roleCode.trim().isNotEmpty) {
      return node.roleCode;
    }
    if (node.itemCode.trim().isNotEmpty) {
      return node.itemCode;
    }
    return node.kind;
  }

  Color _colorFor(String kind, ColorScheme scheme) {
    return switch (kind) {
      'apparatus' => scheme.secondaryContainer,
      'kk_product' => scheme.primaryContainer,
      'formula' => scheme.tertiaryContainer,
      'condition' => scheme.primaryContainer,
      'task' => scheme.secondaryContainer,
      _ => scheme.surfaceContainerHighest,
    };
  }
}

class _NodeEditSheet extends StatefulWidget {
  const _NodeEditSheet({required this.node});

  final ProductionMapNode node;

  @override
  State<_NodeEditSheet> createState() => _NodeEditSheetState();
}

class _NodeEditSheetState extends State<_NodeEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _roleCode;
  late final TextEditingController _formulaTarget;
  late final TextEditingController _formulaExpression;

  @override
  void initState() {
    super.initState();
    final formula = widget.node.formula;
    _title = TextEditingController(text: widget.node.title);
    _roleCode = TextEditingController(text: widget.node.roleCode);
    _formulaTarget = TextEditingController(text: formula?.target ?? '');
    _formulaExpression = TextEditingController(text: formula?.expression ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _roleCode.dispose();
    _formulaTarget.dispose();
    _formulaExpression.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DismissibleBottomSheetFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const SizedBox(width: 44, height: 4),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Node sozlash',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            _SheetField(
              label: 'Nomi',
              controller: _title,
            ),
            if (widget.node.kind == 'task') ...[
              const SizedBox(height: 10),
              _SheetField(label: 'Vazifa / role code', controller: _roleCode),
            ],
            if (widget.node.kind == 'formula') ...[
              const SizedBox(height: 10),
              _SheetField(label: 'Formula target', controller: _formulaTarget),
              const SizedBox(height: 10),
              _FormulaSheetField(
                label: 'Formula',
                controller: _formulaExpression,
              ),
            ],
            if (widget.node.kind == 'condition') ...[
              const SizedBox(height: 10),
              _FormulaSheetField(
                label: 'Shart',
                controller: _formulaExpression,
              ),
            ],
            const SizedBox(height: 16),
            _PlainActionButton(
              label: 'Saqlash',
              icon: Icons.check_rounded,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    final formulaTarget = _formulaTarget.text.trim();
    final formulaExpression = _formulaExpression.text.trim();
    Navigator.of(context).pop(
      ProductionMapNode(
        id: widget.node.id,
        kind: widget.node.kind,
        title: title.isEmpty ? widget.node.title : title,
        roleCode: _roleCode.text.trim(),
        x: widget.node.x,
        y: widget.node.y,
        formula:
            widget.node.kind == 'formula' || widget.node.kind == 'condition'
                ? ProductionFormula(
                    target: widget.node.kind == 'condition'
                        ? ''
                        : formulaTarget.isEmpty
                            ? 'result'
                            : formulaTarget,
                    expression: formulaExpression.isEmpty
                        ? widget.node.formula?.expression ?? 'order_qty'
                        : formulaExpression,
                  )
                : null,
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _FormulaSheetField extends StatefulWidget {
  const _FormulaSheetField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  State<_FormulaSheetField> createState() => _FormulaSheetFieldState();
}

class _FormulaSheetFieldState extends State<_FormulaSheetField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant _FormulaSheetField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_sync);
    widget.controller.addListener(_sync);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openEditor() async {
    final edited = await showModalBottomSheet<String>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) => _FormulaEditorSheet(
        title: widget.label,
        expression: widget.controller.text,
      ),
    );
    if (edited == null || !mounted) {
      return;
    }
    widget.controller.text = edited;
  }

  @override
  Widget build(BuildContext context) {
    final display = _formulaDisplayText(widget.controller.text);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openEditor,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: const Icon(Icons.open_in_full_rounded),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          display.isEmpty ? ' ' : display,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _FormulaEditorSheet extends StatefulWidget {
  const _FormulaEditorSheet({
    required this.title,
    required this.expression,
  });

  final String title;
  final String expression;

  @override
  State<_FormulaEditorSheet> createState() => _FormulaEditorSheetState();
}

class _FormulaEditorSheetState extends State<_FormulaEditorSheet> {
  late final _FormulaAutocompleteController _expression;
  final FocusNode _expressionFocusNode = FocusNode();
  _FormulaVariable? _suggestion;

  @override
  void initState() {
    super.initState();
    _expression = _FormulaAutocompleteController(
      text: _formulaDisplayText(widget.expression),
    );
    _expression.addListener(_updateSuggestion);
    _updateSuggestion();
  }

  @override
  void dispose() {
    _expression.dispose();
    _expressionFocusNode.dispose();
    super.dispose();
  }

  void _updateSuggestion() {
    final next = _expression.suggestion;
    if (next == _suggestion) {
      return;
    }
    setState(() => _suggestion = next);
  }

  void _insertVariable(_FormulaVariable variable,
      {bool addTrailingSpace = false}) {
    final selection = _expression.selection;
    final text = _expression.text;
    final cursor = selection.isValid ? selection.baseOffset : text.length;
    final start = _expression.segmentStart();
    final before = text.substring(0, start);
    final after = text.substring(cursor.clamp(0, text.length));
    final insertText = addTrailingSpace ? '${variable.label} ' : variable.label;
    final nextText = '$before$insertText$after';
    final nextOffset = before.length + insertText.length;
    _expression.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }

  void _keepFormulaFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _expressionFocusNode.requestFocus();
      }
    });
  }

  void _save() {
    Navigator.of(context).pop(
      _formulaInternalText(_expression.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 16, height: 1.35);
    return _DismissibleBottomSheetFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const SizedBox(width: 44, height: 4),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${widget.title} yozish',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _expression,
              focusNode: _expressionFocusNode,
              autofocus: true,
              minLines: 5,
              maxLines: 8,
              style: textStyle,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {},
              onSubmitted: (_) {
                final active = _suggestion;
                if (active != null && _expression.ghostCompletion.isNotEmpty) {
                  _insertVariable(active, addTrailingSpace: true);
                }
                _keepFormulaFocus();
              },
              decoration: InputDecoration(
                labelText: widget.title,
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final variable in _formulaVariables)
                  InputChip(
                    label: Text(variable.label),
                    onPressed: () => _insertVariable(variable),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _PlainActionButton(
              label: 'Saqlash',
              icon: Icons.check_rounded,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}
