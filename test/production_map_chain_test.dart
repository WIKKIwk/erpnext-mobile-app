import 'package:erpnext_stock_mobile/src/features/admin/logic/apparatus_queue_state.dart';
import 'package:erpnext_stock_mobile/src/features/admin/logic/production_map_chain.dart';
import 'package:erpnext_stock_mobile/src/features/admin/logic/production_map_pechat_rules.dart';
import 'package:erpnext_stock_mobile/src/features/admin/models/production_map_models.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

ProductionMapDefinition _hotlunchMap() {
  ProductionMapNode node(String id, String kind, String title) {
    return ProductionMapNode(id: id, kind: kind, title: title);
  }

  return ProductionMapDefinition(
    id: 'zakaz-hot',
    productCode: 'HOT',
    title: 'Hotlunch',
    nodes: [
      node('start', 'start', 'Start'),
      node('order', 'task', 'Hotlunch mahsulot'),
      node('pechat', 'apparatus', '9 ta rangli pechat - A'),
      node('lamin', 'task', 'Laminatsiya'),
      node('rezka', 'apparatus', 'Rezka aparat - A'),
      node('end', 'end', 'End'),
    ],
    edges: const [
      ProductionMapEdge(from: 'start', to: 'order'),
      ProductionMapEdge(from: 'order', to: 'pechat'),
      ProductionMapEdge(from: 'pechat', to: 'lamin'),
      ProductionMapEdge(from: 'lamin', to: 'rezka'),
      ProductionMapEdge(from: 'rezka', to: 'end'),
    ],
  );
}

ProductionMapDefinition _pechatOnlyMap() {
  ProductionMapNode node(String id, String kind, String title) {
    return ProductionMapNode(id: id, kind: kind, title: title);
  }

  return ProductionMapDefinition(
    id: 'zakaz-1236',
    productCode: 'ZEN',
    title: 'Zenit',
    nodes: [
      node('start', 'start', 'Start'),
      node('order', 'task', 'zenit frutto ninja 70 gr'),
      node('pechat', 'apparatus', '7 ta rangli pechat - A'),
      node('end', 'end', 'End'),
    ],
    edges: const [
      ProductionMapEdge(from: 'start', to: 'order'),
      ProductionMapEdge(from: 'order', to: 'pechat'),
      ProductionMapEdge(from: 'pechat', to: 'end'),
    ],
  );
}

void main() {
  test('production map node preserves alternative group metadata', () {
    const node = ProductionMapNode(
      id: 'apparatus-7',
      kind: 'apparatus',
      title: '7 ta rangli pechat',
      alternativeGroupId: 'alt-pechat-1',
      alternativeGroupLabel: 'pechat',
      alternativeAssignedTitle: '7 ta rangli pechat',
    );

    final restored = ProductionMapNode.fromJson(node.toJson());

    expect(restored.alternativeGroupId, 'alt-pechat-1');
    expect(restored.alternativeGroupLabel, 'pechat');
    expect(restored.alternativeAssignedTitle, '7 ta rangli pechat');
    expect(restored.toJson()['alternative_group_id'], 'alt-pechat-1');
    expect(restored.toJson()['alternative_group_label'], 'pechat');
    expect(
      restored.toJson()['alternative_assigned_title'],
      '7 ta rangli pechat',
    );
  });

  test('production map can clear alternative assignment state only', () {
    const assignedNode = ProductionMapNode(
      id: 'apparatus-7',
      kind: 'apparatus',
      title: '7 ta rangli pechat',
      alternativeGroupId: 'alt-pechat-1',
      alternativeGroupLabel: 'pechat',
      alternativeAssignedTitle: '8 ta rangli pechat',
      x: 24,
      y: 48,
    );
    const cleanNode = ProductionMapNode(
      id: 'end',
      kind: 'end',
      title: 'End',
    );
    const edge = ProductionMapEdge(from: 'apparatus-7', to: 'end');
    const map = ProductionMapDefinition(
      id: 'zakaz-template',
      productCode: 'ITEM-1',
      title: 'Template',
      code: '4444',
      orderNumber: '4444',
      rollCount: 7,
      widthMm: 650,
      nodes: [assignedNode, cleanNode],
      edges: [edge],
    );

    final cleanMap = map.withoutAlternativeAssignments();

    expect(cleanMap.id, map.id);
    expect(cleanMap.productCode, map.productCode);
    expect(cleanMap.code, map.code);
    expect(cleanMap.orderNumber, map.orderNumber);
    expect(cleanMap.rollCount, map.rollCount);
    expect(cleanMap.widthMm, map.widthMm);
    expect(cleanMap.edges, map.edges);
    expect(cleanMap.nodes.first.alternativeGroupId, 'alt-pechat-1');
    expect(cleanMap.nodes.first.alternativeGroupLabel, 'pechat');
    expect(cleanMap.nodes.first.alternativeAssignedTitle, '');
    expect(identical(cleanMap.nodes.last, cleanNode), isTrue);
  });

  test('admin apparatus group normalizes server json shape', () {
    final group = AdminApparatusGroup.fromJson(const {
      'name': 'pechat',
      'apparatus': ['7 ta rangli pechat', '8 ta rangli pechat'],
    });

    expect(group.name, 'pechat');
    expect(group.apparatus, ['7 ta rangli pechat', '8 ta rangli pechat']);
    expect(group.toJson(), {
      'name': 'pechat',
      'apparatus': ['7 ta rangli pechat', '8 ta rangli pechat'],
    });
  });

  test('warehouse suffix titles match', () {
    expect(productionMapWarehouseTitlesMatch('Laminatsiya - A', 'Laminatsiya'),
        isTrue);
    expect(
        productionMapWarehouseTitlesMatch('Paket aparat - A', 'Paket aparat'),
        isTrue);
  });

  test('linear work stages skip product task before first apparatus', () {
    final stages = productionMapLinearWorkStages(_hotlunchMap());
    expect(
      stages.map((stage) => stage.stationTitle).toList(),
      ['9 ta rangli pechat - A', 'Laminatsiya', 'Rezka aparat - A'],
    );
  });

  test('laminatsiya tab sees orders only when map includes that stage', () {
    expect(
      productionMapMapHasWorkStageForStation(
        map: _hotlunchMap(),
        station: 'Laminatsiya - A',
      ),
      isTrue,
    );
    expect(
      productionMapMapHasWorkStageForStation(
        map: _pechatOnlyMap(),
        station: 'Laminatsiya - A',
      ),
      isFalse,
    );
  });

  test('later stage waits for previous completion', () {
    final map = _hotlunchMap();
    const states = <String, Map<String, String>>{};

    expect(
      productionMapOrderReadyForStation(
        map: map,
        orderId: 'zakaz-hot',
        station: 'Laminatsiya - A',
        queueStatesByApparatus: states,
      ),
      isFalse,
    );

    final withPechatDone = {
      '9 ta rangli pechat - A': {'zakaz-hot': 'completed'},
    };
    expect(
      productionMapOrderReadyForStation(
        map: map,
        orderId: 'zakaz-hot',
        station: 'Laminatsiya - A',
        queueStatesByApparatus: withPechatDone,
      ),
      isTrue,
    );
  });

  test('first actionable skips orders blocked by chain', () {
    final actionable = firstActionableQueueOrderId(
      sequence: const ['zakaz-a', 'zakaz-b'],
      states: const {},
      isOrderReady: (id) => id != 'zakaz-a',
    );
    expect(actionable, 'zakaz-b');
  });
}
