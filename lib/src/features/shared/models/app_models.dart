enum UserRole {
  supplier,
  werka,
  customer,
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

const String customerDeliveryResultEventPrefix = 'customer_delivery_result:';

String customerDeliveryResultEventId(String deliveryNoteID) =>
    '$customerDeliveryResultEventPrefix${deliveryNoteID.trim()}';

DateTime? parseCreatedLabelTimestamp(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  final dateTimeWithSpace = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}');
  var normalized = trimmed;
  if (dateOnly.hasMatch(trimmed)) {
    normalized = '${trimmed}T00:00:00';
  } else if (dateTimeWithSpace.hasMatch(trimmed)) {
    normalized = trimmed.replaceFirst(' ', 'T');
  }
  return DateTime.tryParse(normalized);
}

int compareCreatedLabelsDesc(String left, String right) {
  final leftTime = parseCreatedLabelTimestamp(left);
  final rightTime = parseCreatedLabelTimestamp(right);
  if (leftTime != null && rightTime != null) {
    return rightTime.compareTo(leftTime);
  }
  if (leftTime != null) {
    return -1;
  }
  if (rightTime != null) {
    return 1;
  }
  return right.compareTo(left);
}

bool createdLabelIsAfter(String candidate, String current) {
  final candidateTime = parseCreatedLabelTimestamp(candidate);
  final currentTime = parseCreatedLabelTimestamp(current);
  if (candidateTime != null && currentTime != null) {
    return candidateTime.isAfter(currentTime);
  }
  if (candidateTime != null) {
    return true;
  }
  if (currentTime != null) {
    return false;
  }
  return candidate.compareTo(current) > 0;
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

class SupplierDirectoryEntry {
  const SupplierDirectoryEntry({
    required this.ref,
    required this.name,
    required this.phone,
  });

  final String ref;
  final String name;
  final String phone;

  factory SupplierDirectoryEntry.fromJson(Map<String, dynamic> json) {
    return SupplierDirectoryEntry(
      ref: json['ref'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class CustomerDirectoryEntry {
  const CustomerDirectoryEntry({
    required this.ref,
    required this.name,
    required this.phone,
  });

  final String ref;
  final String name;
  final String phone;

  factory CustomerDirectoryEntry.fromJson(Map<String, dynamic> json) {
    return CustomerDirectoryEntry(
      ref: json['ref'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class CustomerItemOption {
  const CustomerItemOption({
    required this.customerRef,
    required this.customerName,
    required this.customerPhone,
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.warehouse,
  });

  final String customerRef;
  final String customerName;
  final String customerPhone;
  final String itemCode;
  final String itemName;
  final String uom;
  final String warehouse;

  factory CustomerItemOption.fromJson(Map<String, dynamic> json) {
    return CustomerItemOption(
      customerRef: json['customer_ref'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      warehouse: json['warehouse'] as String? ?? '',
    );
  }
}

class WerkaCustomerIssueRecord {
  const WerkaCustomerIssueRecord({
    required this.entryID,
    required this.customerRef,
    required this.customerName,
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.qty,
    required this.createdLabel,
  });

  final String entryID;
  final String customerRef;
  final String customerName;
  final String itemCode;
  final String itemName;
  final String uom;
  final double qty;
  final String createdLabel;

  factory WerkaCustomerIssueRecord.fromJson(Map<String, dynamic> json) {
    return WerkaCustomerIssueRecord(
      entryID: json['entry_id'] as String? ?? '',
      customerRef: json['customer_ref'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      createdLabel: json['created_label'] as String? ?? '',
    );
  }
}

class SupplierHomeSummary {
  const SupplierHomeSummary({
    required this.pendingCount,
    required this.submittedCount,
    required this.returnedCount,
  });

  final int pendingCount;
  final int submittedCount;
  final int returnedCount;

  factory SupplierHomeSummary.fromJson(Map<String, dynamic> json) {
    return SupplierHomeSummary(
      pendingCount: json['pending_count'] as int? ?? 0,
      submittedCount: json['submitted_count'] as int? ?? 0,
      returnedCount: json['returned_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending_count': pendingCount,
      'submitted_count': submittedCount,
      'returned_count': returnedCount,
    };
  }
}

class CustomerHomeSummary {
  const CustomerHomeSummary({
    required this.pendingCount,
    required this.confirmedCount,
    required this.rejectedCount,
  });

  final int pendingCount;
  final int confirmedCount;
  final int rejectedCount;

  factory CustomerHomeSummary.fromJson(Map<String, dynamic> json) {
    return CustomerHomeSummary(
      pendingCount: json['pending_count'] as int? ?? 0,
      confirmedCount: json['confirmed_count'] as int? ?? 0,
      rejectedCount: json['rejected_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending_count': pendingCount,
      'confirmed_count': confirmedCount,
      'rejected_count': rejectedCount,
    };
  }
}

enum CustomerStatusKind {
  pending,
  confirmed,
  rejected,
}

enum CustomerDeliveryResponseMode {
  acceptAll,
  acceptPartial,
  rejectAll,
  claimAfterAccept,
}

String customerDeliveryResponseModeApiValue(CustomerDeliveryResponseMode mode) {
  switch (mode) {
    case CustomerDeliveryResponseMode.acceptAll:
      return 'accept_all';
    case CustomerDeliveryResponseMode.acceptPartial:
      return 'accept_partial';
    case CustomerDeliveryResponseMode.rejectAll:
      return 'reject_all';
    case CustomerDeliveryResponseMode.claimAfterAccept:
      return 'claim_after_accept';
  }
}

enum SupplierStatusKind {
  pending,
  submitted,
  returned,
}

class SupplierStatusBreakdownEntry {
  const SupplierStatusBreakdownEntry({
    required this.itemCode,
    required this.itemName,
    required this.receiptCount,
    required this.totalSentQty,
    required this.totalAcceptedQty,
    required this.totalReturnedQty,
    required this.uom,
  });

  final String itemCode;
  final String itemName;
  final int receiptCount;
  final double totalSentQty;
  final double totalAcceptedQty;
  final double totalReturnedQty;
  final String uom;

  factory SupplierStatusBreakdownEntry.fromJson(Map<String, dynamic> json) {
    return SupplierStatusBreakdownEntry(
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      receiptCount: json['receipt_count'] as int? ?? 0,
      totalSentQty: (json['total_sent_qty'] as num?)?.toDouble() ?? 0,
      totalAcceptedQty: (json['total_accepted_qty'] as num?)?.toDouble() ?? 0,
      totalReturnedQty: (json['total_returned_qty'] as num?)?.toDouble() ?? 0,
      uom: json['uom'] as String? ?? '',
    );
  }
}

class WerkaHomeSummary {
  const WerkaHomeSummary({
    required this.pendingCount,
    required this.confirmedCount,
    required this.returnedCount,
  });

  final int pendingCount;
  final int confirmedCount;
  final int returnedCount;

  factory WerkaHomeSummary.fromJson(Map<String, dynamic> json) {
    return WerkaHomeSummary(
      pendingCount: json['pending_count'] as int? ?? 0,
      confirmedCount: json['confirmed_count'] as int? ?? 0,
      returnedCount: json['returned_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending_count': pendingCount,
      'confirmed_count': confirmedCount,
      'returned_count': returnedCount,
    };
  }
}

class WerkaHomeData {
  const WerkaHomeData({
    required this.summary,
    required this.pendingItems,
  });

  final WerkaHomeSummary summary;
  final List<DispatchRecord> pendingItems;

  factory WerkaHomeData.fromJson(Map<String, dynamic> json) {
    final pending = json['pending_items'] as List<dynamic>? ?? const [];
    return WerkaHomeData(
      summary: WerkaHomeSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      pendingItems: pending
          .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum WerkaStatusKind {
  pending,
  confirmed,
  returned,
}

class WerkaStatusBreakdownEntry {
  const WerkaStatusBreakdownEntry({
    required this.supplierRef,
    required this.supplierName,
    required this.receiptCount,
    required this.totalSentQty,
    required this.totalAcceptedQty,
    required this.totalReturnedQty,
    required this.uom,
  });

  final String supplierRef;
  final String supplierName;
  final int receiptCount;
  final double totalSentQty;
  final double totalAcceptedQty;
  final double totalReturnedQty;
  final String uom;

  factory WerkaStatusBreakdownEntry.fromJson(Map<String, dynamic> json) {
    return WerkaStatusBreakdownEntry(
      supplierRef: json['supplier_ref'] as String? ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      receiptCount: json['receipt_count'] as int? ?? 0,
      totalSentQty: (json['total_sent_qty'] as num?)?.toDouble() ?? 0,
      totalAcceptedQty: (json['total_accepted_qty'] as num?)?.toDouble() ?? 0,
      totalReturnedQty: (json['total_returned_qty'] as num?)?.toDouble() ?? 0,
      uom: json['uom'] as String? ?? '',
    );
  }
}

class DispatchRecord {
  const DispatchRecord({
    required this.id,
    this.recordType = '',
    required this.supplierRef,
    required this.supplierName,
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.sentQty,
    required this.acceptedQty,
    required this.amount,
    required this.currency,
    required this.note,
    required this.eventType,
    required this.highlight,
    required this.status,
    required this.createdLabel,
  });

  final String id;
  final String recordType;
  final String supplierRef;
  final String supplierName;
  final String itemCode;
  final String itemName;
  final String uom;
  final double sentQty;
  final double acceptedQty;
  final double amount;
  final String currency;
  final String note;
  final String eventType;
  final String highlight;
  final DispatchStatus status;
  final String createdLabel;

  bool get isDeliveryNote =>
      recordType == 'delivery_note' ||
      eventType.startsWith('customer_delivery_');

  factory DispatchRecord.fromJson(Map<String, dynamic> json) {
    return DispatchRecord(
      id: json['id'] as String? ?? '',
      recordType: json['record_type'] as String? ?? '',
      supplierRef: json['supplier_ref'] as String? ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      itemCode: json['item_code'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      uom: json['uom'] as String? ?? '',
      sentQty: (json['sent_qty'] as num?)?.toDouble() ?? 0,
      acceptedQty: (json['accepted_qty'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? '',
      note: json['note'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      highlight: json['highlight'] as String? ?? '',
      status: parseDispatchStatus(json['status'] as String? ?? ''),
      createdLabel: json['created_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_type': recordType,
      'supplier_ref': supplierRef,
      'supplier_name': supplierName,
      'item_code': itemCode,
      'item_name': itemName,
      'uom': uom,
      'sent_qty': sentQty,
      'accepted_qty': acceptedQty,
      'amount': amount,
      'currency': currency,
      'note': note,
      'event_type': eventType,
      'highlight': highlight,
      'status': status.name,
      'created_label': createdLabel,
    };
  }
}

class NotificationComment {
  const NotificationComment({
    required this.id,
    required this.authorLabel,
    required this.body,
    required this.createdLabel,
  });

  final String id;
  final String authorLabel;
  final String body;
  final String createdLabel;

  factory NotificationComment.fromJson(Map<String, dynamic> json) {
    return NotificationComment(
      id: json['id'] as String? ?? '',
      authorLabel: json['author_label'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdLabel: json['created_label'] as String? ?? '',
    );
  }
}

class NotificationDetail {
  const NotificationDetail({
    required this.record,
    required this.comments,
  });

  final DispatchRecord record;
  final List<NotificationComment> comments;

  factory NotificationDetail.fromJson(Map<String, dynamic> json) {
    return NotificationDetail(
      record: DispatchRecord.fromJson(
        json['record'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((item) =>
              NotificationComment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CustomerDeliveryDetail {
  const CustomerDeliveryDetail({
    required this.record,
    required this.canApprove,
    required this.canReject,
    required this.canPartiallyAccept,
    required this.canReportClaim,
  });

  final DispatchRecord record;
  final bool canApprove;
  final bool canReject;
  final bool canPartiallyAccept;
  final bool canReportClaim;

  factory CustomerDeliveryDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDeliveryDetail(
      record: DispatchRecord.fromJson(
        json['record'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      canApprove: json['can_approve'] as bool? ?? false,
      canReject: json['can_reject'] as bool? ?? false,
      canPartiallyAccept: json['can_partially_accept'] as bool? ?? false,
      canReportClaim: json['can_report_claim'] as bool? ?? false,
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
          : roleValue == 'customer'
              ? UserRole.customer
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
          : role == UserRole.customer
              ? 'customer'
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

  Map<String, dynamic> toJson() {
    return {
      'total_suppliers': totalSuppliers,
      'active_suppliers': activeSuppliers,
      'blocked_suppliers': blockedSuppliers,
    };
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

class AdminCustomerDetail {
  const AdminCustomerDetail({
    required this.ref,
    required this.name,
    required this.phone,
    required this.code,
    required this.codeLocked,
    required this.codeRetryAfterSec,
    required this.assignedItems,
  });

  final String ref;
  final String name;
  final String phone;
  final String code;
  final bool codeLocked;
  final int codeRetryAfterSec;
  final List<SupplierItem> assignedItems;

  factory AdminCustomerDetail.fromJson(Map<String, dynamic> json) {
    return AdminCustomerDetail(
      ref: json['ref'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      code: json['code'] as String? ?? '',
      codeLocked: json['code_locked'] as bool? ?? false,
      codeRetryAfterSec: json['code_retry_after_sec'] as int? ?? 0,
      assignedItems: (json['assigned_items'] as List<dynamic>? ?? const [])
          .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

enum AdminUserKind {
  supplier,
  werka,
  customer,
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

  String get roleLabel => kind == AdminUserKind.werka
      ? 'Werka'
      : kind == AdminUserKind.customer
          ? 'Customer'
          : 'Supplier';
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
