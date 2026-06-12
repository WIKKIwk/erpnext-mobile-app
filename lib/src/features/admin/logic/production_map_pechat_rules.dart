import 'dart:math' as math;

import '../models/production_map_models.dart';

int productionMapRubberSizeFromWidth(double widthMm) {
  return (widthMm / 50).ceil().clamp(1, 26).toInt() * 50;
}

String productionMapPechatTabLabel(String warehouse) {
  final count = productionMapPechatColorCount(warehouse);
  if (count != null) {
    return '$count ta rangli pechat';
  }
  return warehouse.trim();
}

int? productionMapPechatColorCount(String title) {
  final match = RegExp(
    r'\b([789])\s*(?:ta)?\s*rangli(?:\s*(?:pechat|val|aparat))?\b',
    caseSensitive: false,
  ).firstMatch(title.trim().toLowerCase());
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1) ?? '');
}

int? productionMapRecommendedPechatColorCount({
  double? rollCount,
  double? widthMm,
}) {
  final hasRoll = rollCount != null && rollCount > 0;
  final hasWidth = widthMm != null && widthMm > 0;
  if (!hasRoll && !hasWidth) {
    return null;
  }

  var requiredColorCount = 0;
  if (hasRoll) {
    if (rollCount > 9) {
      return null;
    }
    requiredColorCount = rollCount > 8
        ? 9
        : rollCount > 7
            ? 8
            : 7;
  }
  if (hasWidth) {
    final rubberSize = productionMapRubberSizeFromWidth(widthMm);
    if (rubberSize > 1300) {
      return null;
    }
    final rubberColorCount = rubberSize > 1000
        ? 9
        : rubberSize > 800
            ? 8
            : 7;
    requiredColorCount = math.max(requiredColorCount, rubberColorCount);
  }
  return requiredColorCount == 0 ? null : requiredColorCount;
}

bool productionMapPechatCanHandleOrder({
  required int apparatusColorCount,
  required double? rollCount,
  required double? widthMm,
}) {
  if (rollCount != null && rollCount > apparatusColorCount) {
    return false;
  }
  if (widthMm == null || widthMm <= 0) {
    return true;
  }
  final rubberSize = productionMapRubberSizeFromWidth(widthMm);
  return switch (apparatusColorCount) {
    7 => rubberSize <= 800,
    8 => rubberSize >= 150 && rubberSize <= 1000,
    9 => rubberSize >= 800 && rubberSize <= 1300,
    _ => false,
  };
}

int? productionMapOrderPechatColorCount(Iterable<String> apparatusTitles) {
  var highest = 0;
  for (final title in apparatusTitles) {
    final colorCount = productionMapPechatColorCount(title);
    if (colorCount != null && colorCount > highest) {
      highest = colorCount;
    }
  }
  return highest == 0 ? null : highest;
}

String productionMapPechatApparatusLabel(int colorCount) {
  return '$colorCount ta rangli pechat';
}

List<int> productionMapCompatiblePechatColorCounts({
  required double? rollCount,
  required double? widthMm,
}) {
  final recommended = productionMapRecommendedPechatColorCount(
    rollCount: rollCount,
    widthMm: widthMm,
  );
  return [
    for (final count in [7, 8, 9])
      if ((recommended == null || count >= recommended) &&
          productionMapPechatCanHandleOrder(
            apparatusColorCount: count,
            rollCount: rollCount,
            widthMm: widthMm,
          ))
        count,
  ];
}

String productionMapPechatCompatibilitySummary({
  required double? rollCount,
  required double? widthMm,
}) {
  final recommended = productionMapRecommendedPechatColorCount(
    rollCount: rollCount,
    widthMm: widthMm,
  );
  final compatible = productionMapCompatiblePechatColorCounts(
    rollCount: rollCount,
    widthMm: widthMm,
  );
  if (compatible.isEmpty) {
    return 'Mos pechat topilmadi';
  }
  final compatibleText =
      compatible.map(productionMapPechatApparatusLabel).join(', ');
  if (recommended == null) {
    return 'Mos pechat: $compatibleText';
  }
  return 'Minimal ${productionMapPechatApparatusLabel(recommended)} • '
      'Mos: $compatibleText';
}

bool productionMapPechatCanMoveOrder({
  required int apparatusColorCount,
  required double? rollCount,
  required double? widthMm,
  int? sourceApparatusColorCount,
}) {
  final recommended = productionMapRecommendedPechatColorCount(
    rollCount: rollCount,
    widthMm: widthMm,
  );
  if (recommended != null && apparatusColorCount < recommended) {
    return false;
  }
  final movingDown = sourceApparatusColorCount != null &&
      apparatusColorCount < sourceApparatusColorCount;
  if (movingDown) {
    if (widthMm == null || widthMm <= 0) {
      return false;
    }
    return productionMapPechatCanHandleOrder(
      apparatusColorCount: apparatusColorCount,
      rollCount: rollCount,
      widthMm: widthMm,
    );
  }
  if (rollCount == null || rollCount <= 0 || widthMm == null || widthMm <= 0) {
    return apparatusColorCount != 9;
  }
  return productionMapPechatCanHandleOrder(
    apparatusColorCount: apparatusColorCount,
    rollCount: rollCount,
    widthMm: widthMm,
  );
}

/// Strips trailing instance suffixes such as ` - A` from warehouse titles.
String productionMapWarehouseBaseTitle(String title) {
  final trimmed = title.trim();
  final match = RegExp(
    r'^(.*)\s+-\s+[A-Z0-9_-]+$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  return match?.group(1)?.trim() ?? trimmed;
}

bool productionMapIsLaminatsiyaApparatus(String title) {
  return productionMapWarehouseBaseTitle(title)
      .toLowerCase()
      .contains('laminatsiya');
}

bool productionMapTextIsFlexoOrder(Iterable<String> values) {
  final haystack = values.join(' ').toLowerCase();
  return const ['fleksa', 'fleska', 'flex', 'flexe', 'flexo'].any(
    haystack.contains,
  );
}

bool productionMapIsFlexoOrder(ProductionMapDefinition map) {
  return productionMapTextIsFlexoOrder([
    map.title,
    map.productCode,
    map.code,
    for (final node in map.nodes)
      if (node.kind != 'apparatus') ...[
        node.title,
        node.itemCode,
      ],
  ]);
}

bool productionMapWarehouseTitlesMatch(String left, String right) {
  final normalizedLeft = left.trim();
  final normalizedRight = right.trim();
  if (normalizedLeft.isEmpty || normalizedRight.isEmpty) {
    return false;
  }
  if (normalizedLeft == normalizedRight) {
    return true;
  }
  if (productionMapApparatusNodeMatchesFrom(
        nodeTitle: normalizedLeft,
        fromApparatus: normalizedRight,
      ) ||
      productionMapApparatusNodeMatchesFrom(
        nodeTitle: normalizedRight,
        fromApparatus: normalizedLeft,
      )) {
    return true;
  }
  return productionMapWarehouseBaseTitle(normalizedLeft).toLowerCase() ==
      productionMapWarehouseBaseTitle(normalizedRight).toLowerCase();
}

bool productionMapAlternativeAssignedGroupContainsTarget({
  required List<ProductionMapNode> nodes,
  required String fromApparatus,
  required String toApparatus,
}) {
  final candidateGroups = <String>{};
  for (final node in nodes) {
    final groupId = node.alternativeGroupId.trim();
    if (node.kind == 'apparatus' &&
        groupId.isNotEmpty &&
        productionMapWarehouseTitlesMatch(
          node.alternativeAssignedTitle,
          fromApparatus,
        )) {
      candidateGroups.add(groupId);
    }
  }
  if (candidateGroups.isEmpty) {
    return true;
  }
  return nodes.any(
    (node) =>
        node.kind == 'apparatus' &&
        candidateGroups.contains(node.alternativeGroupId.trim()) &&
        productionMapWarehouseTitlesMatch(node.title, toApparatus),
  );
}

bool productionMapCanMoveOrderToApparatus({
  required List<ProductionMapNode> nodes,
  required String fromApparatus,
  required String toApparatus,
  required double? rollCount,
  required double? widthMm,
  bool isFlexoOrder = false,
}) {
  final fromIsLaminatsiya = productionMapIsLaminatsiyaApparatus(fromApparatus);
  final toIsLaminatsiya = productionMapIsLaminatsiyaApparatus(toApparatus);
  if (fromIsLaminatsiya || toIsLaminatsiya) {
    return fromIsLaminatsiya &&
        toIsLaminatsiya &&
        productionMapAlternativeAssignedGroupContainsTarget(
          nodes: nodes,
          fromApparatus: fromApparatus,
          toApparatus: toApparatus,
        );
  }
  final targetColorCount = productionMapPechatColorCount(toApparatus);
  if (targetColorCount == null) {
    return true;
  }
  if (isFlexoOrder) {
    return false;
  }
  final sourceColorCount = productionMapPechatColorCount(fromApparatus) ??
      productionMapOrderPechatColorCount(
        nodes
            .where((node) => node.kind == 'apparatus')
            .map((node) => node.title),
      );
  return productionMapPechatCanMoveOrder(
    apparatusColorCount: targetColorCount,
    rollCount: rollCount,
    widthMm: widthMm,
    sourceApparatusColorCount: sourceColorCount,
  );
}

/// Whether an apparatus node belongs to the source warehouse/pechat being moved
/// from. Pechat nodes match by color count so minor title suffixes still work.
bool productionMapApparatusNodeMatchesFrom({
  required String nodeTitle,
  required String fromApparatus,
}) {
  final from = fromApparatus.trim();
  final title = nodeTitle.trim();
  if (title == from ||
      productionMapWarehouseBaseTitle(title).toLowerCase() ==
          productionMapWarehouseBaseTitle(from).toLowerCase()) {
    return true;
  }
  final fromColor = productionMapPechatColorCount(from);
  if (fromColor == null) {
    return false;
  }
  return productionMapPechatColorCount(nodeTitle) == fromColor;
}

/// Reassigns the chosen apparatus for alternative-group maps.
/// Returns null when the order is not currently assigned to [fromApparatus].
List<ProductionMapNode>? productionMapReassignAlternativeApparatusAssignment({
  required List<ProductionMapNode> nodes,
  required String fromApparatus,
  required String toApparatus,
}) {
  final to = toApparatus.trim();
  if (to.isEmpty) {
    return null;
  }
  final candidateGroups = <String>{};
  for (final node in nodes) {
    final groupId = node.alternativeGroupId.trim();
    if (node.kind == 'apparatus' &&
        groupId.isNotEmpty &&
        productionMapWarehouseTitlesMatch(
          node.alternativeAssignedTitle,
          fromApparatus,
        )) {
      candidateGroups.add(groupId);
    }
  }
  if (candidateGroups.isEmpty) {
    return null;
  }
  return [
    for (final node in nodes)
      node.kind == 'apparatus' &&
              candidateGroups.contains(node.alternativeGroupId.trim())
          ? node.copyWith(alternativeAssignedTitle: to)
          : node,
  ];
}

/// Reassigns apparatus nodes from [fromApparatus] to [toApparatus].
/// Returns null when no matching source node was found.
List<ProductionMapNode>? productionMapReassignApparatusNodes({
  required List<ProductionMapNode> nodes,
  required String fromApparatus,
  required String toApparatus,
}) {
  final to = toApparatus.trim();
  var changed = false;
  final next = nodes.map((node) {
    if (node.kind == 'apparatus' &&
        productionMapApparatusNodeMatchesFrom(
          nodeTitle: node.title,
          fromApparatus: fromApparatus,
        )) {
      changed = true;
      return node.copyWith(title: to);
    }
    return node;
  }).toList(growable: false);
  return changed ? next : null;
}
