import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_daily_calendar_screen.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_monthly_calendar_screen.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_sent_hub_screen.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_yearly_calendar_screen.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_screen.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_list_screen.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/werka_archive_period_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    onGenerateRoute: AppRouter.onGenerateRoute,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('monthly archive list screen builds without exception',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WerkaArchiveListScreen(
          args: WerkaArchiveListArgs(
            kind: WerkaArchiveKind.sent,
            period: WerkaArchivePeriod.monthly,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('period screen opens monthly calendar without exception',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WerkaArchivePeriodScreen(kind: WerkaArchiveKind.sent),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Oylik'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.takeException(), isNull);
    expect(find.byType(WerkaArchiveMonthlyCalendarScreen), findsOneWidget);
  });

  testWidgets('archive screen opens sent archive hub without exception',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WerkaArchiveScreen(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Jo\'natilgan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(WerkaArchiveSentHubScreen), findsOneWidget);
  });

  testWidgets('period screen opens daily calendar without exception',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WerkaArchivePeriodScreen(kind: WerkaArchiveKind.sent),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Kunlik'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.takeException(), isNull);
    expect(find.byType(WerkaArchiveDailyCalendarScreen), findsOneWidget);
  });

  testWidgets('period screen opens yearly calendar without exception',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const WerkaArchivePeriodScreen(kind: WerkaArchiveKind.sent),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Yillik'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(tester.takeException(), isNull);
    expect(find.byType(WerkaArchiveYearlyCalendarScreen), findsOneWidget);
  });

  testWidgets('daily calendar opens list when active day is tapped',
      (tester) async {
    Future<WerkaArchiveResponse> archiveLoader({
      required WerkaArchiveKind kind,
      required WerkaArchivePeriod period,
      DateTime? from,
      DateTime? to,
    }) async {
      return WerkaArchiveResponse(
        kind: kind,
        period: period,
        from: from,
        to: to,
        summary: const WerkaArchiveSummary(
          recordCount: 1,
          totalsByUOM: [
            ArchiveTotalByUOM(uom: 'Kg', qty: 3),
          ],
        ),
        items: const [
          DispatchRecord(
            id: 'MAT-DN-TEST',
            supplierRef: 'CUS-001',
            supplierName: 'Customer One',
            itemCode: 'ITEM-001',
            itemName: 'Rice',
            uom: 'Kg',
            sentQty: 3,
            acceptedQty: 0,
            amount: 0,
            currency: '',
            note: '',
            eventType: '',
            highlight: '',
            status: DispatchStatus.pending,
            createdLabel: '2026-04-03 10:00:00',
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _wrap(
        WerkaArchiveDailyCalendarScreen(
          kind: WerkaArchiveKind.sent,
          archiveLoader: archiveLoader,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(WerkaArchiveListScreen), findsOneWidget);
  });

  testWidgets('monthly calendar opens list when month is tapped',
      (tester) async {
    Future<WerkaArchiveResponse> archiveLoader({
      required WerkaArchiveKind kind,
      required WerkaArchivePeriod period,
      DateTime? from,
      DateTime? to,
    }) async {
      return WerkaArchiveResponse(
        kind: kind,
        period: period,
        from: from,
        to: to,
        summary: const WerkaArchiveSummary(
          recordCount: 1,
          totalsByUOM: [
            ArchiveTotalByUOM(uom: 'Kg', qty: 3),
          ],
        ),
        items: const [
          DispatchRecord(
            id: 'MAT-DN-TEST',
            supplierRef: 'CUS-001',
            supplierName: 'Customer One',
            itemCode: 'ITEM-001',
            itemName: 'Rice',
            uom: 'Kg',
            sentQty: 3,
            acceptedQty: 0,
            amount: 0,
            currency: '',
            note: '',
            eventType: '',
            highlight: '',
            status: DispatchStatus.pending,
            createdLabel: '2026-04-03 10:00:00',
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _wrap(
        WerkaArchiveMonthlyCalendarScreen(
          kind: WerkaArchiveKind.sent,
          archiveLoader: archiveLoader,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('archive_month_4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(WerkaArchiveListScreen), findsOneWidget);
  });

  testWidgets('yearly calendar opens list when year is tapped', (tester) async {
    Future<WerkaArchiveResponse> archiveLoader({
      required WerkaArchiveKind kind,
      required WerkaArchivePeriod period,
      DateTime? from,
      DateTime? to,
    }) async {
      return WerkaArchiveResponse(
        kind: kind,
        period: period,
        from: from,
        to: to,
        summary: const WerkaArchiveSummary(
          recordCount: 1,
          totalsByUOM: [
            ArchiveTotalByUOM(uom: 'Kg', qty: 3),
          ],
        ),
        items: const [
          DispatchRecord(
            id: 'MAT-DN-TEST',
            supplierRef: 'CUS-001',
            supplierName: 'Customer One',
            itemCode: 'ITEM-001',
            itemName: 'Rice',
            uom: 'Kg',
            sentQty: 3,
            acceptedQty: 0,
            amount: 0,
            currency: '',
            note: '',
            eventType: '',
            highlight: '',
            status: DispatchStatus.pending,
            createdLabel: '2026-04-03 10:00:00',
          ),
        ],
      );
    }

    await tester.pumpWidget(
      _wrap(
        WerkaArchiveYearlyCalendarScreen(
          kind: WerkaArchiveKind.sent,
          archiveLoader: archiveLoader,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('archive_year_2026')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.takeException(), isNull);
    expect(find.byType(WerkaArchiveListScreen), findsOneWidget);
  });
}
