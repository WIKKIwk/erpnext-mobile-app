import 'dart:convert';

import 'package:erpnext_stock_mobile/src/features/admin/state/calculate_order_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and mutates calculate orders through the server client',
      () async {
    final client = _FakeCalculateOrderTemplateClient();
    final store = CalculateOrderTemplateStore(client: client);

    await store.load();
    expect(client.listCalls, 1);
    expect(store.templates, isEmpty);

    await store
        .upsert(_template(code: 'Z-CPP-1', name: 'CPP 600', widthMm: 530));
    await store
        .upsert(_template(code: 'Z-CPP-1', name: 'CPP 600', widthMm: 630));

    expect(client.upsertCalls, 2);
    expect(client.listCalls, 3);
    expect(store.templates, hasLength(1));
    expect(store.templates.single.code, 'Z-CPP-1');
    expect(store.templates.single.name, 'CPP 600');
    expect(store.templates.single.widthMm, 630);

    await store
        .upsert(_template(code: 'Z-CPP-2', name: 'CPP 600', widthMm: 700));
    expect(store.templates, hasLength(2));
    final first = store.templates.firstWhere(
      (template) => template.code == 'Z-CPP-1',
    );
    expect(first.materialDisplay, isEmpty);
    expect(first.imageId, 'img-1');
    expect(first.customerRef, 'CUST-001');
    expect(first.itemCode, 'ITEM-001');
    expect(jsonEncode(first.toJson()), isNot(contains('"kg"')));

    await store.delete(first.id);
    await store.delete(
      store.templates.firstWhere((template) => template.code == 'Z-CPP-2').id,
    );

    expect(client.deleteCalls, 2);
    expect(store.templates, isEmpty);
  });

  test('load hides duplicate calculate orders with the same code', () async {
    final client = _FakeCalculateOrderTemplateClient();
    client.seed([
      _copyWithServerFields(
        _template(code: 'Z-DUP-1', name: 'New copy', widthMm: 640),
        id: 'new-id',
        code: 'Z-DUP-1',
      ),
      _copyWithServerFields(
        _template(code: 'z-dup-1', name: 'Old copy', widthMm: 530),
        id: 'old-id',
        code: 'z-dup-1',
      ),
    ]);
    final store = CalculateOrderTemplateStore(client: client);

    await store.load();

    expect(store.templates, hasLength(1));
    expect(store.templates.single.id, 'new-id');
    expect(store.templates.single.widthMm, 640);
  });
}

class _FakeCalculateOrderTemplateClient
    implements CalculateOrderTemplateClient {
  final List<CalculateOrderTemplate> _templates = [];
  int listCalls = 0;
  int upsertCalls = 0;
  int deleteCalls = 0;

  void seed(List<CalculateOrderTemplate> templates) {
    _templates
      ..clear()
      ..addAll(templates);
  }

  @override
  Future<List<CalculateOrderTemplate>> listTemplates() async {
    listCalls++;
    return List<CalculateOrderTemplate>.from(_templates);
  }

  @override
  Future<CalculateOrderTemplate> upsertTemplate(
    CalculateOrderTemplate template,
  ) async {
    upsertCalls++;
    final normalizedCode = template.code.trim().toLowerCase();
    final index = normalizedCode.isEmpty
        ? -1
        : _templates.indexWhere(
            (item) => item.code.trim().toLowerCase() == normalizedCode,
          );
    final saved = _copyWithServerFields(
      template,
      id: index >= 0 ? _templates[index].id : 'template-$upsertCalls',
      code: template.code.trim().isEmpty
          ? 'Z-AUTO-$upsertCalls'
          : template.code.trim(),
    );
    if (index >= 0) {
      _templates[index] = saved;
    } else {
      _templates.add(saved);
    }
    return saved;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    deleteCalls++;
    _templates.removeWhere((template) => template.id == id);
  }
}

CalculateOrderTemplate _copyWithServerFields(
  CalculateOrderTemplate template, {
  required String id,
  required String code,
}) {
  return CalculateOrderTemplate(
    id: id,
    code: code,
    name: template.name,
    savedAt: DateTime.utc(2026, 6, 8, 12),
    orderNumber: template.orderNumber,
    customerRef: template.customerRef,
    customer: template.customer,
    itemCode: template.itemCode,
    product: template.product,
    status: template.status,
    materialDisplay: '',
    color: template.color,
    imageId: template.imageId,
    imageName: template.imageName,
    imageMime: template.imageMime,
    imageSizeBytes: template.imageSizeBytes,
    imageUrl: template.imageUrl,
    widthMm: template.widthMm,
    wastePercent: template.wastePercent,
    rollCount: template.rollCount,
    firstLayerMaterial: template.firstLayerMaterial,
    firstLayerMicron: template.firstLayerMicron,
    secondLayerMaterial: template.secondLayerMaterial,
    secondLayerMicron: template.secondLayerMicron,
    thirdLayerMaterial: template.thirdLayerMaterial,
    thirdLayerMicron: template.thirdLayerMicron,
    note: template.note,
  );
}

CalculateOrderTemplate _template({
  required String code,
  required String name,
  double widthMm = 530,
}) {
  return CalculateOrderTemplate(
    id: '',
    code: code,
    name: name,
    savedAt: DateTime.utc(2026, 6, 8, 11),
    orderNumber: 'ORD-1',
    customerRef: 'CUST-001',
    customer: 'Mijoz',
    itemCode: 'ITEM-001',
    product: 'cpp / 20 mikron / 600',
    status: 'Ready',
    materialDisplay: '',
    color: 'oq',
    imageId: 'img-1',
    imageName: 'rang.jpg',
    imageMime: 'image/jpeg',
    imageSizeBytes: 1234,
    imageUrl: '/v1/mobile/calculate/orders/image/view?id=img-1',
    widthMm: widthMm,
    wastePercent: 3,
    rollCount: 7,
    firstLayerMaterial: 'pet',
    firstLayerMicron: '12',
    secondLayerMaterial: 'pe oq',
    secondLayerMicron: '30',
    thirdLayerMaterial: '',
    thirdLayerMicron: '',
    note: 'test',
  );
}
