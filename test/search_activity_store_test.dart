import 'package:erpnext_stock_mobile/src/core/search/search_activity_store.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.werka,
      displayName: 'Werka',
      legalName: 'Werka',
      ref: 'WERKA-001',
      phone: '',
      avatarUrl: '',
    );
    await SearchActivityStore.instance.debugReset();
  });

  tearDown(() async {
    AppSession.instance.profile = null;
    await SearchActivityStore.instance.debugReset();
  });

  test('puts frequently used items ahead of alphabetical fallback', () async {
    await SearchActivityStore.instance.recordItemSelection('ITEM-B');
    await SearchActivityStore.instance.recordItemSelections([
      'ITEM-C',
      'ITEM-C',
    ]);

    final sorted = await SearchActivityStore.instance.sortByItemCode(
      ['ITEM-A', 'ITEM-B', 'ITEM-C'],
      itemCode: (item) => item,
      fallback: (left, right) => left.compareTo(right),
    );

    expect(sorted, ['ITEM-C', 'ITEM-B', 'ITEM-A']);
  });

  test('keeps activity isolated per signed-in profile', () async {
    await SearchActivityStore.instance.recordItemSelections([
      'ITEM-B',
      'ITEM-B',
    ]);

    AppSession.instance.profile = const SessionProfile(
      role: UserRole.werka,
      displayName: 'Second',
      legalName: 'Second',
      ref: 'WERKA-002',
      phone: '',
      avatarUrl: '',
    );

    final sorted = await SearchActivityStore.instance.sortByItemCode(
      ['ITEM-A', 'ITEM-B'],
      itemCode: (item) => item,
      fallback: (left, right) => left.compareTo(right),
    );

    expect(sorted, ['ITEM-A', 'ITEM-B']);
  });
}
