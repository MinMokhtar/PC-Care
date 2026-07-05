import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pc_specs.dart';

class PcSpecsService {
  static const String _key = 'pc_specs';

  Future<PcSpecs> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return PcSpecs.empty;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PcSpecs.fromJson(json);
    } catch (_) {
      return PcSpecs.empty;
    }
  }

  Future<void> save(PcSpecs specs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(specs.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
