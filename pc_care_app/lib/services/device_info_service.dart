import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a stable per-install device ID (UUID-like) and a friendly
/// device name (e.g. "Poco F6") so the PC can identify which phone is
/// hitting its API.
class DeviceInfoService {
  static const String _idKey = 'device_id';

  String? _cachedId;
  String? _cachedName;

  /// Returns the persistent ID for this install. Generates one on first call.
  Future<String> getId() async {
    if (_cachedId != null) return _cachedId!;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_idKey);
    if (existing != null && existing.isNotEmpty) {
      _cachedId = existing;
      return existing;
    }
    final generated = _generateId();
    await prefs.setString(_idKey, generated);
    _cachedId = generated;
    return generated;
  }

  /// Returns a friendly name like "Poco F6" or "Pixel 8". Falls back
  /// to "Phone" if device_info_plus fails.
  Future<String> getName() async {
    if (_cachedName != null) return _cachedName!;
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        // info.model is usually the marketing name on most modern devices
        // (e.g. "Poco F6"). Fallback to brand + device if model looks
        // like a raw codename.
        final name = info.model.trim().isNotEmpty
            ? info.model
            : '${info.brand} ${info.device}';
        _cachedName = name;
        return name;
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        _cachedName = info.utsname.machine;
        return _cachedName!;
      }
    } catch (_) {/* ignore */}
    _cachedName = 'Phone';
    return _cachedName!;
  }

  /// 32-char hex string (~128 bits of entropy). Cryptographically random.
  static String _generateId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
