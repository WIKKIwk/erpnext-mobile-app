import 'package:erpnext_stock_mobile/src/core/api/mobile_api.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/core/test_mode/test_mode_controller.dart';
import 'package:erpnext_stock_mobile/src/features/admin/logic/production_map_pechat_rules.dart';
import 'package:erpnext_stock_mobile/src/features/admin/models/production_map_models.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_production_map_test_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.admin,
      displayName: 'Admin',
      legalName: 'Admin',
      ref: 'ADMIN-001',
      phone: '',
      avatarUrl: '',
    );
    await TestModeController.instance.setEnabled(true);
    setMobileApiTestModeForceSequenceSaveFailure(false);
    setMobileApiTestModeForceCalculateTemplateSaveFailure(false);
  });

  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
    setMobileApiTestModeForceSequenceSaveFailure(false);
    setMobileApiTestModeForceCalculateTemplateSaveFailure(false);
  });

  testWidgets('re-saving opened zakaz skips order number dialog',
      (tester) async {
    final saved = await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-4444',
        title: 'Locked order',
        productCode: 'LOCK-4444',
        apparatus: '7 ta rangli pechat',
        product: 'locked product',
        orderNumber: '4444',
      ),
    );
    await _usePhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminProductionMapTestScreen(savedMap: saved.map),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('production-map-save')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('production-map-order-number-field')),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.text('Production map saqlandi'), findsOneWidget);

    final maps = await MobileApi.instance.adminProductionMaps();
    final updated = maps.firstWhere((item) => item.map.id == 'zakaz-4444');
    expect(updated.map.orderNumber, '4444');
    await tester.pump(const Duration(seconds: 2));
  });

  test('pechat move allows dual-compatible order from 7 to 8 color', () {
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 8,
        rollCount: 7,
        widthMm: 650,
        sourceApparatusColorCount: 7,
      ),
      isTrue,
    );
  });

  test('batch move allows 7-color order with suffix title to 8-color pechat',
      () async {
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-7100',
        title: 'Seven to eight',
        productCode: 'SE-7100',
        apparatus: '7 ta rangli pechat - A',
        product: 'dual pechat order',
        orderNumber: '7100',
        rollCount: 7,
        widthMm: 650,
      ),
    );

    final moved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
      mapIds: const ['zakaz-7100'],
      fromApparatus: '7 ta rangli pechat',
      toApparatus: '8 ta rangli pechat',
    );
    expect(moved, hasLength(1));
    expect(
      moved.first.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.title)
          .first,
      '8 ta rangli pechat',
    );
  });

  test('batch move is all-or-nothing for pechat orders', () async {
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-7001',
        title: 'Batch A',
        productCode: 'B-A',
        apparatus: '7 ta rangli pechat',
        product: 'batch A',
        orderNumber: '7001',
        rollCount: 7,
        widthMm: 650,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-7002',
        title: 'Batch B',
        productCode: 'B-B',
        apparatus: '7 ta rangli pechat',
        product: 'batch B',
        orderNumber: '7002',
        rollCount: 7,
        widthMm: 650,
      ),
    );

    await expectLater(
      MobileApi.instance.adminMoveProductionMapOrdersBatch(
        mapIds: const ['zakaz-7001', 'zakaz-missing'],
        fromApparatus: '7 ta rangli pechat',
        toApparatus: '8 ta rangli pechat',
      ),
      throwsA(isA<MobileApiException>()),
    );

    final maps = await MobileApi.instance.adminProductionMaps();
    for (final id in ['zakaz-7001', 'zakaz-7002']) {
      final map = maps.firstWhere((item) => item.map.id == id);
      final apparatus = map.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.title)
          .first;
      expect(apparatus, '7 ta rangli pechat');
    }

    final moved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
      mapIds: const ['zakaz-7001', 'zakaz-7002'],
      fromApparatus: '7 ta rangli pechat',
      toApparatus: '8 ta rangli pechat',
    );
    expect(moved, hasLength(2));
    for (final saved in moved) {
      final apparatus = saved.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.title)
          .first;
      expect(apparatus, '8 ta rangli pechat');
    }
  });

  test('batch move stress handles many pechat orders without partial updates',
      () async {
    for (var index = 0; index < 30; index++) {
      final number = (8000 + index).toString();
      await MobileApi.instance.adminSaveProductionMap(
        _productionOrderMap(
          id: 'zakaz-$number',
          title: 'Stress $number',
          productCode: 'S-$number',
          apparatus: '7 ta rangli pechat',
          product: 'stress $number',
          orderNumber: number,
          rollCount: 7,
          widthMm: 650,
        ),
      );
    }

    final ids = [
      for (var index = 0; index < 30; index++) 'zakaz-${8000 + index}',
    ];
    final moved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
      mapIds: ids,
      fromApparatus: '7 ta rangli pechat',
      toApparatus: '8 ta rangli pechat',
    );
    expect(moved, hasLength(30));

    final maps = await MobileApi.instance.adminProductionMaps();
    for (final id in ids) {
      final map = maps.firstWhere((item) => item.map.id == id);
      final apparatus = map.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.title)
          .first;
      expect(apparatus, '8 ta rangli pechat');
    }
  });

  test('batch move handles mixed direct and alternative pechat orders',
      () async {
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-mix-direct-1',
        title: 'Mix direct 1',
        productCode: 'MIX-D1',
        apparatus: '7 ta rangli pechat',
        product: 'mix direct 1',
        orderNumber: '8101',
        rollCount: 7,
        widthMm: 650,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-mix-direct-2',
        title: 'Mix direct 2',
        productCode: 'MIX-D2',
        apparatus: '7 ta rangli pechat',
        product: 'mix direct 2',
        orderNumber: '8102',
        rollCount: 7,
        widthMm: 650,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-mix-alt-1',
        title: 'Mix alternative 1',
        productCode: 'MIX-A1',
        product: 'mix alternative 1',
        orderNumber: '8103',
        rollCount: 7,
        widthMm: 650,
        assigned: '7 ta rangli pechat',
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-mix-alt-2',
        title: 'Mix alternative 2',
        productCode: 'MIX-A2',
        product: 'mix alternative 2',
        orderNumber: '8104',
        rollCount: 7,
        widthMm: 650,
        assigned: '7 ta rangli pechat',
      ),
    );

    const ids = [
      'zakaz-mix-direct-1',
      'zakaz-mix-direct-2',
      'zakaz-mix-alt-1',
      'zakaz-mix-alt-2',
    ];
    final moved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
      mapIds: ids,
      fromApparatus: '7 ta rangli pechat',
      toApparatus: '8 ta rangli pechat',
    );
    expect(moved, hasLength(4));

    final maps = await MobileApi.instance.adminProductionMaps();
    for (final id in ids.take(2)) {
      final map = maps.firstWhere((item) => item.map.id == id);
      final apparatus = map.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.title)
          .first;
      expect(apparatus, '8 ta rangli pechat');
    }
    for (final id in ids.skip(2)) {
      final map = maps.firstWhere((item) => item.map.id == id);
      final assigned = map.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.alternativeAssignedTitle)
          .where((title) => title.trim().isNotEmpty)
          .toSet();
      expect(assigned, {'8 ta rangli pechat'});
    }
  });

  test('batch move handles assigned alternatives without target title node',
      () async {
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-real-8768',
        title: 'tanlov lavash paket',
        productCode: 'tanlov lavash paket',
        product: 'tanlov lavash paket',
        orderNumber: '8768',
        rollCount: 7,
        widthMm: 640,
        assigned: '8 ta rangli pechat - A',
        apparatusTitles: const [
          '7 ta rangli pechat - A',
          '7 ta rangli pechat - A',
        ],
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-real-9875',
        title: 'standart lavash 20 sht paket',
        productCode: 'standart lavash 20 sht paket',
        product: 'standart lavash 20 sht paket',
        orderNumber: '9875',
        rollCount: 7,
        widthMm: 630,
        assigned: '8 ta rangli pechat - A',
        apparatusTitles: const [
          '7 ta rangli pechat - A',
          '7 ta rangli pechat - A',
        ],
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-real-6564',
        title: 'akhmedov since 2020',
        productCode: 'akhmedov since 2020',
        product: 'akhmedov since 2020',
        orderNumber: '6564',
        rollCount: 7,
        widthMm: 630,
        assigned: '8 ta rangli pechat - A',
        apparatusTitles: const [
          '7 ta rangli pechat - A',
          '7 ta rangli pechat - A',
        ],
      ),
    );

    const ids = [
      'zakaz-real-8768',
      'zakaz-real-9875',
      'zakaz-real-6564',
    ];
    final moved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
      mapIds: ids,
      fromApparatus: '8 ta rangli pechat - A',
      toApparatus: '7 ta rangli pechat - A',
    );
    expect(moved, hasLength(3));

    final maps = await MobileApi.instance.adminProductionMaps();
    for (final id in ids) {
      final map = maps.firstWhere((item) => item.map.id == id);
      final assigned = map.map.nodes
          .where((node) => node.kind == 'apparatus')
          .map((node) => node.alternativeAssignedTitle)
          .where((title) => title.trim().isNotEmpty)
          .toSet();
      expect(assigned, {'7 ta rangli pechat - A'});
    }
  });

  test(
      'batch move preserves alternative node titles when target title is absent',
      () async {
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-real-title-preserve',
        title: 'title preserve order',
        productCode: 'TITLE-PRESERVE',
        product: 'title preserve product',
        orderNumber: '8110',
        rollCount: 7,
        widthMm: 630,
        assigned: '7 ta rangli pechat - A',
        apparatusTitles: const [
          '7 ta rangli pechat - A',
          '7 ta rangli pechat - A',
        ],
      ),
    );

    final moved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
      mapIds: const ['zakaz-real-title-preserve'],
      fromApparatus: '7 ta rangli pechat - A',
      toApparatus: '8 ta rangli pechat - A',
    );
    expect(moved, hasLength(1));

    final map = (await MobileApi.instance.adminProductionMaps())
        .firstWhere((item) => item.map.id == 'zakaz-real-title-preserve')
        .map;
    final apparatus = map.nodes.where((node) => node.kind == 'apparatus');
    expect(
      apparatus.map((node) => node.title).toSet(),
      {'7 ta rangli pechat - A'},
    );
    expect(
      apparatus.map((node) => node.alternativeAssignedTitle).toSet(),
      {'8 ta rangli pechat - A'},
    );
  });

  test('with-order rolls back map when template upsert fails in test mode',
      () async {
    setMobileApiTestModeForceCalculateTemplateSaveFailure(true);
    await expectLater(
      MobileApi.instance.adminSaveProductionMapWithOrder(
        map: _productionOrderMap(
          id: 'zakaz-9001',
          title: 'Atomic fail',
          productCode: 'AF-9001',
          apparatus: '7 ta rangli pechat',
          product: 'atomic fail',
          orderNumber: '9001',
        ),
        template: CalculateOrderTemplate(
          id: '',
          code: '',
          name: 'valid template',
          savedAt: DateTime.now().toUtc(),
          orderNumber: '',
          customerRef: '',
          customer: '',
          itemCode: 'AF-9001',
          product: 'atomic fail',
          status: '',
          materialDisplay: '',
          color: '',
          imageId: '',
          imageName: '',
          imageMime: '',
          imageSizeBytes: 0,
          imageUrl: '',
          widthMm: 650,
          wastePercent: 5,
          rollCount: null,
          firstLayerMaterial: 'pet',
          firstLayerMicron: '12',
          secondLayerMaterial: 'pe oq',
          secondLayerMicron: '30',
          thirdLayerMaterial: '',
          thirdLayerMicron: '',
          note: '',
        ),
      ),
      throwsA(isA<MobileApiException>()),
    );

    final maps = await MobileApi.instance.adminProductionMaps();
    expect(maps.where((item) => item.map.id == 'zakaz-9001'), isEmpty);
  });

  test('sequence save failure does not persist reordered ids on server',
      () async {
    setMobileApiTestModeForceSequenceSaveFailure(true);
    await expectLater(
      MobileApi.instance.adminSaveProductionMapSequence(
        apparatus: '8 ta rangli pechat',
        orderIds: const ['zakaz-seq-b', 'zakaz-seq-a'],
      ),
      throwsA(isA<MobileApiException>()),
    );
    final sequences = await MobileApi.instance.adminProductionMapSequences();
    expect(sequences['8 ta rangli pechat'], isNull);
  });
}

ProductionMapDefinition _productionOrderMap({
  required String id,
  required String title,
  required String productCode,
  required String apparatus,
  required String product,
  String orderNumber = '',
  double? rollCount,
  double? widthMm,
}) {
  return ProductionMapDefinition(
    id: id,
    productCode: productCode,
    title: title,
    orderNumber: orderNumber,
    rollCount: rollCount,
    widthMm: widthMm,
    nodes: [
      const ProductionMapNode(
        id: 'start',
        kind: 'start',
        title: 'Start',
      ),
      ProductionMapNode(
        id: 'apparatus',
        kind: 'apparatus',
        title: apparatus,
      ),
      ProductionMapNode(
        id: 'end',
        kind: 'end',
        title: product,
        itemCode: productCode,
      ),
    ],
    edges: const [
      ProductionMapEdge(from: 'start', to: 'apparatus'),
      ProductionMapEdge(from: 'apparatus', to: 'end'),
    ],
  );
}

ProductionMapDefinition _alternativeProductionOrderMap({
  required String id,
  required String title,
  required String productCode,
  required String product,
  required String orderNumber,
  required double rollCount,
  required double widthMm,
  required String assigned,
  List<String> apparatusTitles = const [
    '7 ta rangli pechat',
    '8 ta rangli pechat',
  ],
}) {
  return ProductionMapDefinition(
    id: id,
    productCode: productCode,
    title: title,
    orderNumber: orderNumber,
    rollCount: rollCount,
    widthMm: widthMm,
    nodes: [
      const ProductionMapNode(
        id: 'start',
        kind: 'start',
        title: 'Start',
      ),
      for (var index = 0; index < apparatusTitles.length; index++)
        ProductionMapNode(
          id: 'apparatus-$index',
          kind: 'apparatus',
          title: apparatusTitles[index],
          alternativeGroupId: 'alt-$id',
          alternativeGroupLabel: 'pechat',
          alternativeAssignedTitle: assigned,
        ),
      ProductionMapNode(
        id: 'end',
        kind: 'end',
        title: product,
        itemCode: productCode,
      ),
    ],
    edges: [
      for (var index = 0; index < apparatusTitles.length; index++) ...[
        ProductionMapEdge(from: 'start', to: 'apparatus-$index'),
        ProductionMapEdge(from: 'apparatus-$index', to: 'end'),
      ],
    ],
  );
}

Future<void> _usePhoneViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
