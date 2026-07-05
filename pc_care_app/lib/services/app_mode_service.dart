import 'package:shared_preferences/shared_preferences.dart';

enum AppMode {
  demo,
  real;

  String get label => this == AppMode.demo ? 'Demo Mode' : 'Connected to PC';
}

class AppModeService {
  static const String _key = 'app_mode';

  Future<AppMode?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return raw == 'real' ? AppMode.real : AppMode.demo;
  }

  Future<void> save(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == AppMode.real ? 'real' : 'demo');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
