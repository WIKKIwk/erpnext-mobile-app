import 'dart:io';

import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/core/theme/app_theme.dart';
import 'package:erpnext_stock_mobile/src/core/theme/theme_controller.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_home_screen.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/widgets/admin_navigation_drawer.dart';
import 'package:erpnext_stock_mobile/src/features/shared/presentation/profile_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
  });

  testWidgets('custom catalog role opens admin home without summary request',
      (tester) async {
    final seenRequests = <String>[];
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.customer,
      displayName: 'Custom operator',
      legalName: '',
      ref: 'custom',
      phone: '',
      avatarUrl: '',
      capabilities: [
        'catalog.item.read',
        'catalog.item.create',
        'gscale.print',
        'rps.batch.manage',
      ],
    );

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppThemeVariant.earthy),
          locale: const Locale('uz'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item qo‘shish'), findsOneWidget);
      expect(find.text('GScale'), findsOneWidget);
      expect(find.text('Uy'), findsOneWidget);
      expect(find.text('Foydalanuvchilar'), findsNothing);
      expect(find.text('Faoliyat'), findsNothing);
      expect(find.text('Jami users'), findsNothing);
      expect(seenRequests, isEmpty);
    }, createHttpClient: (_) => _RecordingHttpClient(seenRequests));
  });

  testWidgets('custom catalog role drawer hides blocked admin routes',
      (tester) async {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.customer,
      displayName: 'Custom operator',
      legalName: '',
      ref: 'custom',
      phone: '',
      avatarUrl: '',
      capabilities: [
        'catalog.item.read',
        'catalog.item.create',
        'gscale.print',
        'rps.batch.manage',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppThemeVariant.earthy),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdminNavigationDrawer(
            selectedIndex: 0,
            onNavigate: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Uy'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('GScale Mode'), findsOneWidget);
    expect(find.text('Foydalanuvchilar'), findsNothing);
    expect(find.text('Harakatlar'), findsNothing);
    expect(find.text('Rollar'), findsNothing);
  });

  testWidgets('admin drawer shows apparatus groups route', (tester) async {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.admin,
      displayName: 'Admin',
      legalName: '',
      ref: 'admin',
      phone: '',
      avatarUrl: '',
      capabilities: ['admin.access', 'production.map.manage'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppThemeVariant.earthy),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdminNavigationDrawer(
            selectedIndex: 0,
            onNavigate: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('reja menu'), findsOneWidget);
    expect(find.text('Aparat guruhlari'), findsOneWidget);
  });

  testWidgets('custom catalog profile home returns to capability home route',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.customer,
      displayName: 'Custom operator',
      legalName: '',
      ref: 'custom',
      phone: '',
      avatarUrl: '',
      capabilities: [
        'catalog.item.read',
        'catalog.item.create',
        'gscale.print',
        'rps.batch.manage',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppThemeVariant.earthy),
        locale: const Locale('uz'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const ProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bildirish'), findsNothing);

    await tester.tap(find.text('Uy').last);
    await tester.pumpAndSettle();

    expect(find.text('Ruxsat yo‘q'), findsNothing);
    expect(find.text('Item qo‘shish'), findsOneWidget);
  });
}

class _RecordingHttpClient extends Fake implements HttpClient {
  _RecordingHttpClient(this.seenRequests);

  final List<String> seenRequests;

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    seenRequests.add('GET ${url.path}');
    throw UnsupportedError('unexpected HTTP request: $url');
  }
}
