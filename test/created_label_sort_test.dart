import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compareCreatedLabelsDesc prefers parsed timestamps over document ids',
      () {
    final labels = <String>[
      'MAT-PRE-0001',
      '2026-03-21T08:15:30Z',
      '2026-03-20 11:20:00',
    ]..sort(compareCreatedLabelsDesc);

    expect(labels[0], '2026-03-21T08:15:30Z');
    expect(labels[1], '2026-03-20 11:20:00');
    expect(labels[2], 'MAT-PRE-0001');
  });

  test('createdLabelIsAfter handles date-only and full timestamps', () {
    expect(
      createdLabelIsAfter('2026-03-21T10:00:00Z', '2026-03-21'),
      isTrue,
    );
    expect(
      createdLabelIsAfter('2026-03-20', '2026-03-21T10:00:00Z'),
      isFalse,
    );
  });
}
