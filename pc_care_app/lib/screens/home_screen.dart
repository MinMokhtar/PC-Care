import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/companion_config.dart';
import '../services/app_mode_service.dart';
import '../services/companion_service.dart';
import '../widgets/notifications_dropdown.dart';
import 'connect_pc_screen.dart';
import 'pc_power_screen.dart';
import 'settings_screen.dart';
import 'storage_manager_screen.dart';
import 'temperature_monitor_screen.dart';

/// Whole-PC connectivity state shown on the Home screen.
enum PcStatus { offline, startingUp, online, sleeping }

extension PcStatusUi on PcStatus {
  String get label {
    switch (this) {
      case PcStatus.offline:
        return 'Offline';
      case PcStatus.startingUp:
        return 'Starting up…';
      case PcStatus.online:
        return 'Online';
      case PcStatus.sleeping:
        return 'Sleeping';
    }
  }

  Color get dotColor {
    switch (this) {
      case PcStatus.offline:
        return const Color(0xFFEF4444);
      case PcStatus.startingUp:
        return const Color(0xFFEAB308);
      case PcStatus.online:
        return const Color(0xFF4ADE80);
      case PcStatus.sleeping:
        return const Color(0xFF94A3B8);
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color divider = Color(0xFF2A3550);
  static const Color accentBlue = Color(0xFF29ABE2);
  static const Color tempGreen = Color(0xFF4ADE80);
  static const Color storagePurple = Color(0xFF9B8FE3);

  // Backwards-compatible aliases for the helper widgets below.
  static const Color _bg = bg;
  static const Color _cardBg = cardBg;
  static const Color _iconBg = iconBg;
  static const Color _divider = divider;
  static const Color _accentBlue = accentBlue;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _bellKey = GlobalKey();
  final CompanionService _companion = CompanionService();
  bool _hasUnread = true;

  PcStatus _status = PcStatus.offline;
  bool get _online =>
      _status == PcStatus.online || _status == PcStatus.startingUp;
  CompanionTemps? _temps;
  List<CompanionDrive> _drives = const [];
  Timer? _pollTimer;

  static const Duration _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _poll();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final reachable = await _companion.ping();
    if (!mounted) return;

    if (!reachable) {
      // Offline — but if the user recently asked PC to Sleep, label it
      // "Sleeping" instead of just "Offline".
      setState(() {
        _status = _companion.isSleepRecentlyRequested
            ? PcStatus.sleeping
            : PcStatus.offline;
      });
      return;
    }

    // Reachable — figure out the right "up" state.
    // First time becoming reachable after being down → show "Starting up..."
    // for one poll cycle, then jump to "Online".
    final nextStatus = (_status == PcStatus.offline ||
            _status == PcStatus.sleeping)
        ? PcStatus.startingUp
        : PcStatus.online;

    try {
      final results = await Future.wait([
        _companion.fetchTemps(),
        _companion.fetchStorage(),
      ]);
      if (!mounted) return;
      setState(() {
        _status = nextStatus;
        _temps = results[0] as CompanionTemps;
        _drives = results[1] as List<CompanionDrive>;
      });
    } on CompanionRevokedException {
      // PC owner kicked us — clean up and bounce to Connect screen.
      _pollTimer?.cancel();
      await CompanionConfig.clear();
      await AppModeService().clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Disconnected by PC owner',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ConnectPcScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = PcStatus.offline);
    }
  }

  int? _overallTemp() {
    final t = _temps;
    if (t == null) return null;
    final vals = [t.cpu, t.gpu, t.motherboard, t.storage]
        .whereType<int>()
        .toList();
    if (vals.isEmpty) return null;
    return (vals.reduce((a, b) => a + b) / vals.length).round();
  }

  ({int percent, double freeGB})? _storageSummary() {
    if (_drives.isEmpty) return null;
    final total = _drives.fold<double>(0, (a, d) => a + d.totalGB);
    final free = _drives.fold<double>(0, (a, d) => a + d.freeGB);
    if (total <= 0) return null;
    final used = total - free;
    return (percent: ((used / total) * 100).round(), freeGB: free);
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _showActionSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Future<void> _runQuickAction({
    required String title,
    required String confirmBody,
    required Future<String> Function() runner,
  }) async {
    if (!_online) {
      _snack("PC is offline. Can't run $title.", error: true);
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: HomeScreen.cardBg,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(confirmBody,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HomeScreen.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Run'),
          ),
        ],
      ),
    );
    if (go != true) return;
    try {
      final msg = await runner();
      _snack(msg);
    } catch (e) {
      _snack('$title failed: $e', error: true);
    }
  }

  Future<void> _clearCache() => _runQuickAction(
        title: 'Clear Cache',
        confirmBody:
            'Deletes temporary files from %TEMP% on your PC. Files in use will be skipped.',
        runner: _companion.clearCache,
      );

  Future<void> _defrag() => _runQuickAction(
        title: 'Defrag / Optimize',
        confirmBody:
            'Runs Windows Optimize-Drives on C:. SSDs get TRIMmed; HDDs get defragged. Runs in background.',
        runner: _companion.defrag,
      );

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                bellKey: _bellKey,
                hasUnread: _hasUnread,
                onBell: _showNotifications,
                onSettings: () => _open(context, const SettingsScreen()),
              ),
              const SizedBox(height: 20),
              _PcPowerHero(
                status: _status,
                onTap: () => _open(context, const PcPowerScreen()),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Temperature',
                      value: _overallTemp() != null
                          ? '${_overallTemp()}C'
                          : '--',
                      subValue: _online ? 'Live' : 'Offline',
                      progress: _overallTemp() != null
                          ? (_overallTemp()! / 100).clamp(0.0, 1.0)
                          : 0,
                      arcColor: HomeScreen.tempGreen,
                      icon: Icons.thermostat_outlined,
                      onTap: () =>
                          _open(context, const TemperatureMonitorScreen()),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: () {
                      final s = _storageSummary();
                      return _StatCard(
                        label: 'Storage',
                        value: s != null ? '${s.percent}%' : '--',
                        subValue: s != null
                            ? '${s.freeGB.toStringAsFixed(0)}GB Free'
                            : 'Offline',
                        progress: s != null ? s.percent / 100.0 : 0,
                        arcColor: HomeScreen.storagePurple,
                        icon: Icons.storage_outlined,
                        onTap: () =>
                            _open(context, const StorageManagerScreen()),
                      );
                    }(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: HomeScreen.divider, height: 1, thickness: 1),
              const SizedBox(height: 18),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _QuickAction(
                label: 'Clear Cache',
                onTap: _clearCache,
              ),
              const SizedBox(height: 10),
              _QuickAction(
                label: 'Defrag / Optimize Disk',
                onTap: _defrag,
              ),
            ],
          ),
        ),
      );
  }
}

// ---------- Top bar ----------

class _TopBar extends StatelessWidget {
  final GlobalKey bellKey;
  final bool hasUnread;
  final VoidCallback onBell;
  final VoidCallback onSettings;

  const _TopBar({
    required this.bellKey,
    required this.hasUnread,
    required this.onBell,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _CircleIconButton(
          key: bellKey,
          icon: Icons.notifications_outlined,
          onTap: onBell,
          showBadge: hasUnread,
        ),
        const SizedBox(width: 10),
        _CircleIconButton(icon: Icons.settings_outlined, onTap: onSettings),
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
          color: HomeScreen._iconBg,
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
                border: Border.all(color: HomeScreen._iconBg, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------- Hero PC Power card ----------

class _PcPowerHero extends StatelessWidget {
  final VoidCallback onTap;
  final PcStatus status;

  const _PcPowerHero({required this.onTap, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF29ABE2).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF5BCBF0),
                        Color(0xFF3B82F6),
                        Color(0xFF1E2A78),
                      ],
                      stops: [0.0, 0.55, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.45),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'My PC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status.dotColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.power_settings_new,
                  color: Color(0xFF2D4FA8),
                  size: 36,
                ),
              ),
            ],
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

// ---------- Stat cards (Temperature / Storage) ----------

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final double progress;
  final Color arcColor;
  final IconData icon;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.progress,
    required this.arcColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeScreen._cardBg,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(icon, color: Colors.white70, size: 18),
              ),
              const SizedBox(height: 4),
              Center(
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(110, 110),
                        painter: _ArcPainter(
                          progress: progress,
                          color: arcColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subValue,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ---------- Quick Actions ----------

class _QuickAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeScreen._cardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

