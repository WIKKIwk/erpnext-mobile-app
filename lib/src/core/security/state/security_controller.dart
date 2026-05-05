import 'dart:convert';

import '../../../features/shared/models/app_models.dart';
import '../../session/session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityController extends ChangeNotifier with WidgetsBindingObserver {
  SecurityController._();

  static final SecurityController instance = SecurityController._();
  static const String _pinKeyPrefix = 'security_pin_hash_';
  static const String _biometricKeyPrefix = 'security_biometric_';

  final LocalAuthentication _localAuth = LocalAuthentication();
  SharedPreferences? _prefs;
  bool _loaded = false;
  bool _locked = false;
  bool _privacyShieldVisible = false;
  bool _wasBackgrounded = false;
  bool _authInProgress = false;
  bool _suspendResumeLock = false;

  bool get loaded => _loaded;
  bool get locked => _loaded && _locked && hasPinForCurrentUser;
  bool get privacyShieldVisible =>
      _loaded && _privacyShieldVisible && hasPinForCurrentUser;
  bool get hasPinForCurrentUser =>
      _hasPinForProfile(AppSession.instance.profile);
  bool get biometricEnabledForCurrentUser =>
      _biometricEnabledForProfile(AppSession.instance.profile);

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    WidgetsBinding.instance.addObserver(this);
    _loaded = true;
    _locked = hasPinForCurrentUser;
    notifyListeners();
  }

  Future<void> unlockAfterLogin() async {
    _prefs ??= await SharedPreferences.getInstance();
    _locked = false;
    _privacyShieldVisible = false;
    notifyListeners();
  }

  Future<void> clearForLogout() async {
    _prefs ??= await SharedPreferences.getInstance();
    _locked = false;
    _privacyShieldVisible = false;
    _wasBackgrounded = false;
    _suspendResumeLock = false;
    _authInProgress = false;
    notifyListeners();
  }

  Future<void> savePinForCurrentUser(String pin) async {
    _prefs ??= await SharedPreferences.getInstance();
    final profile = AppSession.instance.profile;
    if (profile == null) {
      throw Exception('No active profile');
    }
    if (!_isValidPin(pin)) {
      throw Exception('PIN 4 xonali bo‘lishi kerak');
    }
    await _prefs!.setString(_pinKey(profile), _hash(pin));
    _locked = false;
    _privacyShieldVisible = false;
    notifyListeners();
  }

  Future<void> clearPinForCurrentUser() async {
    _prefs ??= await SharedPreferences.getInstance();
    final profile = AppSession.instance.profile;
    if (profile == null) {
      return;
    }
    await _prefs!.remove(_pinKey(profile));
    await _prefs!.remove(_biometricKey(profile));
    _locked = false;
    _privacyShieldVisible = false;
    notifyListeners();
  }

  Future<bool> unlockWithPin(String pin) async {
    _prefs ??= await SharedPreferences.getInstance();
    final profile = AppSession.instance.profile;
    if (profile == null) {
      return false;
    }
    final storedHash = _prefs!.getString(_pinKey(profile)) ?? '';
    if (storedHash.isEmpty || storedHash != _hash(pin)) {
      return false;
    }
    _locked = false;
    _privacyShieldVisible = false;
    notifyListeners();
    return true;
  }

  Future<bool> canUseBiometrics() async {
    try {
      final bool supported = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final biometrics = await _localAuth.getAvailableBiometrics();
      return supported && canCheck && biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setBiometricEnabledForCurrentUser(bool enabled) async {
    _prefs ??= await SharedPreferences.getInstance();
    final profile = AppSession.instance.profile;
    if (profile == null || !_hasPinForProfile(profile)) {
      return false;
    }
    if (enabled) {
      final bool available = await canUseBiometrics();
      if (!available) {
        return false;
      }
      final bool ok = await _authenticate(
        reason: 'Tezkor ochish uchun Face ID yoki fingerprintni yoqing',
      );
      if (!ok) {
        return false;
      }
    }
    await _prefs!.setBool(_biometricKey(profile), enabled);
    notifyListeners();
    return true;
  }

  Future<bool> unlockWithBiometric() async {
    if (!biometricEnabledForCurrentUser || !locked) {
      return false;
    }
    final bool ok = await _authenticate(
      reason: 'Appni ochish uchun biometrik tasdiqdan o‘ting',
    );
    if (ok) {
      _locked = false;
      _privacyShieldVisible = false;
      notifyListeners();
    }
    return ok;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_loaded) {
      return;
    }
    if (_authInProgress) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (hasPinForCurrentUser && !_privacyShieldVisible) {
        _privacyShieldVisible = true;
        notifyListeners();
      }
      _wasBackgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (_suspendResumeLock) {
        _suspendResumeLock = false;
        _wasBackgrounded = false;
        if (_privacyShieldVisible) {
          _privacyShieldVisible = false;
          notifyListeners();
        }
        return;
      }
      var changed = false;
      if (_wasBackgrounded && hasPinForCurrentUser) {
        _locked = true;
        changed = true;
      }
      if (_privacyShieldVisible) {
        _privacyShieldVisible = false;
        changed = true;
      }
      _wasBackgrounded = false;
      if (changed) {
        notifyListeners();
      }
    }
  }

  bool _hasPinForProfile(SessionProfile? profile) {
    if (profile == null || _prefs == null) {
      return false;
    }
    final value = _prefs!.getString(_pinKey(profile)) ?? '';
    return value.isNotEmpty;
  }

  bool _biometricEnabledForProfile(SessionProfile? profile) {
    if (profile == null || _prefs == null) {
      return false;
    }
    return _prefs!.getBool(_biometricKey(profile)) ?? false;
  }

  String _pinKey(SessionProfile profile) =>
      '$_pinKeyPrefix${_profileKey(profile)}';
  String _biometricKey(SessionProfile profile) =>
      '$_biometricKeyPrefix${_profileKey(profile)}';

  String _profileKey(SessionProfile profile) =>
      '${profile.role.name}:${profile.ref}';

  bool _isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin.trim());

  String _hash(String value) =>
      sha256.convert(utf8.encode(value.trim())).toString();

  Future<bool> _authenticate({required String reason}) async {
    if (_authInProgress) {
      return false;
    }
    _authInProgress = true;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok) {
        _suspendResumeLock = true;
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      _authInProgress = false;
    }
  }
}
