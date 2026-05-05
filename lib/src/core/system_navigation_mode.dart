import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android: tizim navigatsiyasi gesture yoki tugmali ekanini aniqlash.
///
/// Kanal `accord/system_navigation` — [SystemNavigationMode.kt].
/// iOS / boshqa platformalar: [isGestureNavigation] `false` qaytaradi.
class SystemNavigationMode {
  SystemNavigationMode._();

  static const MethodChannel _channel =
      MethodChannel('accord/system_navigation');

  /// `true` → Android tomonda gesture navigatsiyasiga yaqin deb hisoblangan.
  static Future<bool> isGestureNavigation() async {
    if (!Platform.isAndroid) return false;
    try {
      final Object? v =
          await _channel.invokeMethod<Object?>('isGestureNavigation');
      return v == true;
    } on PlatformException catch (e, st) {
      debugPrint('SystemNavigationMode.isGestureNavigation: $e\n$st');
      return false;
    }
  }

  /// Debug: raw `navigation_mode`, `use_gesture_version_three`, `isGestureNavigation`.
  static Future<Map<String, Object?>?> debugSnapshot() async {
    if (!Platform.isAndroid) return null;
    try {
      final Object? v = await _channel.invokeMethod<Object?>('debugSnapshot');
      if (v is Map) {
        return v.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } on PlatformException catch (e, st) {
      debugPrint('SystemNavigationMode.debugSnapshot: $e\n$st');
      return null;
    }
  }
}
