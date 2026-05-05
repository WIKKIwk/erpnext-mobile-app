import '../../features/shared/models/app_models.dart';
import '../customer/customer_priority.dart';
import '../notifications/service/push_messaging_service.dart';
import '../search/search_activity_store.dart';
import '../search/search_normalizer.dart';
import '../session/session.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

part 'admin/mobile_api_admin.dart';
part 'auth/mobile_api_auth_profile.dart';
part 'customer/mobile_api_customer.dart';
part 'supplier/mobile_api_supplier_notifications.dart';
part 'werka/mobile_api_werka.dart';

class MobileApiException implements Exception {
  const MobileApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String maskPushToken(String token) {
  final trimmed = token.trim();
  if (trimmed.isEmpty) {
    return '<empty>';
  }
  if (trimmed.length <= 12) {
    return trimmed;
  }
  return '${trimmed.substring(0, 6)}...${trimmed.substring(trimmed.length - 6)}';
}

class MobileApi {
  MobileApi._();

  static final MobileApi instance = MobileApi._();
  static const String _lastCodeKey = 'last_login_code';
  static const String _lastPhoneKey = 'last_login_phone';
  static const int werkaPickerLimit = 50;

  static const String baseUrl = String.fromEnvironment(
    'MOBILE_API_BASE_URL',
    defaultValue: 'https://core.wspace.sbs',
  );

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

  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function() send,
  ) async {
    final http.Response response = await send();
    if (response.statusCode != 401) {
      return response;
    }

    final bool refreshed = await _reauthenticateFromStorage();
    if (!refreshed) {
      await AppSession.instance.clear();
      return response;
    }
    return send();
  }

  Future<http.StreamedResponse> _sendMultipartAuthorized(
    Future<http.StreamedResponse> Function() send,
  ) async {
    final http.StreamedResponse response = await send();
    if (response.statusCode != 401) {
      return response;
    }

    final bool refreshed = await _reauthenticateFromStorage();
    if (!refreshed) {
      await AppSession.instance.clear();
      return response;
    }
    return send();
  }

  Future<bool> _reauthenticateFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String phone = prefs.getString(_lastPhoneKey)?.trim() ?? '';
    final String code = prefs.getString(_lastCodeKey)?.trim() ?? '';
    if (phone.isEmpty || code.isEmpty) {
      return false;
    }

    try {
      await _performLogin(phone: phone, code: code);
      return true;
    } catch (_) {
      return false;
    }
  }
}
