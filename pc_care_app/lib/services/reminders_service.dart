import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder.dart';

/// Persistence layer for the user's reminder list (presets + custom).
/// First-run loads the 6 default presets (all disabled).
class RemindersService {
  static const String _key = 'reminders_list';
  static const String _seededKey = 'reminders_seeded';

  Future<List<Reminder>> load() async {
    final prefs = await SharedPreferences.getInstance();

    // First-run seeding: write the 6 presets so they show up disabled.
    final seeded = prefs.getBool(_seededKey) ?? false;
    if (!seeded) {
      final presets = defaultPresetReminders();
      await _writeList(prefs, presets);
      await prefs.setBool(_seededKey, true);
      return presets;
    }

    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return defaultPresetReminders();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return defaultPresetReminders();
    }
  }

  Future<void> saveAll(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeList(prefs, reminders);
  }

  Future<void> _writeList(
      SharedPreferences prefs, List<Reminder> reminders) async {
    final raw = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
