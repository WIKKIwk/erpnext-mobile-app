import 'package:erpnext_stock_mobile/src/core/notifications/store/werka_runtime_store.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    WerkaRuntimeStore.instance.clear();
  });

  test('reconcile removes reflected pending mutation from summary', () {
    const pendingRecord = DispatchRecord(
      id: 'MAT-DN-0001',
      supplierRef: 'CUS-001',
      supplierName: 'Customer',
      itemCode: 'ITEM-001',
      itemName: 'Rice',
      uom: 'Kg',
      sentQty: 1,
      acceptedQty: 0,
      amount: 0,
      currency: '',
      note: '',
      eventType: 'customer_issue_pending',
      highlight: '',
      status: DispatchStatus.pending,
      createdLabel: '2026-03-26T04:12:31Z',
    );

    WerkaRuntimeStore.instance.recordCreatedPending(pendingRecord);

    final inflated = WerkaRuntimeStore.instance.applySummary(
      const WerkaHomeSummary(
        pendingCount: 1,
        confirmedCount: 0,
        returnedCount: 0,
      ),
    );

    expect(inflated.pendingCount, 2);

    WerkaRuntimeStore.instance.reconcileWithServer(
      pendingItems: const [pendingRecord],
      historyItems: const <DispatchRecord>[],
    );

    final reconciled = WerkaRuntimeStore.instance.applySummary(
      const WerkaHomeSummary(
        pendingCount: 1,
        confirmedCount: 0,
        returnedCount: 0,
      ),
    );

    expect(reconciled.pendingCount, 1);
  });
}
