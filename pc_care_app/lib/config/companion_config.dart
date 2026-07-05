import '../services/companion_prefs_service.dart';

/// Configuration for talking to the Windows companion app.
///
/// [host] + [pin] are mutable statics — loaded from SharedPreferences at
/// app start via [loadFromPrefs], and updated by the Connect PC screen
/// via [setHostAndPin].
class CompanionConfig {
  static String host = '';
  static String pin = '';
  static String mac = '';
  static const int port = 5000;

  static String get baseUrl => 'http://$host:$port';

  /// Call once at app startup (in main). If the user has saved a host/PIN/MAC
  /// previously, those override the defaults.
  static Future<void> loadFromPrefs() async {
    final svc = CompanionPrefsService();
    final savedHost = await svc.loadHost();
    final savedPin = await svc.loadPin();
    final savedMac = await svc.loadMac();
    if (savedHost != null && savedHost.isNotEmpty) host = savedHost;
    if (savedPin != null && savedPin.isNotEmpty) pin = savedPin;
    if (savedMac != null && savedMac.isNotEmpty) mac = savedMac;
  }

  /// Updates the in-memory host + pin + mac AND persists them.
  static Future<void> setConnection(
      String newHost, String newPin, String newMac) async {
    host = newHost.trim();
    pin = newPin.trim();
    mac = newMac.trim();
    final svc = CompanionPrefsService();
    await svc.saveHost(host);
    await svc.savePin(pin);
    await svc.saveMac(mac);
  }

  /// Forgets the saved host + pin + mac. Used by the Settings "Disconnect" button.
  static Future<void> clear() async {
    host = '';
    pin = '';
    mac = '';
    await CompanionPrefsService().clear();
  }
}
