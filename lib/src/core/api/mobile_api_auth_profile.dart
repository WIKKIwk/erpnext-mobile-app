part of 'mobile_api.dart';

extension MobileApiAuthProfile on MobileApi {
  String get baseUrl => MobileApi.baseUrl;

  Future<SessionProfile> login({
    required String phone,
    required String code,
  }) async {
    return _performLogin(phone: phone, code: code);
  }

  Future<SessionProfile> _performLogin({
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
    final WerkaHomeData? werkaHome = profile.role == UserRole.werka &&
            json['werka_home'] is Map<String, dynamic>
        ? WerkaHomeData.fromJson(json['werka_home'] as Map<String, dynamic>)
        : null;
    await AppSession.instance.setSession(
      token: token,
      profile: profile,
      werkaHomeBootstrap: werkaHome,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(MobileApi._lastPhoneKey, phone);
    await prefs.setString(MobileApi._lastCodeKey, code);
    return profile;
  }

  Future<void> registerPushToken({
    required String tokenValue,
    required String platform,
  }) async {
    final trimmedToken = tokenValue.trim();
    final profile = AppSession.instance.profile;
    debugPrint(
      'push register request role=${profile?.role.name ?? 'none'} '
      'ref=${profile?.ref ?? ''} '
      'platform=${platform.trim()} '
      'token=${maskPushToken(trimmedToken)}',
    );
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/push/token'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'token': trimmedToken,
          'platform': platform,
        }),
      ),
    );
    debugPrint(
      'push register response status=${response.statusCode} '
      'token=${maskPushToken(trimmedToken)}',
    );
    if (response.statusCode != 200) {
      throw Exception('Push token register failed');
    }
  }

  Future<void> unregisterPushToken(String tokenValue) async {
    final token = AppSession.instance.token;
    if (token == null || token.isEmpty) {
      return;
    }
    debugPrint(
      'push unregister request token=${maskPushToken(tokenValue.trim())}',
    );
    await http.delete(
      Uri.parse('$baseUrl/v1/mobile/push/token')
          .replace(queryParameters: {'token': tokenValue}),
      headers: _headers(token),
    );
  }

  Future<void> logout() async {
    final String? token = AppSession.instance.token;
    if (token != null) {
      try {
        await PushMessagingService.instance.unregisterCurrentToken();
      } catch (_) {}
      try {
        await http.post(
          Uri.parse('$baseUrl/v1/mobile/auth/logout'),
          headers: _headers(token),
        );
      } catch (_) {}
    }
    await AppSession.instance.clear();
  }

  Future<SessionProfile> profile() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/profile'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Profile fetch failed');
    }
    final SessionProfile profile = SessionProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await AppSession.instance.updateProfile(profile);
    return profile;
  }

  Future<SessionProfile> updateNickname(String nickname) async {
    final http.Response response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/profile'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'nickname': nickname}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Nickname update failed');
    }
    final SessionProfile profile = SessionProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await AppSession.instance.updateProfile(profile);
    return profile;
  }

  Future<SessionProfile> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final streamed = await _sendMultipartAuthorized(
      () {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/v1/mobile/profile/avatar'),
        );
        request.headers.addAll(_headers(requireToken()));
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            bytes,
            filename: filename,
          ),
        );
        return request.send();
      },
    );
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Avatar upload failed');
    }
    final SessionProfile profile = SessionProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await AppSession.instance.updateProfile(profile);
    return profile;
  }
}
