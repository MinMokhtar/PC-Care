import 'package:flutter/material.dart';

import 'config/companion_config.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/terms_screen.dart';
import 'services/notifications_service.dart';
import 'services/onboarding_prefs_service.dart';
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

  // First-launch gating: pick the entry screen based on stored flags.
  final onboardingPrefs = OnboardingPrefsService();
  final onboardingDone = await onboardingPrefs.isOnboardingDone();
  final termsAgreed = await onboardingPrefs.isTermsAgreed();

  final Widget entry;
  if (!onboardingDone) {
    entry = const OnboardingScreen();
  } else if (!termsAgreed) {
    entry = const TermsScreen();
  } else {
    entry = const SplashScreen();
  }

  runApp(PcCareApp(entry: entry));
}

class PcCareApp extends StatelessWidget {
  final Widget entry;
  const PcCareApp({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PICARE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF29ABE2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: entry,
    );
  }
}
