import 'package:flutter/material.dart';

// Colors used inside legal content (shared with owning screens).
const _accent = Color(0xFF29ABE2);
const _body = Colors.white70;

/// The Privacy Policy body — reused by [PrivacyPolicyScreen] AND stacked
/// inside the onboarding [TermsScreen].
class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading('Data stored on this device'),
        _Paragraph(
          'PICARE stores your PC specs, upgrade selections, maintenance '
          'reminders, and pairing credentials locally on this device only. '
          'Nothing is uploaded to our servers.',
        ),
        SizedBox(height: 14),
        _Heading('PC companion communication'),
        _Paragraph(
          'When you pair with a PC running the companion app, all '
          'communication happens over your local network only. Requests '
          'include a 6-digit PIN and a per-device identifier so the PC '
          'owner can revoke this device individually at any time.',
        ),
        SizedBox(height: 14),
        _Heading('YouTube guides'),
        _Paragraph(
          'Video results in the Guides tab are fetched from the YouTube '
          'Data API. Only the search query (based on the guide you tap) '
          'leaves the device. No account information is sent.',
        ),
        SizedBox(height: 14),
        _Heading('Notifications'),
        _Paragraph(
          'Maintenance reminders are scheduled locally on this device. '
          'No push notification service is involved.',
        ),
        SizedBox(height: 14),
        _Heading('No third-party trackers'),
        _Paragraph(
          'PICARE does not include analytics SDKs, advertising, or '
          'third-party trackers.',
        ),
        SizedBox(height: 14),
        _Heading('Your control'),
        _Paragraph(
          'You can disconnect from your PC at any time from Settings, '
          'and clear all app data by uninstalling PICARE.',
        ),
      ],
    );
  }
}

/// The Terms of Service body — reused by [TermsOfServiceScreen] AND stacked
/// inside the onboarding [TermsScreen].
class TermsOfServiceContent extends StatelessWidget {
  const TermsOfServiceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading('About PICARE'),
        _Paragraph(
          'PICARE is a companion app that lets you monitor and control '
          'a Windows PC you own from your phone. Full functionality '
          'requires the PICARE Companion desktop application to be '
          'running on that PC.',
        ),
        SizedBox(height: 14),
        _Heading('Your responsibility'),
        _Paragraph(
          'Only pair with PCs you own and control. Keep the pairing PIN '
          'private — anyone with the PIN can issue commands to your PC '
          '(shutdown, restart, sleep, clear cache).',
        ),
        SizedBox(height: 14),
        _Heading('Power commands and data safety'),
        _Paragraph(
          'Shutdown, restart, and sleep commands are issued with a small '
          'delay to allow cancellation, but they can still interrupt work '
          'in progress. Save your files before triggering these actions.',
        ),
        SizedBox(height: 14),
        _Heading('No warranty'),
        _Paragraph(
          'PICARE is provided "as is" without warranty of any kind. '
          'The authors are not liable for data loss, hardware issues, '
          'or any damages resulting from use of the app.',
        ),
        SizedBox(height: 14),
        _Heading('Age requirement'),
        _Paragraph(
          'You must be at least 13 years old to use PICARE.',
        ),
        SizedBox(height: 14),
        _Heading('Changes to these terms'),
        _Paragraph(
          'These terms may be updated in future versions of the app. '
          'Continued use after an update constitutes acceptance of the '
          'revised terms.',
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _accent,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: _body,
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
