import 'package:flutter/material.dart';

enum ReminderFrequency {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  quarterly('Quarterly');

  const ReminderFrequency(this.label);

  final String label;

  static ReminderFrequency? fromName(String? name) {
    if (name == null) return null;
    for (final f in values) {
      if (f.name == name) return f;
    }
    return null;
  }
}

/// One scheduled maintenance reminder.
/// Stable [id] is used as the OS notification id (modulo for int range).
class Reminder {
  final String id;
  final String title;
  final ReminderFrequency frequency;
  final TimeOfDay timeOfDay;
  final bool enabled;
  final bool isPreset;

  const Reminder({
    required this.id,
    required this.title,
    required this.frequency,
    required this.timeOfDay,
    required this.enabled,
    this.isPreset = false,
  });

  Reminder copyWith({
    String? title,
    ReminderFrequency? frequency,
    TimeOfDay? timeOfDay,
    bool? enabled,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      enabled: enabled ?? this.enabled,
      isPreset: isPreset,
    );
  }

  /// Stable integer id derived from the string id (for notification scheduling).
  int get notificationId =>
      id.hashCode & 0x7fffffff; // positive int within range

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'frequency': frequency.name,
        'hour': timeOfDay.hour,
        'minute': timeOfDay.minute,
        'enabled': enabled,
        'isPreset': isPreset,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String,
        frequency: ReminderFrequency.fromName(json['frequency'] as String?) ??
            ReminderFrequency.weekly,
        timeOfDay: TimeOfDay(
          hour: (json['hour'] as int?) ?? 9,
          minute: (json['minute'] as int?) ?? 0,
        ),
        enabled: (json['enabled'] as bool?) ?? false,
        isPreset: (json['isPreset'] as bool?) ?? false,
      );
}

/// The 6 suggested presets that ship with the app.
List<Reminder> defaultPresetReminders() => const [
      Reminder(
        id: 'preset_clear_cache',
        title: 'Clear Cache',
        frequency: ReminderFrequency.weekly,
        timeOfDay: TimeOfDay(hour: 18, minute: 0),
        enabled: false,
        isPreset: true,
      ),
      Reminder(
        id: 'preset_defrag',
        title: 'Defrag / Optimize Disk',
        frequency: ReminderFrequency.monthly,
        timeOfDay: TimeOfDay(hour: 10, minute: 0),
        enabled: false,
        isPreset: true,
      ),
      Reminder(
        id: 'preset_windows_updates',
        title: 'Check Windows Updates',
        frequency: ReminderFrequency.weekly,
        timeOfDay: TimeOfDay(hour: 9, minute: 0),
        enabled: false,
        isPreset: true,
      ),
      Reminder(
        id: 'preset_antivirus_scan',
        title: 'Run Antivirus Scan',
        frequency: ReminderFrequency.weekly,
        timeOfDay: TimeOfDay(hour: 20, minute: 0),
        enabled: false,
        isPreset: true,
      ),
      Reminder(
        id: 'preset_driver_updates',
        title: 'Update Drivers',
        frequency: ReminderFrequency.monthly,
        timeOfDay: TimeOfDay(hour: 11, minute: 0),
        enabled: false,
        isPreset: true,
      ),
      Reminder(
        id: 'preset_dust_pc',
        title: 'Dust the PC',
        frequency: ReminderFrequency.quarterly,
        timeOfDay: TimeOfDay(hour: 14, minute: 0),
        enabled: false,
        isPreset: true,
      ),
    ];
