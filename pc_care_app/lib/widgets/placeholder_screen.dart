import 'package:flutter/material.dart';

import '../screens/main_shell.dart';
import 'app_bottom_nav.dart';

/// Generic dark-themed placeholder for screens we haven't designed yet.
/// Used by Temperature Monitor, Storage Manager, Notification Reminder,
/// PC Power, and YouTube Tutorial.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final AppTab? activeTab;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    this.activeTab,
  });

  static const Color bg = Color(0xFF03091F);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color soonGreen = Color(0xFF22C55E);
  static const Color soonBg = Color(0xFF13322A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Material(
                    color: iconBg,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(icon, color: Colors.white70, size: 48),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: soonBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: soonGreen.withOpacity(0.5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Text(
                          'Coming soon',
                          style: TextStyle(
                            color: soonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: activeTab,
        onHome: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.home);
        },
        onGuides: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.guides);
        },
        onUpgrades: () {
          Navigator.of(context).popUntil((r) => r.isFirst);
          MainShellState.switchTab(AppTab.upgrades);
        },
      ),
    );
  }
}
