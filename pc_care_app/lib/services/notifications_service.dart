import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// Thin wrapper around `flutter_local_notifications` for scheduling
/// maintenance reminders. Initialize once in `main()`, then schedule
/// or cancel from anywhere.
class NotificationsService {
  NotificationsService._();
  static final instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const String _channelId = 'pc_care_reminders';
  static const String _channelName = 'Maintenance Reminders';
  static const String _channelDescription =
      'Scheduled reminders for PC maintenance (clear cache, defrag, updates, etc.)';

  Future<void> init() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    // We don't have device timezone detection; use 'UTC' as a safe fallback.
    // For the FYP scope this is fine — schedules drift by at most the local
    // offset, which is acceptable for periodic reminders.
    try {
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {/* ignore */}

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init);
    _ready = true;
  }

  /// Ask the OS for runtime notification permission. Safe to call multiple times.
  Future<bool> requestPermission() async {
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? true;
    }
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> scheduleReminder(Reminder r) async {
    await init();
    await _plugin.cancel(r.notificationId);
    if (!r.enabled) return;

    final next = _nextOccurrence(r);
    final scheduled = tz.TZDateTime.from(next, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    DateTimeComponents? matchComponents;
    switch (r.frequency) {
      case ReminderFrequency.daily:
        matchComponents = DateTimeComponents.time;
        break;
      case ReminderFrequency.weekly:
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case ReminderFrequency.monthly:
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case ReminderFrequency.quarterly:
        // No native quarterly repeat; we schedule the next single occurrence
        // and re-schedule on app launch (see [rescheduleAll]).
        matchComponents = null;
        break;
    }

    try {
      await _plugin.zonedSchedule(
        r.notificationId,
        r.title,
        _bodyFor(r),
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e, st) {
      debugPrint('NotificationsService.scheduleReminder failed: $e\n$st');
    }
  }

  Future<void> cancelReminder(Reminder r) async {
    await init();
    await _plugin.cancel(r.notificationId);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Re-schedules every enabled reminder. Call on app launch and after
  /// any change to the reminder list.
  Future<void> rescheduleAll(List<Reminder> reminders) async {
    await init();
    await _plugin.cancelAll();
    for (final r in reminders) {
      if (r.enabled) {
        await scheduleReminder(r);
      }
    }
  }

  /// Next concrete DateTime this reminder should fire at, given its
  /// frequency and time-of-day. Strictly in the future.
  DateTime _nextOccurrence(Reminder r) {
    final now = DateTime.now();
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      r.timeOfDay.hour,
      r.timeOfDay.minute,
    );
    switch (r.frequency) {
      case ReminderFrequency.daily:
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
      case ReminderFrequency.weekly:
        // Fire on the same weekday as today; if already past today, +7 days.
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        return candidate;
      case ReminderFrequency.monthly:
        if (!candidate.isAfter(now)) {
          candidate = DateTime(
            now.year,
            now.month + 1,
            now.day,
            r.timeOfDay.hour,
            r.timeOfDay.minute,
          );
        }
        return candidate;
      case ReminderFrequency.quarterly:
        if (!candidate.isAfter(now)) {
          candidate = DateTime(
            now.year,
            now.month + 3,
            now.day,
            r.timeOfDay.hour,
            r.timeOfDay.minute,
          );
        }
        return candidate;
    }
  }

  String _bodyFor(Reminder r) {
    switch (r.frequency) {
      case ReminderFrequency.daily:
        return 'Daily maintenance reminder';
      case ReminderFrequency.weekly:
        return 'Weekly maintenance reminder';
      case ReminderFrequency.monthly:
        return 'Monthly maintenance reminder';
      case ReminderFrequency.quarterly:
        return 'Quarterly maintenance reminder';
    }
  }
}
