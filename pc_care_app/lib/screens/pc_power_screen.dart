import 'dart:async';

import 'package:flutter/material.dart';

import '../config/companion_config.dart';
import '../services/companion_service.dart';
import '../services/wol_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'main_shell.dart';

class PcPowerScreen extends StatefulWidget {
  const PcPowerScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);

  // Action accent colors
  static const Color wakeGreen = Color(0xFF22C55E);
  static const Color sleepYellow = Color(0xFFEAB308);
  static const Color restartBlue = Color(0xFF29ABE2);
  static const Color shutdownRed = Color(0xFFEF4444);

  @override
  State<PcPowerScreen> createState() => _PcPowerScreenState();
}

class _PcPowerScreenState extends State<PcPowerScreen> {
  final CompanionService _companion = CompanionService();
  final WolService _wol = WolService();
  bool _online = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _poll();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _poll(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final online = await _companion.ping();
    if (!mounted) return;
    setState(() => _online = online);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: error
            ? const Color(0xFFEF4444)
            : const Color(0xFF1E2742),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _runPowerAction({
    required String action,
    required String confirmTitle,
    required String confirmBody,
    required Color accent,
    required Future<void> Function() runner,
    required String successMsg,
  }) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: confirmTitle,
        body: confirmBody,
        accent: accent,
        confirmLabel: action,
      ),
    );
    if (go != true) return;
    try {
      await runner();
      _snack(successMsg);
    } catch (e) {
      _snack('Failed: $e', error: true);
    }
  }

  Future<void> _wake() async {
    if (CompanionConfig.mac.isEmpty) {
      _snack(
        "Can't wake — MAC address unknown. Re-pair to your PC while it's on.",
        error: true,
      );
      return;
    }
    try {
      await _wol.wake(CompanionConfig.mac);
      _snack('Wake packet sent to ${CompanionConfig.mac}');
    } catch (e) {
      _snack('Wake failed: $e', error: true);
    }
  }

  Future<void> _shutdown() => _runPowerAction(
        action: 'Shutdown',
        confirmTitle: 'Shut down PC?',
        confirmBody: "PC will power off in 5 seconds. You can cancel from the PC if needed (`shutdown /a`).",
        accent: PcPowerScreen.shutdownRed,
        runner: _companion.shutdown,
        successMsg: 'Shutdown command sent',
      );

  Future<void> _restart() => _runPowerAction(
        action: 'Restart',
        confirmTitle: 'Restart PC?',
        confirmBody: 'PC will restart in 5 seconds.',
        accent: PcPowerScreen.restartBlue,
        runner: _companion.restart,
        successMsg: 'Restart command sent',
      );

  Future<void> _sleep() => _runPowerAction(
        action: 'Sleep',
        confirmTitle: 'Put PC to sleep?',
        confirmBody: 'PC will enter sleep mode.',
        accent: PcPowerScreen.sleepYellow,
        runner: _companion.sleep,
        successMsg: 'Sleep command sent',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PcPowerScreen.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: 12),
              _BackPill(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 18),
              _StatusCard(online: _online),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _PowerAction(
                      icon: Icons.bedtime_outlined,
                      label: 'Sleep',
                      color: PcPowerScreen.sleepYellow,
                      enabled: _online,
                      onTap: _sleep,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PowerAction(
                      icon: Icons.refresh,
                      label: 'Restart',
                      color: PcPowerScreen.restartBlue,
                      enabled: _online,
                      onTap: _restart,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PowerAction(
                      icon: Icons.flash_on,
                      label: 'Wake',
                      color: PcPowerScreen.wakeGreen,
                      enabled: !_online,
                      onTap: _wake,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _PowerAction(
                      icon: Icons.power_settings_new,
                      label: 'Shutdown',
                      color: PcPowerScreen.shutdownRed,
                      enabled: _online,
                      onTap: _shutdown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _Footnote(),
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

// ---------- Header ----------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PC Power',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Remote control over your PC',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }
}

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: PcPowerScreen.iconBg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Status card ----------

class _StatusCard extends StatelessWidget {
  final bool online;
  const _StatusCard({required this.online});

  @override
  Widget build(BuildContext context) {
    final dotColor = online
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);
    return Container(
      decoration: BoxDecoration(
        color: PcPowerScreen.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: PcPowerScreen.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.desktop_windows_outlined,
              color: Colors.white70,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CompanionConfig.host.isEmpty
                      ? 'No PC connected'
                      : 'My PC',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      online ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Power action card ----------

class _PowerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _PowerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: PcPowerScreen.cardBg,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        'Wake requires Wake-on-LAN enabled in BIOS + network adapter.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38, fontSize: 11),
      ),
    );
  }
}

// ---------- Confirm dialog ----------

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final Color accent;

  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PcPowerScreen.cardBg,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(body, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
