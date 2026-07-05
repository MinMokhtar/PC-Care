import 'package:shared_preferences/shared_preferences.dart';

/// Persists the IP/hostname + pairing PIN + MAC address of the Windows
/// companion app the user picked on the Connect PC screen.
class CompanionPrefsService {
  static const String _hostKey = 'companion_host';
  static const String _pinKey = 'companion_pin';
  static const String _macKey = 'companion_mac';

  Future<String?> loadHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hostKey);
  }

  Future<void> saveHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host);
  }

  Future<String?> loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<String?> loadMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_macKey);
  }

  Future<void> saveMac(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_macKey, mac);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hostKey);
    await prefs.remove(_pinKey);
    await prefs.remove(_macKey);
  }
}
