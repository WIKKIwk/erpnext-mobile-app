import 'package:erpnext_stock_mobile/src/core/widgets/shell/app_retry_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content width scales from phone width', () {
    expect(
      AppRetryState.contentWidthFor(const Size(390, 844)),
      closeTo(343.2, 0.1),
    );
  });

  test('content width clamps on narrow screens', () {
    expect(AppRetryState.contentWidthFor(const Size(300, 600)), 280.0);
  });
}
