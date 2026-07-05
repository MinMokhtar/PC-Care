import 'package:flutter/material.dart';

import 'config/companion_config.dart';
import 'screens/splash_screen.dart';
import 'services/notifications_service.dart';
import 'services/reminders_service.dart';
import 'services/settings_prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CompanionConfig.loadFromPrefs();
  await NotificationsService.instance.init();
  // Re-schedule reminders only if global Notifications toggle is on.
  final globalOn = await SettingsPrefsService().loadNotifications();
  if (globalOn) {
    final reminders = await RemindersService().load();
    await NotificationsService.instance.rescheduleAll(reminders);
  } else {
    await NotificationsService.instance.cancelAll();
  }
  runApp(const PcCareApp());
}

class PcCareApp extends StatelessWidget {
  const PcCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF29ABE2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
