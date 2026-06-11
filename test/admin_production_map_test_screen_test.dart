import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/api/mobile_api.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/core/test_mode/test_mode_controller.dart';
import 'package:erpnext_stock_mobile/src/features/admin/logic/production_map_pechat_rules.dart';
import 'package:erpnext_stock_mobile/src/features/admin/models/production_map_models.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_production_map_orders_screen.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_production_map_test_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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
  });

  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
  });

  testWidgets('production map page can add and select an apparatus node',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
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
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'Aparat');
    await tester.pumpAndSettle();
    expect(find.text('Aparat tanlang'), findsOneWidget);

    await tester.ensureVisible(find.text('Aparat tanlang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aparat tanlang'));
    await tester.pumpAndSettle();
    expect(find.text('Aparat tanlang'), findsWidgets);

    await tester.tap(find.text('Godex aparat - DEMO').last);
    await tester.pumpAndSettle();

    expect(find.text('Godex aparat - DEMO'), findsWidgets);
  });

  testWidgets('production map opened from zakaz uses linear apparatus flow',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
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
        home: const AdminProductionMapTestScreen(
          orderContext: ProductionMapOrderContext(
            orderName: 'Zenit order',
            productName: 'zenit frutto ninja 70gr',
            itemCode: 'ITEM-001',
            rollCount: 7,
            widthMm: 650,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Zenit order'), findsOneWidget);
    expect(find.text('zenit frutto ninja 70gr'), findsOneWidget);
    expect(find.text('CPP hisob'), findsNothing);
    expect(find.text('Katta partiyami?'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Element qo‘shish'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin-fab-menu-pechat')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('admin-fab-menu-kk li mahsulot')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('admin-fab-menu-Formula')), findsNothing);
    expect(
        find.byKey(const ValueKey('admin-fab-menu-Condition')), findsNothing);
    expect(find.byKey(const ValueKey('admin-fab-menu-Ishlov')), findsOneWidget);
  });

  testWidgets(
      'production map pechat group skip adds alternative apparatus nodes',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
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
        home: const AdminProductionMapTestScreen(
          orderContext: ProductionMapOrderContext(
            orderName: 'Zenit order',
            productName: 'zenit frutto ninja 70gr',
            itemCode: 'ITEM-001',
            rollCount: 7,
            widthMm: 650,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Element qo‘shish'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-fab-menu-pechat')));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('7 ta rangli pechat'), findsOneWidget);
    expect(find.text('8 ta rangli pechat'), findsOneWidget);
    expect(find.text('9 ta rangli pechat'), findsNothing);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('7 ta rangli pechat'), findsOneWidget);
    expect(find.text('8 ta rangli pechat'), findsOneWidget);
  });

  testWidgets('production map can add kk product and pick item',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
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
        home: const AdminProductionMapTestScreen(
          orderContext: ProductionMapOrderContext(
            orderName: 'Zenit order',
            productName: 'zenit frutto ninja 70gr',
            itemCode: 'ITEM-001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'kk li mahsulot');
    await tester.pumpAndSettle();
    expect(find.text('KK li mahsulot tanlang'), findsOneWidget);

    await tester.tap(find.text('KK li mahsulot tanlang'));
    await tester.pumpAndSettle();
    expect(find.text('Mahsulot qidiring'), findsOneWidget);

    await tester.tap(find.text('Hotlunch').last);
    await tester.pumpAndSettle();

    expect(find.text('Hotlunch'), findsWidgets);
    expect(find.text('DEMO-HOTLUNCH'), findsWidgets);
  });

  testWidgets('production map apparatus picker shows only recommended pechat',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
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
        home: const AdminProductionMapTestScreen(
          orderContext: ProductionMapOrderContext(
            orderName: 'Zenit order',
            productName: 'zenit frutto ninja 70gr',
            itemCode: 'ITEM-001',
            rollCount: 8,
            widthMm: 700,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'Aparat');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aparat tanlang'));
    await tester.pumpAndSettle();

    expect(find.text('8 ta rangli pechat'), findsOneWidget);
    expect(find.text('7 ta rangli pechat'), findsNothing);
    expect(find.text('9 ta rangli pechat'), findsNothing);
    expect(find.text('Godex aparat - DEMO'), findsOneWidget);
  });

  test('kk product edges are allowed only with apparatus nodes', () {
    const kk = ProductionMapNode(
      id: 'kk_product_1',
      kind: 'kk_product',
      title: 'Hotlunch',
    );
    const apparatus = ProductionMapNode(
      id: 'apparatus_1',
      kind: 'apparatus',
      title: 'Godex aparat - DEMO',
    );
    const task = ProductionMapNode(
      id: 'task_1',
      kind: 'task',
      title: 'Ishlov jarayoni',
    );
    const start = ProductionMapNode(
      id: 'start',
      kind: 'start',
      title: 'Start',
    );

    expect(productionMapCanCreateEdge(kk, apparatus), isTrue);
    expect(productionMapCanCreateEdge(apparatus, kk), isTrue);
    expect(productionMapCanCreateEdge(kk, task), isFalse);
    expect(productionMapCanCreateEdge(start, kk), isFalse);
    expect(productionMapCanCreateEdge(task, apparatus), isTrue);
  });

  test('production map pechat compatibility summary uses product constraints',
      () {
    expect(
      productionMapPechatCompatibilitySummary(rollCount: 7, widthMm: 650),
      'Minimal 7 ta rangli pechat • Mos: 7 ta rangli pechat, 8 ta rangli pechat',
    );
    expect(
      productionMapPechatCompatibilitySummary(rollCount: 7, widthMm: 1250),
      'Minimal 9 ta rangli pechat • Mos: 9 ta rangli pechat',
    );
  });

  test('production map pechat recommendation prioritizes val then rubber', () {
    expect(
      productionMapRecommendedPechatColorCount(rollCount: 7, widthMm: 700),
      7,
    );
    expect(
      productionMapRecommendedPechatColorCount(rollCount: 7, widthMm: 900),
      8,
    );
    expect(
      productionMapRecommendedPechatColorCount(rollCount: 8, widthMm: 700),
      8,
    );
    expect(
      productionMapRecommendedPechatColorCount(rollCount: 9, widthMm: 700),
      9,
    );
    expect(
      productionMapRecommendedPechatColorCount(rollCount: 6, widthMm: 1200),
      9,
    );
    expect(
      productionMapRecommendedPechatColorCount(rollCount: 10, widthMm: 700),
      isNull,
    );
  });

  test('production map pechat filter allows compatible higher pechat capacity',
      () {
    const context = ProductionMapOrderContext(
      orderName: 'Zenit order',
      productName: 'zenit frutto ninja 70gr',
      itemCode: 'ITEM-001',
      rollCount: 7,
      widthMm: 650,
    );

    expect(
      productionMapApparatusMatchesOrder(
        const AdminWarehouse(
          warehouse: '7 ta rangli pechat',
          parentWarehouse: 'aparat - A',
        ),
        context,
      ),
      isTrue,
    );
    expect(
      productionMapApparatusMatchesOrder(
        const AdminWarehouse(
          warehouse: '8 ta rangli pechat',
          parentWarehouse: 'aparat - A',
        ),
        context,
      ),
      isTrue,
    );
    expect(
      productionMapApparatusMatchesOrder(
        const AdminWarehouse(
          warehouse: '9 ta rangli pechat',
          parentWarehouse: 'aparat - A',
        ),
        context,
      ),
      isFalse,
    );
    expect(
      productionMapApparatusMatchesOrder(
        const AdminWarehouse(
          warehouse: 'Godex aparat - DEMO',
          parentWarehouse: 'aparat - A',
        ),
        context,
      ),
      isTrue,
    );

    const smallRubberContext = ProductionMapOrderContext(
      orderName: 'Small order',
      productName: 'small product',
      itemCode: 'ITEM-002',
      rollCount: 7,
      widthMm: 100,
    );

    expect(
      productionMapApparatusMatchesOrder(
        const AdminWarehouse(
          warehouse: '8 ta rangli pechat',
          parentWarehouse: 'aparat - A',
        ),
        smallRubberContext,
      ),
      isFalse,
    );
  });

  test('production map pechat move blocks missing or incompatible order data',
      () {
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 8,
        rollCount: null,
        widthMm: 900,
      ),
      isTrue,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 8,
        rollCount: 7,
        widthMm: null,
      ),
      isTrue,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 9,
        rollCount: null,
        widthMm: 900,
      ),
      isFalse,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 9,
        rollCount: 7,
        widthMm: null,
      ),
      isFalse,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 9,
        rollCount: 7,
        widthMm: 650,
      ),
      isFalse,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 9,
        rollCount: 9,
        widthMm: 900,
      ),
      isTrue,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 7,
        rollCount: 7,
        widthMm: 1300,
      ),
      isFalse,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 8,
        rollCount: 7,
        widthMm: 1250,
      ),
      isFalse,
    );
    expect(
      productionMapPechatColorCount('9 ta rangli aparat'),
      9,
    );
    expect(
      productionMapPechatColorCount('7 ta rangli'),
      7,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 7,
        rollCount: 7,
        widthMm: null,
        sourceApparatusColorCount: 9,
      ),
      isFalse,
    );
    expect(
      productionMapPechatCanMoveOrder(
        apparatusColorCount: 7,
        rollCount: 7,
        widthMm: 1250,
        sourceApparatusColorCount: 9,
      ),
      isFalse,
    );
  });

  test('production map batch move reassigns alternative assigned apparatus',
      () async {
    await TestModeController.instance.setEnabled(true);
    final map = _alternativeProductionOrderMap(
      id: 'zakaz-alt-move',
      title: 'Alternative move order',
      productCode: 'ALT-MOVE',
      product: 'alternative move product',
      apparatus: const ['7 ta rangli pechat', '8 ta rangli pechat'],
      rollCount: 7,
      widthMm: 650,
    );
    await MobileApi.instance.adminSaveProductionMap(
      map.copyWith(
        nodes: [
          for (final node in map.nodes)
            node.kind == 'apparatus'
                ? node.copyWith(
                    alternativeAssignedTitle: '7 ta rangli pechat',
                  )
                : node,
        ],
      ),
    );

    final moved = await MobileApi.instance.adminMoveProductionMapOrdersBatch(
      mapIds: const ['zakaz-alt-move'],
      fromApparatus: '7 ta rangli pechat',
      toApparatus: '8 ta rangli pechat',
    );

    expect(_apparatusTitles(moved, 'zakaz-alt-move'), [
      '7 ta rangli pechat',
      '8 ta rangli pechat',
    ]);
    expect(_alternativeAssignedTitles(moved, 'zakaz-alt-move'), [
      '8 ta rangli pechat',
      '8 ta rangli pechat',
    ]);
    final maps = await MobileApi.instance.adminProductionMaps();
    expect(_alternativeAssignedTitles(maps, 'zakaz-alt-move'), [
      '8 ta rangli pechat',
      '8 ta rangli pechat',
    ]);
  });

  testWidgets('production map order flow requires four digit order number',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
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
        home: const AdminProductionMapTestScreen(
          orderContext: ProductionMapOrderContext(
            templateId: 'ORDER-1',
            orderName: 'Zenit order',
            productName: 'zenit frutto ninja 70gr',
            itemCode: 'ITEM-001',
            rollCount: 7,
            widthMm: 650,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('production-map-save')));
    await tester.pumpAndSettle();

    expect(find.text('Zakaz raqami'), findsOneWidget);
    expect(find.byKey(const ValueKey('production-map-order-number-field')),
        findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('production-map-order-number-field')),
      '12',
    );
    await tester.tap(find.byKey(const ValueKey('production-map-confirm-save')));
    await tester.pumpAndSettle();

    expect(find.text('4 xonali raqam kiriting'), findsOneWidget);
    expect(find.text('Production map saqlandi'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('production-map-order-number-field')),
      '1234',
    );
    await tester.tap(find.byKey(const ValueKey('production-map-confirm-save')));
    await tester.pumpAndSettle();

    expect(find.text('Production map saqlandi'), findsOneWidget);
    final maps = await MobileApi.instance.adminProductionMaps();
    expect(maps.first.map.orderNumber, '1234');
    expect(maps.first.map.id, 'zakaz-1234');
    expect(maps.first.map.rollCount, 7);
    expect(maps.first.map.widthMm, 650);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('production map order number must be unique per zakaz',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-9876',
        title: 'Old zakaz',
        productCode: 'OLD-ITEM',
        apparatus: 'Paket aparat',
        product: 'old product',
        orderNumber: '9876',
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
        home: const AdminProductionMapTestScreen(
          orderContext: ProductionMapOrderContext(
            templateId: 'ORDER-NEW',
            orderName: 'New zakaz',
            productName: 'new product',
            itemCode: 'NEW-ITEM',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('production-map-save')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('production-map-order-number-field')),
      '9876',
    );
    await tester.tap(find.byKey(const ValueKey('production-map-confirm-save')));
    await tester.pumpAndSettle();

    expect(find.text('Bu raqam boshqa zakazga berilgan'), findsOneWidget);
    expect(find.text('Production map saqlandi'), findsNothing);
    final maps = await MobileApi.instance.adminProductionMaps();
    expect(maps.where((item) => item.map.orderNumber == '9876'), hasLength(1));
    expect(maps.first.map.title, 'Old zakaz');
    // Let the top notice auto-dismiss timer finish.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('opened production map orders page lists saved zakaz',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
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
        home: const AdminProductionMapTestScreen(
          orderContext: ProductionMapOrderContext(
            templateId: 'ORDER-2',
            orderName: 'Zenit opened',
            productName: 'zenit frutto ninja 70gr',
            itemCode: 'ITEM-002',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('production-map-save')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('production-map-order-number-field')),
      '2222',
    );
    await tester.tap(find.byKey(const ValueKey('production-map-confirm-save')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('reja menu'), findsOneWidget);
    expect(find.textContaining('Zenit opened'), findsOneWidget);
    expect(
      find.textContaining('zenit frutto ninja 70gr • ITEM-002'),
      findsOneWidget,
    );
  });

  testWidgets('opened orders sequence module picks apparatus and reorders',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-sequence-a',
        title: 'Paket order A',
        productCode: 'PKT-A',
        apparatus: 'Godex aparat - DEMO',
        product: 'paket mahsulot A',
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-sequence-b',
        title: 'Paket order B',
        productCode: 'PKT-B',
        apparatus: 'Godex aparat - DEMO',
        product: 'paket mahsulot B',
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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zakazlar'), findsOneWidget);
    expect(find.text('Ketma-ketlik'), findsOneWidget);
    expect(find.text('Ko‘chirish'), findsOneWidget);

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    await tester.tap(find.text('Ketma-ketlik'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_rounded), findsNothing);

    expect(find.text('Aparatlar'), findsOneWidget);
    expect(find.text('Godex aparat - DEMO'), findsOneWidget);

    expect(find.textContaining('Paket order A'), findsOneWidget);
    expect(find.textContaining('Paket order B'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle_rounded), findsWidgets);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets('opened orders move module moves only compatible pechat orders',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-move-ok',
        title: 'Move ok order',
        productCode: 'MOVE-OK',
        apparatus: '8 ta rangli pechat',
        product: 'move ok product',
        rollCount: 7,
        widthMm: 650,
        apparatusCopies: 2,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-move-blocked',
        title: 'Move blocked order',
        productCode: 'MOVE-BLOCK',
        apparatus: '8 ta rangli pechat',
        product: 'move blocked product',
        rollCount: 8,
        widthMm: 700,
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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ko‘chirish'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    await tester.tap(find.text('Ko‘chirish'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.textContaining('Move ok order'), findsOneWidget);
    expect(find.textContaining('Move blocked order'), findsNothing);
    await tester
        .tap(find.byKey(const ValueKey('move-boundary-apparatus-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Aparat tanlang'), findsOneWidget);
    expect(find.text('Tanlangan'), findsNothing);
    expect(find.text('Tanlanmagan'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await _dragOrderTitleToTopZone(
      tester,
      orderTitle: 'Move ok order',
      targetText: '7 ta rangli pechat uchun zakaz yo‘q',
    );
    var maps = await MobileApi.instance.adminProductionMaps();
    expect(_apparatusTitle(maps, 'zakaz-move-ok'), '8 ta rangli pechat');
    expect(
      find.text('7 ta rangli pechat uchun zakaz yo‘q'),
      findsOneWidget,
    );

    await _dragOrderHandleToTopZone(
      tester,
      orderTitle: 'Move ok order',
      targetText: '7 ta rangli pechat uchun zakaz yo‘q',
    );
    expect(
      find.text('7 ta rangli pechat uchun zakaz yo‘q'),
      findsNothing,
    );
    expect(find.textContaining('Move ok order'), findsOneWidget);
    maps = await MobileApi.instance.adminProductionMaps();
    expect(_apparatusTitle(maps, 'zakaz-move-ok'), '7 ta rangli pechat');
    expect(
      _apparatusTitles(maps, 'zakaz-move-ok'),
      isNot(contains('8 ta rangli pechat')),
    );
    maps = await MobileApi.instance.adminProductionMaps();
    expect(
      _apparatusTitle(maps, 'zakaz-move-blocked'),
      '8 ta rangli pechat',
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('opened orders move module moves every selected pechat order',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    for (var index = 0; index < 4; index++) {
      await MobileApi.instance.adminSaveProductionMap(
        _productionOrderMap(
          id: 'zakaz-batch-move-$index',
          title: 'Batch move order ${index + 1}',
          productCode: 'BATCH-$index',
          apparatus: '7 ta rangli pechat',
          product: 'batch move product ${index + 1}',
          rollCount: 7,
          widthMm: 650,
        ),
      );
    }
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-batch-move-target',
        title: 'Batch move target order',
        productCode: 'BATCH-TARGET',
        apparatus: '8 ta rangli pechat',
        product: 'batch move target product',
        rollCount: 7,
        widthMm: 650,
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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ko‘chirish'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 4; index++) {
      await _tapMoveOrderBadge(
        tester,
        key: ValueKey(
          'move-order-7 ta rangli pechat-zakaz-batch-move-$index',
        ),
      );
    }

    await _dragOrderHandleToBottomZone(
      tester,
      orderTitle: 'Batch move order 1',
      targetText: 'Batch move target order',
    );

    final maps = await MobileApi.instance.adminProductionMaps();
    for (var index = 0; index < 4; index++) {
      expect(
        _apparatusTitle(maps, 'zakaz-batch-move-$index'),
        '8 ta rangli pechat',
      );
    }
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'opened orders move module blocks 9-color rubber orders on 7-color pechat',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-move-9-only',
        title: 'Nine color rubber order',
        productCode: 'MOVE-9',
        apparatus: '8 ta rangli pechat',
        product: 'nine color product',
        rollCount: 7,
        widthMm: 1250,
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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ko‘chirish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nine color rubber order'), findsNothing);

    final maps = await MobileApi.instance.adminProductionMaps();
    expect(_apparatusTitle(maps, 'zakaz-move-9-only'), '8 ta rangli pechat');
  });

  testWidgets('opened orders move module keeps direct orders out of unassigned',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-direct-pechat',
        title: 'Direct pechat order',
        productCode: 'DIRECT-7',
        apparatus: '7 ta rangli pechat',
        product: 'direct product',
        rollCount: 7,
        widthMm: 650,
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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ko‘chirish'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('move-order-7 ta rangli pechat-zakaz-direct-pechat'),
      ),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey('move-boundary-apparatus-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tanlanmagan'));
    await tester.pumpAndSettle();
    expect(find.text('Tanlanmagan zakaz yo‘q'), findsOneWidget);

    await _dragOrderHandleToBottomZone(
      tester,
      orderTitle: 'Direct pechat order',
      targetText: 'Tanlanmagan zakaz yo‘q',
    );

    expect(
      find.byKey(
        const ValueKey('move-order-7 ta rangli pechat-zakaz-direct-pechat'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('move-order-Tanlanmagan-zakaz-direct-pechat'),
      ),
      findsNothing,
    );
    final maps = await MobileApi.instance.adminProductionMaps();
    expect(_apparatusTitles(maps, 'zakaz-direct-pechat'), [
      '7 ta rangli pechat',
    ]);
  });

  testWidgets('opened orders move module boundary resizes zones',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-resize-a',
        title: 'Resize top order',
        productCode: 'RESIZE-A',
        apparatus: '7 ta rangli pechat',
        product: 'resize product a',
        rollCount: 7,
        widthMm: 650,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-resize-b',
        title: 'Resize bottom order',
        productCode: 'RESIZE-B',
        apparatus: '8 ta rangli pechat',
        product: 'resize product b',
        rollCount: 7,
        widthMm: 650,
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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ko‘chirish'));
    await tester.pumpAndSettle();
    final boundary =
        find.byKey(const ValueKey('move-boundary-apparatus-picker'));
    final before = tester.getTopLeft(boundary).dy;
    final gesture = await tester.startGesture(tester.getCenter(boundary));
    await gesture.moveBy(const Offset(0, 160));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(boundary).dy, greaterThan(before + 40));
  });

  testWidgets(
      'opened orders picker unassigned card shows skipped alternatives in move zone',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-skip-7-8',
        title: 'Skipped pechat order',
        productCode: 'SKIP-78',
        product: 'skipped product',
        apparatus: const ['7 ta rangli pechat', '8 ta rangli pechat'],
        rollCount: 7,
        widthMm: 650,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _alternativeProductionOrderMap(
        id: 'zakaz-skip-9',
        title: 'Skipped nine order',
        productCode: 'SKIP-9',
        product: 'skipped nine product',
        apparatus: const ['9 ta rangli pechat'],
        rollCount: 9,
        widthMm: 900,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-skip-target-7',
        title: 'Skip target seven order',
        productCode: 'SKIP-TARGET-7',
        apparatus: '7 ta rangli pechat',
        product: 'skip target seven product',
        rollCount: 7,
        widthMm: 650,
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-skip-target-8',
        title: 'Skip target eight order',
        productCode: 'SKIP-TARGET-8',
        apparatus: '8 ta rangli pechat',
        product: 'skip target product',
        rollCount: 7,
        widthMm: 650,
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
        home: const AdminProductionMapOrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ko‘chirish'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('move-boundary-apparatus-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Tanlangan'), findsNothing);
    expect(find.text('Tanlanmagan'), findsOneWidget);
    await tester.tap(find.text('Tanlanmagan'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('move-order-Tanlanmagan-zakaz-skip-7-8'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('move-order-Tanlanmagan-zakaz-skip-9'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('move-order-7 ta rangli pechat-zakaz-skip-7-8'),
      ),
      findsNothing,
    );

    await _dragOrderHandleToTopZone(
      tester,
      orderTitle: 'Skipped pechat order',
      targetText: 'Skip target seven order',
    );

    expect(
      find.byKey(
        const ValueKey('move-order-Tanlanmagan-zakaz-skip-7-8'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('move-order-7 ta rangli pechat-zakaz-skip-7-8'),
      ),
      findsOneWidget,
    );
    final maps = await MobileApi.instance.adminProductionMaps();
    expect(_apparatusTitles(maps, 'zakaz-skip-7-8'), [
      '7 ta rangli pechat',
      '8 ta rangli pechat',
    ]);
    expect(_alternativeGroupIds(maps, 'zakaz-skip-7-8'), isNotEmpty);
    expect(_alternativeAssignedTitles(maps, 'zakaz-skip-7-8'), [
      '7 ta rangli pechat',
      '7 ta rangli pechat',
    ]);

    await _dragOrderHandleToBottomZone(
      tester,
      orderTitle: 'Skipped pechat order',
      targetText: 'Tanlanmagan zakaz yo‘q',
    );

    expect(
      find.byKey(
        const ValueKey('move-order-Tanlanmagan-zakaz-skip-7-8'),
      ),
      findsOneWidget,
    );
    final returnedMaps = await MobileApi.instance.adminProductionMaps();
    expect(_apparatusTitles(returnedMaps, 'zakaz-skip-7-8'), [
      '7 ta rangli pechat',
      '8 ta rangli pechat',
    ]);
    expect(_alternativeGroupIds(returnedMaps, 'zakaz-skip-7-8'), isNotEmpty);
    expect(_alternativeAssignedTitles(returnedMaps, 'zakaz-skip-7-8'), isEmpty);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('move-top-apparatus-picker')),
        matching: find.textContaining('7 ta rangli pechat'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('8 ta rangli pechat').first);
    await tester.pumpAndSettle();

    await _dragOrderHandleToTopZone(
      tester,
      orderTitle: 'Skipped pechat order',
      targetText: 'Skip target eight order',
    );

    expect(
      find.byKey(
        const ValueKey('move-order-8 ta rangli pechat-zakaz-skip-7-8'),
      ),
      findsOneWidget,
    );
    final assignedToEightMaps = await MobileApi.instance.adminProductionMaps();
    expect(
      _alternativeAssignedTitles(assignedToEightMaps, 'zakaz-skip-7-8'),
      ['8 ta rangli pechat', '8 ta rangli pechat'],
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('apparatus queue worker view is read only', (tester) async {
    await TestModeController.instance.setEnabled(true);
    await AppSession.instance.setSession(
      token: 'worker-token',
      profile: const SessionProfile(
        role: UserRole.werka,
        displayName: 'Aparatchi',
        legalName: '',
        ref: 'werka',
        phone: '',
        avatarUrl: '',
        capabilities: ['apparatus.queue.read', 'apparatus.queue.manage'],
        assignedApparatus: ['7 ta rangli pechat'],
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-worker-queue',
        title: 'Worker queue order',
        productCode: 'WRK-A',
        apparatus: '7 ta rangli pechat',
        product: 'worker mahsulot',
      ),
    );
    await MobileApi.instance.adminSaveProductionMap(
      _productionOrderMap(
        id: 'zakaz-worker-queue-2',
        title: 'Worker queue order 2',
        productCode: 'WRK-B',
        apparatus: '7 ta rangli pechat',
        product: 'worker mahsulot 2',
      ),
    );
    await MobileApi.instance.adminSaveProductionMapSequence(
      apparatus: '7 ta rangli pechat',
      orderIds: const ['zakaz-worker-queue', 'zakaz-worker-queue-2'],
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
        home: const AdminProductionMapOrdersScreen(
          readOnly: true,
          workerMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zakazlar'), findsNothing);
    expect(find.text('Kuzatish'), findsOneWidget);
    expect(find.text('Godex aparat - DEMO'), findsOneWidget);
    expect(find.text('7 ta rangli pechat'), findsOneWidget);
    expect(find.text('Aparatlar'), findsNothing);
    expect(find.textContaining('Worker queue order'), findsNWidgets(2));
    expect(find.byIcon(Icons.drag_handle_rounded), findsNothing);
    expect(find.text('Sizning aparatingiz'), findsOneWidget);
    expect(find.text('Boshlash'), findsNothing);

    await tester.tap(find.text('7 ta rangli pechat'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('worker-queue').first);
    await tester.pumpAndSettle();

    expect(find.text('Boshlash'), findsOneWidget);
    expect(find.text('Tugatish'), findsNothing);

    await tester.tap(find.text('Boshlash'));
    await tester.pumpAndSettle();

    expect(find.text('Tugatish'), findsOneWidget);
    expect(find.text('Boshlash'), findsNothing);

    await tester.tap(find.text('Tugatish'));
    await tester.pumpAndSettle();

    expect(find.text('Tugatish'), findsNothing);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('Boshlash'), findsNothing);
  });

  testWidgets('production map sheet closes when tapping the dimmed barrier',
      (tester) async {
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
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Katta partiyami?'));
    await tester.pumpAndSettle();

    expect(find.text('Node sozlash'), findsOneWidget);

    await tester.tapAt(const Offset(200, 90));
    await tester.pumpAndSettle();

    expect(find.text('Node sozlash'), findsNothing);
  });

  testWidgets('production map page shows default condition flow',
      (tester) async {
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
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Katta partiyami?'), findsOneWidget);
    expect(find.text('Katta partiya'), findsNothing);
    expect(find.text('Rezkaga yuborish'), findsNothing);
    expect(
      find.byKey(const ValueKey('production-map-branch-add-true')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('production-map-branch-add-false')),
      findsWidgets,
    );
  });

  testWidgets('production map formula field shows human variable editor',
      (tester) async {
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
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CPP hisob'));
    await tester.pumpAndSettle();

    expect(find.text('Node sozlash'), findsOneWidget);
    expect(find.text('Buyurtma miqdori * 1.08'), findsOneWidget);
    expect(find.text('order_qty * 1.08'), findsNothing);

    await tester.tap(find.text('Buyurtma miqdori * 1.08'));
    await tester.pumpAndSettle();

    expect(find.text('Formula yozish'), findsOneWidget);
    expect(find.text('Buyurtma miqdori'), findsWidgets);

    await tester.enterText(find.byType(TextField).last, 'buyu');
    await tester.pump();
    final formulaField = tester.widget<TextField>(find.byType(TextField).last);
    final formulaSpan = formulaField.controller!.buildTextSpan(
      context: tester.element(find.byType(TextField).last),
      style: const TextStyle(),
      withComposing: false,
    );
    expect(formulaSpan.toPlainText(), 'buyurtma miqdori');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Formula yozish'), findsOneWidget);
    expect(formulaField.focusNode?.hasFocus, isTrue);
    expect(formulaField.controller!.text, 'Buyurtma miqdori ');

    await tester.tap(find.text('Saqlash').last);
    await tester.pumpAndSettle();

    expect(find.text('Buyurtma miqdori'), findsWidgets);
  });

  testWidgets('production map edge delete button removes an outgoing edge',
      (tester) async {
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
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'Ishlov');
    await tester.pumpAndSettle();

    final deleteButton = find.byKey(
      const ValueKey('production-map-edge-delete-task_1-end-'),
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(deleteButton, findsNothing);
  });

  testWidgets('production map branch adds condition with open branch handles',
      (tester) async {
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
        home: const AdminProductionMapTestScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapMapTool(tester, 'Condition');
    await tester.pumpAndSettle();

    expect(find.text('Shart'), findsOneWidget);
    expect(find.text('Shunda yo‘liga qo‘shish'), findsNothing);
    expect(find.text('Bajariladigan ish'), findsNothing);
    expect(find.text('Boshqa holatdagi ish'), findsNothing);
    expect(
      find.byKey(const ValueKey('production-map-branch-add-true')),
      findsWidgets,
    );
    expect(
      find.byKey(const ValueKey('production-map-branch-add-false')),
      findsWidgets,
    );
  });
}

ProductionMapDefinition _alternativeProductionOrderMap({
  required String id,
  required String title,
  required String productCode,
  required String product,
  required List<String> apparatus,
  double? rollCount,
  double? widthMm,
}) {
  final apparatusNodes = [
    for (var index = 0; index < apparatus.length; index++)
      ProductionMapNode(
        id: 'apparatus-$index',
        kind: 'apparatus',
        title: apparatus[index],
        alternativeGroupId: 'alt-$id',
        alternativeGroupLabel: 'pechat',
      ),
  ];
  return ProductionMapDefinition(
    id: id,
    productCode: productCode,
    title: title,
    rollCount: rollCount,
    widthMm: widthMm,
    nodes: [
      const ProductionMapNode(
        id: 'start',
        kind: 'start',
        title: 'Start',
      ),
      ...apparatusNodes,
      ProductionMapNode(
        id: 'end',
        kind: 'end',
        title: product,
        itemCode: productCode,
      ),
    ],
    edges: [
      for (final node in apparatusNodes) ...[
        ProductionMapEdge(from: 'start', to: node.id),
        ProductionMapEdge(from: node.id, to: 'end'),
      ],
    ],
  );
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
  int apparatusCopies = 1,
}) {
  final apparatusNodes = [
    for (var index = 0; index < apparatusCopies; index++)
      ProductionMapNode(
        id: index == 0 ? 'apparatus' : 'apparatus-$index',
        kind: 'apparatus',
        title: apparatus,
      ),
  ];
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
      ...apparatusNodes,
      ProductionMapNode(
        id: 'end',
        kind: 'end',
        title: product,
        itemCode: productCode,
      ),
    ],
    edges: [
      ProductionMapEdge(from: 'start', to: apparatusNodes.first.id),
      for (var index = 0; index < apparatusNodes.length - 1; index++)
        ProductionMapEdge(
          from: apparatusNodes[index].id,
          to: apparatusNodes[index + 1].id,
        ),
      ProductionMapEdge(from: apparatusNodes.last.id, to: 'end'),
    ],
  );
}

Future<void> _usePhoneViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapMapTool(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel('Element qo‘shish'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('admin-fab-menu-$label')));
}

Future<void> _dragOrderTitleToTopZone(
  WidgetTester tester, {
  required String orderTitle,
  required String targetText,
}) async {
  final order = find.textContaining(orderTitle);
  await tester.ensureVisible(order);
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(tester.getCenter(order));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 120));
  await gesture.moveTo(tester.getCenter(find.textContaining(targetText).first));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _tapMoveOrderBadge(
  WidgetTester tester, {
  required ValueKey<String> key,
}) async {
  final order = find.byKey(key);
  await tester.ensureVisible(order);
  await tester.pumpAndSettle();
  final topLeft = tester.getTopLeft(order);
  final height = tester.getSize(order).height;
  await tester.tapAt(topLeft + Offset(28, height / 2));
  await tester.pumpAndSettle();
}

Future<void> _dragOrderHandleToTopZone(
  WidgetTester tester, {
  required String orderTitle,
  required String targetText,
}) async {
  final order = find.textContaining(orderTitle);
  await tester.ensureVisible(order);
  await tester.pumpAndSettle();
  final orderCenter = tester.getCenter(order);
  final handles = tester
      .widgetList<Icon>(find.byIcon(Icons.drag_handle_rounded))
      .toList(growable: false);
  final handleFinders = [
    for (var index = 0; index < handles.length; index++)
      find.byIcon(Icons.drag_handle_rounded).at(index),
  ];
  Finder? matchingHandle;
  var minDistance = double.infinity;
  for (final handle in handleFinders) {
    final center = tester.getCenter(handle);
    final distance = (center.dy - orderCenter.dy).abs();
    if (distance < minDistance) {
      minDistance = distance;
      matchingHandle = handle;
    }
  }
  final gesture = await tester.startGesture(tester.getCenter(matchingHandle!));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 120));
  await gesture.moveTo(tester.getCenter(find.textContaining(targetText).first));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

Future<void> _dragOrderHandleToBottomZone(
  WidgetTester tester, {
  required String orderTitle,
  required String targetText,
}) async {
  await _dragOrderHandleToZone(
    tester,
    orderTitle: orderTitle,
    targetText: targetText,
  );
}

Future<void> _dragOrderHandleToZone(
  WidgetTester tester, {
  required String orderTitle,
  required String targetText,
}) async {
  final order = find.textContaining(orderTitle);
  await tester.ensureVisible(order);
  await tester.pumpAndSettle();
  final orderCenter = tester.getCenter(order);
  final handles = tester
      .widgetList<Icon>(find.byIcon(Icons.drag_handle_rounded))
      .toList(growable: false);
  final handleFinders = [
    for (var index = 0; index < handles.length; index++)
      find.byIcon(Icons.drag_handle_rounded).at(index),
  ];
  Finder? matchingHandle;
  var minDistance = double.infinity;
  for (final handle in handleFinders) {
    final center = tester.getCenter(handle);
    final distance = (center.dy - orderCenter.dy).abs();
    if (distance < minDistance) {
      minDistance = distance;
      matchingHandle = handle;
    }
  }
  final gesture = await tester.startGesture(tester.getCenter(matchingHandle!));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 120));
  await gesture.moveTo(tester.getCenter(find.textContaining(targetText).first));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

String _apparatusTitle(List<ProductionMapSaved> maps, String id) {
  final map = maps.singleWhere((item) => item.map.id == id).map;
  return map.nodes.firstWhere((node) => node.kind == 'apparatus').title.trim();
}

List<String> _apparatusTitles(List<ProductionMapSaved> maps, String id) {
  final map = maps.singleWhere((item) => item.map.id == id).map;
  return map.nodes
      .where((node) => node.kind == 'apparatus')
      .map((node) => node.title.trim())
      .toList(growable: false);
}

List<String> _alternativeGroupIds(List<ProductionMapSaved> maps, String id) {
  final map = maps.singleWhere((item) => item.map.id == id).map;
  return map.nodes
      .where((node) => node.kind == 'apparatus')
      .map((node) => node.alternativeGroupId.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

List<String> _alternativeAssignedTitles(
  List<ProductionMapSaved> maps,
  String id,
) {
  final map = maps.singleWhere((item) => item.map.id == id).map;
  return map.nodes
      .where((node) => node.kind == 'apparatus')
      .map((node) => node.alternativeAssignedTitle.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}
