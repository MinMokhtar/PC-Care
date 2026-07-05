import 'package:flutter/material.dart';

import '../data/instructions.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/notifications_dropdown.dart';
import 'guided_detection_screen.dart';
import 'main_shell.dart';
import 'settings_screen.dart';
import 'youtube_video_list_screen.dart';

enum GuideMode { ar, video }

class ArTaskListScreen extends StatefulWidget {
  final GuideMode mode;

  const ArTaskListScreen({super.key, this.mode = GuideMode.ar});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color iconBgInner = Color(0xFF2A3550);
  static const Color hintBg = Color(0xFF1A2444);
  static const Color accentBlue = Color(0xFF29ABE2);

  @override
  State<ArTaskListScreen> createState() => _ArTaskListScreenState();
}

class _ArTaskListScreenState extends State<ArTaskListScreen> {
  final GlobalKey _bellKey = GlobalKey();
  bool _hasUnread = true;

  void _showNotifications() {
    showNotificationsDropdown(
      context: context,
      bellKey: _bellKey,
      onMarkAllRead: () => setState(() => _hasUnread = false),
    );
  }

  void _openTask(MaintenanceGuide guide) {
    if (widget.mode == GuideMode.ar) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GuidedDetectionScreen(guide: guide),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => YoutubeVideoListScreen(guide: guide),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final installation = motherboardGuides
        .where((g) => g.category == GuideCategory.installation)
        .toList();

    return Scaffold(
      backgroundColor: ArTaskListScreen.bg,
      extendBody: true,
      body: SafeArea(
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
              const SizedBox(height: 22),
              const _SectionHeader(label: 'INSTALLATION'),
              const SizedBox(height: 12),
              for (final g in installation) ...[
                _TaskCard(guide: g, onTap: () => _openTask(g)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: AppTab.guides,
        onHome: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.home);
        },
        onGuides: () => Navigator.of(context).pop(),
        onUpgrades: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.upgrades);
        },
      ),
    );
  }
}

// ---------- Header (title + subtitle + bell + settings) ----------

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
          color: ArTaskListScreen.iconBg,
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
                  color: ArTaskListScreen.iconBg,
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
        color: ArTaskListScreen.hintBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ArTaskListScreen.accentBlue.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want to do?',
            style: TextStyle(
              color: ArTaskListScreen.accentBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Pick a task. The guide will provide instructions and walk you through each step.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---------- Section header ----------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.build_outlined,
          color: ArTaskListScreen.accentBlue,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: ArTaskListScreen.accentBlue,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

// ---------- Task card ----------

class _TaskCard extends StatelessWidget {
  final MaintenanceGuide guide;
  final VoidCallback onTap;

  const _TaskCard({required this.guide, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArTaskListScreen.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ArTaskListScreen.iconBgInner,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(guide.icon, color: Colors.white70, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guide.shortDescription,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: ArTaskListScreen.iconBgInner,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text(
                        '${guide.steps.length} Steps',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
