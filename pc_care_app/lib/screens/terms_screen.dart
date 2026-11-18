import 'package:flutter/material.dart';

import '../services/onboarding_prefs_service.dart';
import '../widgets/legal_content.dart';
import 'splash_screen.dart';

/// Shown after the onboarding carousel. User must tick the checkbox before
/// they can tap Continue. Saves the acknowledgement to SharedPreferences
/// then navigates into the app's normal splash → main flow.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color accent = Color(0xFF29ABE2);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreed = false;

  Future<void> _continue() async {
    if (!_agreed) return;
    await OnboardingPrefsService().setTermsAgreed();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TermsScreen.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Terms & Privacy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please review before continuing.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: TermsScreen.cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        PrivacyPolicyContent(),
                        SizedBox(height: 24),
                        Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        TermsOfServiceContent(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      _CheckboxSquare(checked: _agreed),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: _agreed ? 1 : 0.4,
                child: Material(
                  color: TermsScreen.accent,
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _agreed ? _continue : null,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxSquare extends StatelessWidget {
  final bool checked;
  const _CheckboxSquare({required this.checked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? TermsScreen.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: checked ? TermsScreen.accent : Colors.white54,
          width: 1.5,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}
