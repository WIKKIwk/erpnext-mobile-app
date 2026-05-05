part of '../mobile_api.dart';

extension MobileApiCustomer on MobileApi {
  String get baseUrl => MobileApi.baseUrl;

  Future<CustomerHomeSummary> customerSummary() async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/customer/summary'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Customer summary failed');
    }
    return CustomerHomeSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<DispatchRecord>> customerHistory() async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/customer/history'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Customer history failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DispatchRecord>> customerStatusDetails(
    CustomerStatusKind kind,
  ) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/customer/status-details').replace(
          queryParameters: {'kind': kind.name},
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Customer status details failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerDeliveryDetail> customerDeliveryDetail(
    String deliveryNoteID,
  ) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/customer/detail').replace(
          queryParameters: {'delivery_note_id': deliveryNoteID},
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Customer detail failed');
    }
    return CustomerDeliveryDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CustomerDeliveryDetail> customerRespondDelivery({
    required String deliveryNoteID,
    bool? approve,
    CustomerDeliveryResponseMode? mode,
    double? acceptedQty,
    double? returnedQty,
    String reason = '',
    String comment = '',
  }) async {
    final body = <String, dynamic>{
      'delivery_note_id': deliveryNoteID,
      'reason': reason,
    };
    if (approve != null) {
      body['approve'] = approve;
    }
    if (mode != null) {
      body['mode'] = customerDeliveryResponseModeApiValue(mode);
    }
    if (acceptedQty != null) {
      body['accepted_qty'] = acceptedQty;
    }
    if (returnedQty != null) {
      body['returned_qty'] = returnedQty;
    }
    if (comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/customer/respond'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Customer respond failed');
    }
    return CustomerDeliveryDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
