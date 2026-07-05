import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../screens/component_picker_screen.dart';

class UpgradePlanService {
  static const String _key = 'upgrade_plan';

  Future<Map<UpgradeCategory, ComponentSelection>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final result = <UpgradeCategory, ComponentSelection>{};
      for (final entry in json.entries) {
        final cat = _categoryFromName(entry.key);
        if (cat == null) continue;
        final value = entry.value;
        if (value is! Map) continue;
        result[cat] =
            ComponentSelection.fromJson(Map<String, dynamic>.from(value));
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<UpgradeCategory, ComponentSelection> plan) async {
    final prefs = await SharedPreferences.getInstance();
    final json = <String, dynamic>{
      for (final entry in plan.entries) entry.key.name: entry.value.toJson(),
    };
    await prefs.setString(_key, jsonEncode(json));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  UpgradeCategory? _categoryFromName(String name) {
    for (final c in UpgradeCategory.values) {
      if (c.name == name) return c;
    }
    return null;
  }
}
