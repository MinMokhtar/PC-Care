import 'package:flutter/material.dart';

import '../widgets/notifications_dropdown.dart';
import 'ar_task_list_screen.dart';
import 'settings_screen.dart';

class GuidesHubScreen extends StatefulWidget {
  const GuidesHubScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color hintBg = Color(0xFF1A2444);
  static const Color accentBlue = Color(0xFF29ABE2);
  static const Color divider = Color(0xFF2A3550);

  @override
  State<GuidesHubScreen> createState() => _GuidesHubScreenState();
}

class _GuidesHubScreenState extends State<GuidesHubScreen> {
  final GlobalKey _bellKey = GlobalKey();
  bool _hasUnread = true;

  void _showNotifications() {
    showNotificationsDropdown(
      context: context,
      bellKey: _bellKey,
      onMarkAllRead: () => setState(() => _hasUnread = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                bellKey: _bellKey,
                hasUnread: _hasUnread,
                onBell: _showNotifications,
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              const SizedBox(height: 16),
              const _HintBanner(),
              const SizedBox(height: 20),
              _OptionCard(
                title: 'AR MODE',
                icon: Icons.camera_alt_outlined,
                description:
                    'Use our trained model to detect object and provide instructions',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const ArTaskListScreen(mode: GuideMode.ar),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _OrDivider(),
              const SizedBox(height: 18),
              _OptionCard(
                title: 'VIDEO GUIDE',
                icon: Icons.smart_display_outlined,
                description: 'Watch video tutorials related to your task',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const ArTaskListScreen(mode: GuideMode.video),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

// ---------- Header ----------

class _Header extends StatelessWidget {
  final GlobalKey bellKey;
  final bool hasUnread;
  final VoidCallback onBell;
  final VoidCallback onSettings;

  const _Header({
    required this.bellKey,
    required this.hasUnread,
    required this.onBell,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guides',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Smart guides that'll help you",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _CircleIconButton(
                key: bellKey,
                icon: Icons.notifications_outlined,
                onTap: onBell,
                showBadge: hasUnread,
              ),
              const SizedBox(width: 10),
              _CircleIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const _CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: GuidesHubScreen.iconBg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(
                  color: GuidesHubScreen.iconBg,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------- Hint banner ----------

class _HintBanner extends StatelessWidget {
  const _HintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GuidesHubScreen.hintBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: GuidesHubScreen.accentBlue.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick your option guides',
            style: TextStyle(
              color: GuidesHubScreen.accentBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pick your option method guide for instructions',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------- Option card (AR Mode / Video Guide) ----------

class _OptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GuidesHubScreen.cardBg,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: GuidesHubScreen.accentBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Icon(
                icon,
                color: const Color(0xFF8B95B5),
                size: 72,
              ),
              const SizedBox(height: 18),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Or divider ----------

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: GuidesHubScreen.divider,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: GuidesHubScreen.divider,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
