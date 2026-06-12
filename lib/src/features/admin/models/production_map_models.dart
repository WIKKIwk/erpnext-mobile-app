class ProductionMapDefinition {
  const ProductionMapDefinition({
    required this.id,
    required this.productCode,
    required this.title,
    this.code = '',
    this.orderNumber = '',
    this.rollCount,
    this.widthMm,
    required this.nodes,
    required this.edges,
  });

  final String id;
  final String productCode;
  final String title;
  final String code;
  final String orderNumber;
  final double? rollCount;
  final double? widthMm;
  final List<ProductionMapNode> nodes;
  final List<ProductionMapEdge> edges;

  factory ProductionMapDefinition.fromJson(Map<String, dynamic> json) {
    return ProductionMapDefinition(
      id: json['id'] as String? ?? '',
      productCode: json['product_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      code: json['code'] as String? ?? '',
      orderNumber: json['order_number'] as String? ?? '',
      rollCount: (json['roll_count'] as num?)?.toDouble(),
      widthMm: (json['width_mm'] as num?)?.toDouble(),
      nodes: (json['nodes'] as List<dynamic>? ?? const [])
          .map((item) =>
              ProductionMapNode.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      edges: (json['edges'] as List<dynamic>? ?? const [])
          .map((item) =>
              ProductionMapEdge.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_code': productCode,
      'title': title,
      if (code.trim().isNotEmpty) 'code': code.trim(),
      if (orderNumber.trim().isNotEmpty) 'order_number': orderNumber.trim(),
      if (rollCount != null) 'roll_count': rollCount,
      if (widthMm != null) 'width_mm': widthMm,
      'nodes': nodes.map((node) => node.toJson()).toList(growable: false),
      'edges': edges.map((edge) => edge.toJson()).toList(growable: false),
    };
  }

  ProductionMapDefinition copyWith({
    String? id,
    String? productCode,
    String? title,
    String? code,
    String? orderNumber,
    double? rollCount,
    double? widthMm,
    List<ProductionMapNode>? nodes,
    List<ProductionMapEdge>? edges,
  }) {
    return ProductionMapDefinition(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      title: title ?? this.title,
      code: code ?? this.code,
      orderNumber: orderNumber ?? this.orderNumber,
      rollCount: rollCount ?? this.rollCount,
      widthMm: widthMm ?? this.widthMm,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  ProductionMapDefinition withoutAlternativeAssignments() {
    return copyWith(
      nodes: [
        for (final node in nodes) node.withoutAlternativeAssignment(),
      ],
    );
  }
}

class ProductionMapNode {
  const ProductionMapNode({
    required this.id,
    required this.kind,
    required this.title,
    this.formula,
    this.roleCode = '',
    this.itemCode = '',
    this.qtyFormula = '',
    this.fromLocation = '',
    this.toLocation = '',
    this.alternativeGroupId = '',
    this.alternativeGroupLabel = '',
    this.alternativeAssignedTitle = '',
    this.x = 0,
    this.y = 0,
  });

  final String id;
  final String kind;
  final String title;
  final ProductionFormula? formula;
  final String roleCode;
  final String itemCode;
  final String qtyFormula;
  final String fromLocation;
  final String toLocation;
  final String alternativeGroupId;
  final String alternativeGroupLabel;
  final String alternativeAssignedTitle;
  final double x;
  final double y;

  ProductionMapNode copyWith({
    String? id,
    String? kind,
    String? title,
    ProductionFormula? formula,
    String? roleCode,
    String? itemCode,
    String? qtyFormula,
    String? fromLocation,
    String? toLocation,
    String? alternativeGroupId,
    String? alternativeGroupLabel,
    String? alternativeAssignedTitle,
    double? x,
    double? y,
  }) {
    return ProductionMapNode(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      formula: formula ?? this.formula,
      roleCode: roleCode ?? this.roleCode,
      itemCode: itemCode ?? this.itemCode,
      qtyFormula: qtyFormula ?? this.qtyFormula,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      alternativeGroupId: alternativeGroupId ?? this.alternativeGroupId,
      alternativeGroupLabel:
          alternativeGroupLabel ?? this.alternativeGroupLabel,
      alternativeAssignedTitle:
          alternativeAssignedTitle ?? this.alternativeAssignedTitle,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  factory ProductionMapNode.fromJson(Map<String, dynamic> json) {
    return ProductionMapNode(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'task',
      title: json['title'] as String? ?? '',
      formula: json['formula'] is Map<String, dynamic>
          ? ProductionFormula.fromJson(json['formula'] as Map<String, dynamic>)
          : null,
      roleCode: json['role_code'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      qtyFormula: json['qty_formula'] as String? ?? '',
      fromLocation: json['from_location'] as String? ?? '',
      toLocation: json['to_location'] as String? ?? '',
      alternativeGroupId: json['alternative_group_id'] as String? ?? '',
      alternativeGroupLabel: json['alternative_group_label'] as String? ?? '',
      alternativeAssignedTitle:
          json['alternative_assigned_title'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'title': title,
      if (formula != null) 'formula': formula!.toJson(),
      if (roleCode.trim().isNotEmpty) 'role_code': roleCode.trim(),
      if (itemCode.trim().isNotEmpty) 'item_code': itemCode.trim(),
      if (qtyFormula.trim().isNotEmpty) 'qty_formula': qtyFormula.trim(),
      if (fromLocation.trim().isNotEmpty) 'from_location': fromLocation.trim(),
      if (toLocation.trim().isNotEmpty) 'to_location': toLocation.trim(),
      if (alternativeGroupId.trim().isNotEmpty)
        'alternative_group_id': alternativeGroupId.trim(),
      if (alternativeGroupLabel.trim().isNotEmpty)
        'alternative_group_label': alternativeGroupLabel.trim(),
      if (alternativeAssignedTitle.trim().isNotEmpty)
        'alternative_assigned_title': alternativeAssignedTitle.trim(),
      'x': x,
      'y': y,
    };
  }

  ProductionMapNode withoutAlternativeAssignment() {
    return alternativeAssignedTitle.trim().isEmpty
        ? this
        : copyWith(alternativeAssignedTitle: '');
  }
}

class ProductionFormula {
  const ProductionFormula({
    required this.target,
    required this.expression,
  });

  final String target;
  final String expression;

  factory ProductionFormula.fromJson(Map<String, dynamic> json) {
    return ProductionFormula(
      target: json['target'] as String? ?? '',
      expression: json['expression'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target': target,
      'expression': expression,
    };
  }
}

class ProductionMapEdge {
  const ProductionMapEdge({
    required this.from,
    required this.to,
    this.branch = '',
  });

  final String from;
  final String to;
  final String branch;

  factory ProductionMapEdge.fromJson(Map<String, dynamic> json) {
    return ProductionMapEdge(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      if (branch.trim().isNotEmpty) 'branch': branch.trim(),
    };
  }
}

class ProductionMapSaved {
  const ProductionMapSaved({
    required this.map,
    required this.program,
  });

  final ProductionMapDefinition map;
  final ProductionMapProgram program;

  factory ProductionMapSaved.fromJson(Map<String, dynamic> json) {
    return ProductionMapSaved(
      map: ProductionMapDefinition.fromJson(
        json['map'] as Map<String, dynamic>,
      ),
      program: ProductionMapProgram.fromJson(
        json['program'] as Map<String, dynamic>,
      ),
    );
  }
}

class ProductionMapRunRequest {
  const ProductionMapRunRequest({
    required this.mapId,
    required this.productCode,
    required this.orderQty,
    this.variables = const {},
  });

  final String mapId;
  final String productCode;
  final double orderQty;
  final Map<String, double> variables;

  Map<String, dynamic> toJson() {
    return {
      'map_id': mapId,
      'product_code': productCode,
      'order_qty': orderQty,
      if (variables.isNotEmpty) 'variables': variables,
    };
  }
}

class ProductionTaskDraft {
  const ProductionTaskDraft({
    required this.order,
    required this.nodeId,
    required this.taskKind,
    required this.title,
    required this.roleCode,
    required this.itemCode,
    required this.fromLocation,
    required this.toLocation,
    required this.qty,
  });

  final int order;
  final String nodeId;
  final String taskKind;
  final String title;
  final String roleCode;
  final String itemCode;
  final String fromLocation;
  final String toLocation;
  final double qty;

  factory ProductionTaskDraft.fromJson(Map<String, dynamic> json) {
    return ProductionTaskDraft(
      order: (json['order'] as num?)?.toInt() ?? 0,
      nodeId: json['node_id'] as String? ?? '',
      taskKind: json['task_kind'] as String? ?? '',
      title: json['title'] as String? ?? '',
      roleCode: json['role_code'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      fromLocation: json['from_location'] as String? ?? '',
      toLocation: json['to_location'] as String? ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ProductionMapRunResult {
  const ProductionMapRunResult({
    required this.mapId,
    required this.productCode,
    required this.orderQty,
    required this.variables,
    required this.tasks,
    required this.visitedNodeIds,
    required this.awaitingNodeId,
    required this.awaitingVariable,
    required this.awaitingExpression,
  });

  final String mapId;
  final String productCode;
  final double orderQty;
  final Map<String, double> variables;
  final List<ProductionTaskDraft> tasks;
  final List<String> visitedNodeIds;
  final String awaitingNodeId;
  final String awaitingVariable;
  final String awaitingExpression;

  factory ProductionMapRunResult.fromJson(Map<String, dynamic> json) {
    return ProductionMapRunResult(
      mapId: json['map_id'] as String? ?? '',
      productCode: json['product_code'] as String? ?? '',
      orderQty: (json['order_qty'] as num?)?.toDouble() ?? 0,
      variables: (json['variables'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
      ),
      tasks: (json['tasks'] as List<dynamic>? ?? const [])
          .map((item) => ProductionTaskDraft.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(growable: false),
      visitedNodeIds: (json['visited_node_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      awaitingNodeId: json['awaiting_node_id'] as String? ?? '',
      awaitingVariable: json['awaiting_variable'] as String? ?? '',
      awaitingExpression: json['awaiting_expression'] as String? ?? '',
    );
  }
}

class ProductionMapProgram {
  const ProductionMapProgram({
    required this.mapId,
    required this.productCode,
    required this.operations,
  });

  final String mapId;
  final String productCode;
  final List<ProductionMapOperation> operations;

  factory ProductionMapProgram.fromJson(Map<String, dynamic> json) {
    return ProductionMapProgram(
      mapId: json['map_id'] as String? ?? '',
      productCode: json['product_code'] as String? ?? '',
      operations: (json['operations'] as List<dynamic>? ?? const [])
          .map((item) =>
              ProductionMapOperation.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class ProductionMapOperation {
  const ProductionMapOperation({
    required this.order,
    required this.nodeId,
    required this.opCode,
    required this.args,
  });

  final int order;
  final String nodeId;
  final String opCode;
  final Map<String, String> args;

  factory ProductionMapOperation.fromJson(Map<String, dynamic> json) {
    return ProductionMapOperation(
      order: (json['order'] as num?)?.toInt() ?? 0,
      nodeId: json['node_id'] as String? ?? '',
      opCode: json['op_code'] as String? ?? '',
      args: (json['args'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      ),
    );
  }
}
