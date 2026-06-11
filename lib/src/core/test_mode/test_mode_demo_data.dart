import '../../features/admin/models/admin_item_group_tree_entry.dart';
import '../../features/shared/models/app_models.dart';

class TestModeDemoData {
  const TestModeDemoData._();

  static const AdminSettings adminSettings = AdminSettings(
    erpUrl: 'https://demo.local',
    erpApiKey: 'demo-key',
    erpApiSecret: 'demo-secret',
    defaultTargetWarehouse: 'Tayyor mahsulot ombori - DEMO',
    defaultUom: 'Dona',
    werkaPhone: '+998900000001',
    werkaName: 'Demo omborchi',
    werkaCode: '1111',
    werkaCodeLocked: false,
    werkaCodeRetryAfterSec: 0,
    adminPhone: '+998900000000',
    adminName: 'Demo admin',
  );

  static const List<SupplierItem> items = [
    SupplierItem(
      code: 'DEMO-HOTLUNCH',
      name: 'Hotlunch',
      uom: 'Dona',
      warehouse: 'Tayyor mahsulot ombori - DEMO',
      itemGroup: 'Demo tayyor mahsulotlar',
    ),
    SupplierItem(
      code: 'DEMO-CPP',
      name: 'CPP sous',
      uom: 'Kg',
      warehouse: 'Xomashyo ombori - DEMO',
      itemGroup: 'Demo xomashyo',
    ),
    SupplierItem(
      code: 'DEMO-PACK',
      name: 'Qadoq quti',
      uom: 'Dona',
      warehouse: 'Qadoqlash ombori - DEMO',
      itemGroup: 'Demo qadoqlash',
    ),
    SupplierItem(
      code: 'DEMO-SALAD',
      name: 'Salat set',
      uom: 'Dona',
      warehouse: 'Tayyor mahsulot ombori - DEMO',
      itemGroup: 'Demo tayyor mahsulotlar',
    ),
  ];

  static const List<AdminWarehouse> warehouses = [
    AdminWarehouse(warehouse: 'Xomashyo ombori - DEMO'),
    AdminWarehouse(warehouse: 'Qadoqlash ombori - DEMO'),
    AdminWarehouse(warehouse: 'Tayyor mahsulot ombori - DEMO'),
    AdminWarehouse(
      warehouse: 'Godex aparat - DEMO',
      parentWarehouse: 'aparat - A',
    ),
    AdminWarehouse(
      warehouse: '7 ta rangli pechat',
      parentWarehouse: 'aparat - A',
    ),
    AdminWarehouse(
      warehouse: '8 ta rangli pechat',
      parentWarehouse: 'aparat - A',
    ),
    AdminWarehouse(
      warehouse: '9 ta rangli pechat',
      parentWarehouse: 'aparat - A',
    ),
    AdminWarehouse(
      warehouse: 'Laminatsiya 1',
      parentWarehouse: 'aparat - A',
    ),
    AdminWarehouse(
      warehouse: 'Laminatsiya 2',
      parentWarehouse: 'aparat - A',
    ),
  ];

  static const List<AdminApparatusGroup> apparatusGroups = [
    AdminApparatusGroup(
      name: 'pechat',
      apparatus: [
        '7 ta rangli pechat',
        '8 ta rangli pechat',
        '9 ta rangli pechat',
      ],
    ),
    AdminApparatusGroup(
      name: 'Laminatsiya',
      apparatus: [
        'Laminatsiya 1',
        'Laminatsiya 2',
      ],
    ),
  ];

  static const List<AdminSupplier> suppliers = [
    AdminSupplier(
      ref: 'demo-supplier-1',
      name: 'Demo ta’minotchi',
      phone: '+998901112233',
      code: '2222',
      blocked: false,
      removed: false,
      assignedItemCodes: ['DEMO-CPP', 'DEMO-PACK'],
      assignedItemCount: 2,
    ),
    AdminSupplier(
      ref: 'demo-supplier-2',
      name: 'Demo qadoqlovchi',
      phone: '+998902223344',
      code: '3333',
      blocked: false,
      removed: false,
      assignedItemCodes: ['DEMO-PACK'],
      assignedItemCount: 1,
    ),
  ];

  static const List<CustomerDirectoryEntry> customers = [
    CustomerDirectoryEntry(
      ref: 'demo-customer-1',
      name: 'Demo haridor',
      phone: '+998903334455',
    ),
    CustomerDirectoryEntry(
      ref: 'demo-customer-2',
      name: 'Demo filial',
      phone: '+998904445566',
    ),
  ];

  static const List<AdminRoleDefinition> roles = [
    AdminRoleDefinition(
      id: 'demo-admin',
      label: 'Demo admin',
      baseRole: UserRole.admin,
      capabilityCodes: [
        'admin.access',
        'catalog.item.read',
        'party.supplier.read',
        'party.customer.read',
        'production.map.manage',
      ],
      system: false,
    ),
  ];

  static const List<AdminRoleAssignment> roleAssignments = [
    AdminRoleAssignment(
      principalRole: UserRole.supplier,
      principalRef: 'demo-supplier-1',
      roleId: 'demo-admin',
    ),
  ];

  static const List<String> itemGroups = [
    'Demo tayyor mahsulotlar',
    'Demo xomashyo',
    'Demo qadoqlash',
  ];

  static const List<AdminItemGroupTreeEntry> itemGroupTree = [
    AdminItemGroupTreeEntry(
      name: 'demo-ready',
      itemGroupName: 'Demo tayyor mahsulotlar',
      parentItemGroup: '',
      isGroup: true,
    ),
    AdminItemGroupTreeEntry(
      name: 'demo-raw',
      itemGroupName: 'Demo xomashyo',
      parentItemGroup: '',
      isGroup: true,
    ),
    AdminItemGroupTreeEntry(
      name: 'demo-packaging',
      itemGroupName: 'Demo qadoqlash',
      parentItemGroup: '',
      isGroup: true,
    ),
  ];

  static AdminSupplierSummary get supplierSummary {
    final active = suppliers.where((item) => !item.blocked).length;
    return AdminSupplierSummary(
      totalSuppliers: suppliers.length,
      activeSuppliers: active,
      blockedSuppliers: suppliers.length - active,
    );
  }

  static List<SupplierItem> itemPage({
    String query = '',
    String group = '',
    int limit = 50,
    int offset = 0,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedGroup = group.trim().toLowerCase();
    final filtered = items.where((item) {
      final matchesGroup = normalizedGroup.isEmpty ||
          item.itemGroup.toLowerCase() == normalizedGroup;
      final matchesQuery = normalizedQuery.isEmpty ||
          item.code.toLowerCase().contains(normalizedQuery) ||
          item.name.toLowerCase().contains(normalizedQuery) ||
          item.uom.toLowerCase().contains(normalizedQuery) ||
          item.warehouse.toLowerCase().contains(normalizedQuery) ||
          item.itemGroup.toLowerCase().contains(normalizedQuery);
      return matchesGroup && matchesQuery;
    }).toList(growable: false);
    return _page(filtered, limit: limit, offset: offset);
  }

  static List<AdminSupplier> supplierPage({
    int limit = 20,
    int offset = 0,
  }) {
    return _page(suppliers, limit: limit, offset: offset);
  }

  static List<CustomerDirectoryEntry> customerPage({
    int limit = 20,
    int offset = 0,
  }) {
    return _page(customers, limit: limit, offset: offset);
  }

  static AdminSupplierDetail supplierDetail(String ref) {
    final supplier = suppliers.firstWhere(
      (item) => item.ref == ref,
      orElse: () => suppliers.first,
    );
    final assignedItems = items
        .where((item) => supplier.assignedItemCodes.contains(item.code))
        .toList(growable: false);
    return AdminSupplierDetail(
      ref: supplier.ref,
      name: supplier.name,
      phone: supplier.phone,
      code: supplier.code,
      blocked: supplier.blocked,
      removed: supplier.removed,
      codeLocked: false,
      codeRetryAfterSec: 0,
      assignedItems: assignedItems,
    );
  }

  static AdminCustomerDetail customerDetail(String ref) {
    final customer = customers.firstWhere(
      (item) => item.ref == ref,
      orElse: () => customers.first,
    );
    return AdminCustomerDetail(
      ref: customer.ref,
      name: customer.name,
      phone: customer.phone,
      code: '4444',
      codeLocked: false,
      codeRetryAfterSec: 0,
      assignedItems: items.take(2).toList(growable: false),
    );
  }

  static List<T> _page<T>(
    List<T> source, {
    required int limit,
    required int offset,
  }) {
    final start = offset <= 0
        ? 0
        : offset >= source.length
            ? source.length
            : offset;
    final end = limit <= 0
        ? source.length
        : start + limit >= source.length
            ? source.length
            : start + limit;
    return source.sublist(start, end);
  }
}
