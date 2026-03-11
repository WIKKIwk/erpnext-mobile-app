enum UserRole {
  supplier,
  werka,
  admin,
}

enum DispatchStatus {
  draft,
  pending,
  accepted,
  partial,
  rejected,
  cancelled,
}

class SupplierItem {
  const SupplierItem({
    required this.code,
    required this.name,
    required this.uom,
    required this.warehouse,
  });

  final String code;
  final String name;
  final String uom;
  final String warehouse;

  factory SupplierItem.fromJson(Map<String, dynamic> json) {
    return SupplierItem(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      warehouse: json['warehouse'] as String? ?? '',
    );
  }
}

class DispatchRecord {
  const DispatchRecord({
    required this.id,
    required this.supplierName,
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.sentQty,
    required this.acceptedQty,
    required this.note,
    required this.status,
    required this.createdLabel,
  });

  final String id;
  final String supplierName;
  final String itemCode;
  final String itemName;
  final String uom;
  final double sentQty;
  final double acceptedQty;
  final String note;
  final DispatchStatus status;
  final String createdLabel;

  factory DispatchRecord.fromJson(Map<String, dynamic> json) {
    return DispatchRecord(
      id: json['id'] as String? ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      sentQty: (json['sent_qty'] as num?)?.toDouble() ?? 0,
      acceptedQty: (json['accepted_qty'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? '',
      status: parseDispatchStatus(json['status'] as String? ?? ''),
      createdLabel: json['created_label'] as String? ?? '',
    );
  }
}

class SessionProfile {
  const SessionProfile({
    required this.role,
    required this.displayName,
    required this.legalName,
    required this.ref,
    required this.phone,
    required this.avatarUrl,
  });

  final UserRole role;
  final String displayName;
  final String legalName;
  final String ref;
  final String phone;
  final String avatarUrl;

  factory SessionProfile.fromJson(Map<String, dynamic> json) {
    final String roleValue =
        (json['role'] as String? ?? '').trim().toLowerCase();
    return SessionProfile(
      role: roleValue == 'werka'
          ? UserRole.werka
          : roleValue == 'admin'
              ? UserRole.admin
              : UserRole.supplier,
      displayName: json['display_name'] as String? ?? '',
      legalName: json['legal_name'] as String? ?? '',
      ref: json['ref'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role == UserRole.werka
          ? 'werka'
          : role == UserRole.admin
              ? 'admin'
              : 'supplier',
      'display_name': displayName,
      'legal_name': legalName,
      'ref': ref,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }

  SessionProfile copyWith({
    UserRole? role,
    String? displayName,
    String? legalName,
    String? ref,
    String? phone,
    String? avatarUrl,
  }) {
    return SessionProfile(
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      legalName: legalName ?? this.legalName,
      ref: ref ?? this.ref,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class AdminSettings {
  const AdminSettings({
    required this.erpUrl,
    required this.erpApiKey,
    required this.erpApiSecret,
    required this.defaultTargetWarehouse,
    required this.defaultUom,
    required this.werkaPhone,
    required this.werkaName,
    required this.werkaCode,
    required this.werkaCodeLocked,
    required this.werkaCodeRetryAfterSec,
    required this.adminPhone,
    required this.adminName,
  });

  final String erpUrl;
  final String erpApiKey;
  final String erpApiSecret;
  final String defaultTargetWarehouse;
  final String defaultUom;
  final String werkaPhone;
  final String werkaName;
  final String werkaCode;
  final bool werkaCodeLocked;
  final int werkaCodeRetryAfterSec;
  final String adminPhone;
  final String adminName;

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    return AdminSettings(
      erpUrl: json['erp_url'] as String? ?? '',
      erpApiKey: json['erp_api_key'] as String? ?? '',
      erpApiSecret: json['erp_api_secret'] as String? ?? '',
      defaultTargetWarehouse: json['default_target_warehouse'] as String? ?? '',
      defaultUom: json['default_uom'] as String? ?? '',
      werkaPhone: json['werka_phone'] as String? ?? '',
      werkaName: json['werka_name'] as String? ?? '',
      werkaCode: json['werka_code'] as String? ?? '',
      werkaCodeLocked: json['werka_code_locked'] as bool? ?? false,
      werkaCodeRetryAfterSec: json['werka_code_retry_after_sec'] as int? ?? 0,
      adminPhone: json['admin_phone'] as String? ?? '',
      adminName: json['admin_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'erp_url': erpUrl,
      'erp_api_key': erpApiKey,
      'erp_api_secret': erpApiSecret,
      'default_target_warehouse': defaultTargetWarehouse,
      'default_uom': defaultUom,
      'werka_phone': werkaPhone,
      'werka_name': werkaName,
      'werka_code': werkaCode,
      'werka_code_locked': werkaCodeLocked,
      'werka_code_retry_after_sec': werkaCodeRetryAfterSec,
      'admin_phone': adminPhone,
      'admin_name': adminName,
    };
  }
}

class AdminSupplier {
  const AdminSupplier({
    required this.ref,
    required this.name,
    required this.phone,
    required this.code,
    required this.blocked,
    required this.removed,
    required this.assignedItemCodes,
    required this.assignedItemCount,
  });

  final String ref;
  final String name;
  final String phone;
  final String code;
  final bool blocked;
  final bool removed;
  final List<String> assignedItemCodes;
  final int assignedItemCount;

  factory AdminSupplier.fromJson(Map<String, dynamic> json) {
    return AdminSupplier(
      ref: json['ref'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      code: json['code'] as String? ?? '',
      blocked: json['blocked'] as bool? ?? false,
      removed: json['removed'] as bool? ?? false,
      assignedItemCodes: (json['assigned_item_codes'] as List<dynamic>? ?? [])
          .map((item) => item as String)
          .toList(),
      assignedItemCount: json['assigned_item_count'] as int? ?? 0,
    );
  }
}

class AdminSupplierSummary {
  const AdminSupplierSummary({
    required this.totalSuppliers,
    required this.activeSuppliers,
    required this.blockedSuppliers,
  });

  final int totalSuppliers;
  final int activeSuppliers;
  final int blockedSuppliers;

  factory AdminSupplierSummary.fromJson(Map<String, dynamic> json) {
    return AdminSupplierSummary(
      totalSuppliers: json['total_suppliers'] as int? ?? 0,
      activeSuppliers: json['active_suppliers'] as int? ?? 0,
      blockedSuppliers: json['blocked_suppliers'] as int? ?? 0,
    );
  }
}

class AdminSupplierDetail {
  const AdminSupplierDetail({
    required this.ref,
    required this.name,
    required this.phone,
    required this.code,
    required this.blocked,
    required this.removed,
    required this.codeLocked,
    required this.codeRetryAfterSec,
    required this.assignedItems,
  });

  final String ref;
  final String name;
  final String phone;
  final String code;
  final bool blocked;
  final bool removed;
  final bool codeLocked;
  final int codeRetryAfterSec;
  final List<SupplierItem> assignedItems;

  factory AdminSupplierDetail.fromJson(Map<String, dynamic> json) {
    return AdminSupplierDetail(
      ref: json['ref'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      code: json['code'] as String? ?? '',
      blocked: json['blocked'] as bool? ?? false,
      removed: json['removed'] as bool? ?? false,
      codeLocked: json['code_locked'] as bool? ?? false,
      codeRetryAfterSec: json['code_retry_after_sec'] as int? ?? 0,
      assignedItems: (json['assigned_items'] as List<dynamic>? ?? [])
          .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  AdminSupplierDetail copyWith({
    String? ref,
    String? name,
    String? phone,
    String? code,
    bool? blocked,
    bool? removed,
    bool? codeLocked,
    int? codeRetryAfterSec,
    List<SupplierItem>? assignedItems,
  }) {
    return AdminSupplierDetail(
      ref: ref ?? this.ref,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      code: code ?? this.code,
      blocked: blocked ?? this.blocked,
      removed: removed ?? this.removed,
      codeLocked: codeLocked ?? this.codeLocked,
      codeRetryAfterSec: codeRetryAfterSec ?? this.codeRetryAfterSec,
      assignedItems: assignedItems ?? this.assignedItems,
    );
  }
}

enum AdminUserKind {
  supplier,
  werka,
}

class AdminUserListEntry {
  const AdminUserListEntry({
    required this.id,
    required this.name,
    required this.phone,
    required this.kind,
    this.blocked = false,
  });

  final String id;
  final String name;
  final String phone;
  final AdminUserKind kind;
  final bool blocked;

  String get roleLabel => kind == AdminUserKind.werka ? 'Werka' : 'Supplier';
}

DispatchStatus parseDispatchStatus(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'accepted':
      return DispatchStatus.accepted;
    case 'partial':
      return DispatchStatus.partial;
    case 'rejected':
      return DispatchStatus.rejected;
    case 'cancelled':
      return DispatchStatus.cancelled;
    case 'draft':
      return DispatchStatus.draft;
    default:
      return DispatchStatus.pending;
  }
}
