import '../../features/shared/models/app_models.dart';
import '../session/app_session.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

class MobileApi {
  MobileApi._();

  static final MobileApi instance = MobileApi._();

  static const String baseUrl = String.fromEnvironment(
    'MOBILE_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );

  Future<SessionProfile> login({
    required String phone,
    required String code,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/v1/mobile/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'code': code,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed');
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String token = json['token'] as String? ?? '';
    final SessionProfile profile =
        SessionProfile.fromJson(json['profile'] as Map<String, dynamic>);
    AppSession.instance.setSession(token: token, profile: profile);
    return profile;
  }

  Future<void> logout() async {
    final String? token = AppSession.instance.token;
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/v1/mobile/auth/logout'),
        headers: _headers(token),
      );
    }
    AppSession.instance.clear();
  }

  Future<List<DispatchRecord>> supplierHistory() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/v1/mobile/supplier/history'),
      headers: _headers(requireToken()),
    );
    if (response.statusCode != 200) {
      throw Exception('Supplier history failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SupplierItem>> supplierItems({String query = ''}) async {
    final Uri uri = Uri.parse('$baseUrl/v1/mobile/supplier/items').replace(
      queryParameters: query.trim().isEmpty ? null : {'q': query},
    );
    final http.Response response = await http.get(
      uri,
      headers: _headers(requireToken()),
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
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/v1/mobile/supplier/dispatch'),
      headers: _headers(requireToken())..['Content-Type'] = 'application/json',
      body: jsonEncode({
        'item_code': itemCode,
        'qty': qty,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Dispatch create failed');
    }
    return DispatchRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<DispatchRecord>> werkaPending() async {
    final http.Response response = await http.get(
      Uri.parse('$baseUrl/v1/mobile/werka/pending'),
      headers: _headers(requireToken()),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka pending failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DispatchRecord> confirmReceipt({
    required String receiptID,
    required double acceptedQty,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('$baseUrl/v1/mobile/werka/confirm'),
      headers: _headers(requireToken())..['Content-Type'] = 'application/json',
      body: jsonEncode({
        'receipt_id': receiptID,
        'accepted_qty': acceptedQty,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Confirm receipt failed');
    }
    return DispatchRecord.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Map<String, String> _headers(String token) {
    return {
      'Authorization': 'Bearer $token',
    };
  }

  String requireToken() {
    final String? token = AppSession.instance.token;
    if (token == null || token.isEmpty) {
      throw Exception('No session token');
    }
    return token;
  }
}
