import 'package:erpnext_stock_mobile/src/core/widgets/shell/app_shell.dart';
import 'package:erpnext_stock_mobile/src/core/widgets/display/shared_header_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppShell native top bar mode uses AppBar only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: AppShell(
          title: 'Werka',
          subtitle: '',
          nativeTopBar: true,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(SharedHeaderTitle), findsNothing);
    expect(find.text('Werka'), findsOneWidget);
  });
}
