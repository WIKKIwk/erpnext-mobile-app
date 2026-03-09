import 'package:flutter_test/flutter_test.dart';
import 'package:erpnext_stock_mobile/src/app/app.dart';

void main() {
  testWidgets('login screen renders phone and code fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ErpnextStockMobileApp());

    expect(find.text('Telefon raqam'), findsOneWidget);
    expect(find.text('Code'), findsOneWidget);
  });
}
