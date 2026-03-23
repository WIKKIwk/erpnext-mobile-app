import 'dart:async';

import 'package:erpnext_stock_mobile/src/app/app_router.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:erpnext_stock_mobile/src/features/supplier/presentation/supplier_confirm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('supplier confirm ignores repeated taps while submitting',
      (tester) async {
    final completer = Completer<DispatchRecord>();
    var submitCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.supplierSuccess: (_) => const Scaffold(
                body: SizedBox.shrink(),
              ),
        },
        home: SupplierConfirmScreen(
          args: const SupplierConfirmArgs(
            item: SupplierItem(
              code: 'ITEM-001',
              name: 'Rice',
              uom: 'Kg',
              warehouse: 'Stores - A',
            ),
            qty: 12,
          ),
          submitDispatch: (_) {
            submitCalls += 1;
            return completer.future;
          },
        ),
      ),
    );

    final submitButton = find.text('Ha, jo‘natishni saqlash');
    expect(submitButton, findsOneWidget);

    await tester.tap(submitButton);
    await tester.pump();

    expect(submitCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitCalls, 1);

    completer.complete(
      const DispatchRecord(
        id: 'MAT-PRE-0001',
        supplierRef: 'SUP-001',
        supplierName: 'Supplier',
        itemCode: 'ITEM-001',
        itemName: 'Rice',
        uom: 'Kg',
        sentQty: 12,
        acceptedQty: 0,
        amount: 0,
        currency: '',
        note: '',
        eventType: '',
        highlight: '',
        status: DispatchStatus.pending,
        createdLabel: '2026-03-23T08:40:41Z',
      ),
    );
    await tester.pumpAndSettle();

    expect(submitCalls, 1);
  });
}
