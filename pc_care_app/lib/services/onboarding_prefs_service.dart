import 'package:shared_preferences/shared_preferences.dart';

/// Tracks first-launch state: has the user seen the onboarding carousel
/// yet, and have they agreed to Terms & Privacy.
class OnboardingPrefsService {
  static const String _onboardingKey = 'onboarding_done';
  static const String _termsKey = 'terms_agreed';

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<bool> isTermsAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsKey) ?? false;
  }

  Future<void> setTermsAgreed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsKey, true);
  }
}
