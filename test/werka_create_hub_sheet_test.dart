import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';
import 'package:erpnext_stock_mobile/src/features/werka/presentation/widgets/werka_create_hub_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(
  Widget child, {
  List<NavigatorObserver> navigatorObservers = const [],
}) {
  return MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    onGenerateRoute: (settings) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => Scaffold(
          body: Center(
            child: Text(settings.name ?? 'root'),
          ),
        ),
      );
    },
    navigatorObservers: navigatorObservers,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('Werka create hub starts as a medium expressive FAB',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showWerkaCreateHubSheet(context);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final toggleFinder = find.byKey(const ValueKey('werka-hub-toggle-button'));
    expect(toggleFinder, findsOneWidget);
    expect(tester.getSize(toggleFinder).width, greaterThan(56));
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('Werka create hub keeps the original 3-card stack',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showWerkaCreateHubSheet(context);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final bottom = find.byKey(const ValueKey('werka-hub-batch-dispatch'));
    final middle = find.byKey(const ValueKey('werka-hub-customer-issue'));
    final top = find.byKey(const ValueKey('werka-hub-unannounced'));

    expect(bottom, findsOneWidget);
    expect(middle, findsOneWidget);
    expect(top, findsOneWidget);

    final toggleSize =
        tester.getSize(find.byKey(const ValueKey('werka-hub-toggle-button')));
    expect(toggleSize.width, closeTo(56, 1.5));
    expect(toggleSize.height, closeTo(56, 1.5));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    final bottomWidth = tester.getSize(bottom).width;
    final middleWidth = tester.getSize(middle).width;
    final topWidth = tester.getSize(top).width;
    expect(bottomWidth, isNot(equals(middleWidth)));
    expect(topWidth, isNot(equals(bottomWidth)));

    final bottomCenter = tester.getCenter(bottom);
    final middleCenter = tester.getCenter(middle);
    final topCenter = tester.getCenter(top);
    expect(
      bottomCenter.dy - middleCenter.dy,
      inInclusiveRange(60.0, 68.0),
    );
    expect(
      middleCenter.dy - topCenter.dy,
      inInclusiveRange(60.0, 68.0),
    );

    final bottomRect = tester.getRect(bottom);
    final toggleRect =
        tester.getRect(find.byKey(const ValueKey('werka-hub-toggle-button')));
    expect(
      toggleRect.top - bottomRect.bottom,
      inInclusiveRange(8.0, 14.0),
    );
  });

  testWidgets('Werka create hub toggle can reverse while opening',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showWerkaCreateHubSheet(context);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final toggleFinder = find.byKey(const ValueKey('werka-hub-toggle-button'));
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    expect(toggleFinder, findsNothing);
    expect(
      find.byKey(const ValueKey('werka-hub-batch-dispatch')),
      findsNothing,
    );
  });

  testWidgets('Werka create hub cards are full-surface tappable',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showWerkaCreateHubSheet(context);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final cardFinder = find.byKey(const ValueKey('werka-hub-batch-dispatch'));
    expect(
      find.descendant(of: cardFinder, matching: find.byType(InkWell)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cardFinder, matching: find.byType(Material)),
      findsWidgets,
    );
  });

  testWidgets('Werka create hub reveals cards from right to left',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showWerkaCreateHubSheet(context);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final revealFinder = find.byKey(const ValueKey('werka-hub-reveal-0'));
    final revealEarly = tester.getSize(revealFinder);
    final titleFinder = find.text('Aytilmagan mahsulot');
    final titleEarly = tester.getTopLeft(titleFinder);

    await tester.pumpAndSettle();

    final revealLate = tester.getSize(revealFinder);
    final titleLate = tester.getTopLeft(titleFinder);

    expect(revealEarly.width, lessThan(revealLate.width));
    expect(titleEarly.dx, closeTo(titleLate.dx, 0.01));
  });

  testWidgets('Werka create hub toggle can reopen while closing',
      (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
            capturedContext = context;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showWerkaCreateHubSheet(context);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final toggleFinder = find.byKey(const ValueKey('werka-hub-toggle-button'));
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    await tester.pump(const Duration(milliseconds: 40));
    showWerkaCreateHubSheet(capturedContext);
    await tester.pumpAndSettle();

    expect(toggleFinder, findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(
        find.byKey(const ValueKey('werka-hub-batch-dispatch')), findsOneWidget);
  });
}
