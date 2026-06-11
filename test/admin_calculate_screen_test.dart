import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/api/mobile_api.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/core/test_mode/test_mode_controller.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_calculate_screen.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_production_map_test_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
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

  testWidgets('zakaz create page shows production map link after calculation',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await _pumpCalculateScreen(tester, template: _template(itemCode: 'ITEM-1'));

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Production mapga ulash'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '100');
    await tester.tap(find.text('Hisoblash'));
    await tester.pumpAndSettle();

    expect(find.text('Production mapga ulash'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '120');
    await tester.pumpAndSettle();

    expect(find.text('Production mapga ulash'), findsNothing);
  });

  testWidgets('product picker asks before recreating existing quick order',
      (tester) async {
    await TestModeController.instance.setEnabled(true);
    await MobileApi.instance.upsertCalculateOrderTemplate(
      _template(itemCode: 'DEMO-HOTLUNCH'),
    );
    await _pumpCalculateScreen(tester);

    await tester.tap(find.text('Mahsulot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hotlunch').last);
    await tester.pumpAndSettle();

    expect(find.text('Bu tezkor zakazlar ro‘yxatida bor'), findsOneWidget);
    expect(find.text('Qaytadan yaratmoqchimisiz?'), findsOneWidget);

    await tester.tap(find.text('Yo‘q'));
    await tester.pumpAndSettle();
    expect(find.text('Hotlunch'), findsNothing);

    await tester.tap(find.text('Mahsulot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hotlunch').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ha'));
    await tester.pumpAndSettle();

    expect(find.text('Hotlunch'), findsWidgets);
  });
}

Future<void> _pumpCalculateScreen(
  WidgetTester tester, {
  CalculateOrderTemplate? template,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
      home: AdminCalculateScreen(template: template),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.adminProductionMapTest &&
            settings.arguments is ProductionMapOrderContext) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('MAP OPENED')),
          );
        }
        return null;
      },
    ),
  );
  await tester.pumpAndSettle();
}

CalculateOrderTemplate _template({required String itemCode}) {
  return CalculateOrderTemplate(
    id: 'template-1',
    code: 'Z-1234',
    name: 'Zenit order',
    savedAt: DateTime.utc(2026, 6, 11),
    orderNumber: '',
    customerRef: 'CUST-001',
    customer: 'Mijoz',
    itemCode: itemCode,
    product: 'zenit frutto ninja 70 gr',
    status: 'Ready',
    materialDisplay: '',
    color: '',
    imageId: '',
    imageName: '',
    imageMime: '',
    imageSizeBytes: 0,
    imageUrl: '',
    widthMm: 630,
    wastePercent: 5,
    rollCount: 7,
    firstLayerMaterial: 'pet',
    firstLayerMicron: '12',
    secondLayerMaterial: 'pe oq',
    secondLayerMicron: '30',
    thirdLayerMaterial: '',
    thirdLayerMicron: '',
    note: '',
  );
}
