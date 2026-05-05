import 'package:erpnext_stock_mobile/src/core/notifications/store/customer_delivery_runtime_store.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final store = CustomerDeliveryRuntimeStore.instance;

  setUp(() {
    store.clear();
  });

  tearDown(() {
    store.clear();
  });

  test('customer runtime treats partial delivery as rejected bucket', () {
    const before = DispatchRecord(
      id: 'MAT-DN-0001',
      supplierRef: 'CUST-001',
      supplierName: 'Comfi',
      itemCode: 'ITEM-001',
      itemName: 'Pista',
      uom: 'Kg',
      sentQty: 10,
      acceptedQty: 0,
      amount: 0,
      currency: '',
      note: '',
      eventType: '',
      highlight: '',
      status: DispatchStatus.pending,
      createdLabel: '2026-03-27 10:00:00',
    );
    const after = DispatchRecord(
      id: 'MAT-DN-0001',
      supplierRef: 'CUST-001',
      supplierName: 'Comfi',
      itemCode: 'ITEM-001',
      itemName: 'Pista',
      uom: 'Kg',
      sentQty: 10,
      acceptedQty: 7,
      amount: 0,
      currency: '',
      note: 'Customer qisman qabul qildi.',
      eventType: 'customer_delivery_partial',
      highlight: '',
      status: DispatchStatus.partial,
      createdLabel: '2026-03-27 10:00:00',
    );

    store.recordTransition(before: before, after: after);

    final rejected = store.applyStatusList(
      CustomerStatusKind.rejected,
      const <DispatchRecord>[],
    );
    expect(rejected, hasLength(1));
    expect(rejected.first.status, DispatchStatus.partial);

    final summary = store.applySummary(
      const CustomerHomeSummary(
        pendingCount: 1,
        confirmedCount: 0,
        rejectedCount: 0,
      ),
    );
    expect(summary.pendingCount, 0);
    expect(summary.rejectedCount, 1);
  });
}
