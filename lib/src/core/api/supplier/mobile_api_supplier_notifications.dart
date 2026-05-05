part of '../mobile_api.dart';

extension MobileApiSupplierNotifications on MobileApi {
  String get baseUrl => MobileApi.baseUrl;

  Future<List<DispatchRecord>> supplierHistory() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/supplier/history'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Supplier history failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SupplierHomeSummary> supplierSummary() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/supplier/summary'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Supplier summary failed');
    }
    return SupplierHomeSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<SupplierStatusBreakdownEntry>> supplierStatusBreakdown(
    SupplierStatusKind kind,
  ) async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/supplier/status-breakdown').replace(
          queryParameters: {'kind': kind.name},
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Supplier status breakdown failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map(
          (item) => SupplierStatusBreakdownEntry.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<DispatchRecord>> supplierStatusDetails({
    required SupplierStatusKind kind,
    required String itemCode,
  }) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/supplier/status-details').replace(
          queryParameters: {
            'kind': kind.name,
            'item_code': itemCode,
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Supplier status details failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationDetail> notificationDetail(String receiptID) async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/notifications/detail')
            .replace(queryParameters: {'receipt_id': receiptID}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Notification detail failed');
    }
    return NotificationDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NotificationDetail> addNotificationComment({
    required String receiptID,
    required String message,
  }) async {
    final http.Response response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/notifications/comments')
            .replace(queryParameters: {'receipt_id': receiptID}),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'message': message}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Notification comment failed');
    }
    return NotificationDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<SupplierItem>> supplierItems({String query = ''}) async {
    final Uri uri = Uri.parse('$baseUrl/v1/mobile/supplier/items').replace(
      queryParameters: query.trim().isEmpty ? null : {'q': query},
    );
    final http.Response response = await _sendAuthorized(
      () => http.get(
        uri,
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Supplier items failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DispatchRecord> createDispatch({
    required String itemCode,
    required double qty,
  }) async {
    final http.Response response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/supplier/dispatch'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'item_code': itemCode,
          'qty': qty,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Dispatch create failed');
    }
    return DispatchRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NotificationDetail> supplierRespondUnannounced({
    required String receiptID,
    required bool approve,
    String reason = '',
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/supplier/unannounced/respond'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'receipt_id': receiptID,
          'approve': approve,
          'reason': reason,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Supplier unannounced response failed');
    }
    return NotificationDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
