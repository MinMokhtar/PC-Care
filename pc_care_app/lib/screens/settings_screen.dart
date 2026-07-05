import 'package:flutter/material.dart';

import '../config/companion_config.dart';
import '../services/app_mode_service.dart';
import '../services/companion_service.dart';
import '../services/notifications_service.dart';
import '../services/reminders_service.dart';
import '../services/settings_prefs_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'connect_pc_screen.dart';
import 'main_shell.dart';
import 'notification_reminder_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color divider = Color(0xFF1E2742);
  static const Color accentBlue = Color(0xFF29ABE2);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsPrefsService _prefs = SettingsPrefsService();
  bool _darkMode = true;
  bool _notifications = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dark = await _prefs.loadDarkMode();
    final notif = await _prefs.loadNotifications();
    if (!mounted) return;
    setState(() {
      _darkMode = dark;
      _notifications = notif;
      _loaded = true;
    });
  }

  void _toggleDark(bool v) {
    // Locked ON for now — light mode requires a full theme rebuild.
    setState(() => _darkMode = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Light mode coming soon'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleNotifications(bool v) async {
    setState(() => _notifications = v);
    await _prefs.saveNotifications(v);
    if (v) {
      await NotificationsService.instance.requestPermission();
      final reminders = await RemindersService().load();
      await NotificationsService.instance.rescheduleAll(reminders);
    } else {
      await NotificationsService.instance.cancelAll();
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SettingsScreen.cardBg,
        title: const Text('Disconnect from PC?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "You'll need to pair again with your PC's PIN to reconnect.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    // Best-effort tell the PC to remove this device from its tracked list.
    // Done BEFORE wiping credentials so headers are still valid.
    await CompanionService().forgetMe();
    await CompanionConfig.clear();
    await AppModeService().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ConnectPcScreen()),
      (route) => false,
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SettingsScreen.cardBg,
        title: const Text('About PC Care',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'PC Care v1.0.0\n\nYour all-in-one PC maintenance companion.\n\nDeveloped as a Final Year Project.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close',
                style: TextStyle(color: SettingsScreen.accentBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsScreen.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Customize your experience.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (_loaded)
                _SettingsCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFFA78BFA),
                      iconBg: const Color(0xFF2E1F4D),
                      title: 'Dark Mode',
                      subtitle: 'Light mode coming soon',
                      value: _darkMode,
                      onChanged: _toggleDark,
                    ),
                    const _CardDivider(),
                    _ToggleRow(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFF60A5FA),
                      iconBg: const Color(0xFF1E2E4F),
                      title: 'Notifications',
                      subtitle: 'Maintenance reminders',
                      value: _notifications,
                      onChanged: _toggleNotifications,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _ChevronRow(
                    icon: Icons.alarm,
                    iconColor: const Color(0xFF60A5FA),
                    iconBg: const Color(0xFF1E2E4F),
                    title: 'Reminders',
                    subtitle: 'Manage maintenance reminders',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationReminderScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _ChevronRow(
                    icon: Icons.link_off,
                    iconColor: const Color(0xFFEF4444),
                    iconBg: const Color(0xFF3F1F23),
                    title: 'Disconnect from PC',
                    subtitle: CompanionConfig.host.isEmpty
                        ? 'Not connected'
                        : 'Connected to ${CompanionConfig.host}',
                    onTap: _disconnect,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                children: [
                  _ChevronRow(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF60A5FA),
                    iconBg: const Color(0xFF1E2E4F),
                    title: 'About App',
                    subtitle: 'Version 1.0.0',
                    onTap: _showAbout,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        activeTab: null,
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SettingsScreen.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: SettingsScreen.divider,
        height: 1,
        thickness: 1,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          _IconBubble(icon: icon, color: iconColor, bg: iconBg),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: SettingsScreen.accentBlue,
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: const Color(0xFF2E3650),
          ),
        ],
      ),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChevronRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              _IconBubble(icon: icon, color: iconColor, bg: iconBg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
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

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;

  const _IconBubble({required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
