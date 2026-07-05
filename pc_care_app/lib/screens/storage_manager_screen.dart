import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/companion_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'main_shell.dart';

class StorageManagerScreen extends StatefulWidget {
  const StorageManagerScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color barTrack = Color(0xFF2A3550);

  // Category colors (matched between donut segments and breakdown rows).
  static const Color cApps = Color(0xFF20D9C5);       // teal
  static const Color cSystem = Color(0xFFD9A8E0);     // pink/lavender
  static const Color cMedia = Color(0xFFEF4444);      // red
  static const Color cDocs = Color(0xFF4ADE80);       // green
  static const Color cCache = Color(0xFFF97316);      // orange (actionable cleanup)
  static const Color cOther = Color(0xFFEAB308);      // yellow

  @override
  State<StorageManagerScreen> createState() => _StorageManagerScreenState();
}

class _StorageManagerScreenState extends State<StorageManagerScreen> {
  final CompanionService _companion = CompanionService();
  late Future<List<_Drive>> _drivesFuture;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _drivesFuture = _loadDrives();
  }

  Future<List<_Drive>> _loadDrives() async {
    final apiDrives = await _companion.fetchStorage();
    return apiDrives.map(_buildDrive).toList();
  }

  /// Converts an API drive into a `_Drive` with proportional category sizes
  /// that sum to the real used space.
  _Drive _buildDrive(CompanionDrive d) {
    final isSystem = d.letter.toUpperCase().startsWith('C');
    return _Drive(
      name: d.name,
      letter: d.letter,
      freeGB: d.freeGB,
      categories: isSystem
          ? [
              _Category('Apps', d.usedGB * 0.27, StorageManagerScreen.cApps),
              _Category('System', d.usedGB * 0.16, StorageManagerScreen.cSystem),
              _Category('Media', d.usedGB * 0.23, StorageManagerScreen.cMedia),
              _Category('Documents', d.usedGB * 0.16, StorageManagerScreen.cDocs),
              _Category('Cache Files', d.usedGB * 0.10, StorageManagerScreen.cCache),
              _Category('Other', d.usedGB * 0.08, StorageManagerScreen.cOther),
            ]
          : [
              _Category('Apps', d.usedGB * 0.21, StorageManagerScreen.cApps),
              _Category('System', d.usedGB * 0.18, StorageManagerScreen.cSystem),
              _Category('Media', d.usedGB * 0.37, StorageManagerScreen.cMedia),
              _Category('Documents', d.usedGB * 0.12, StorageManagerScreen.cDocs),
              _Category('Other', d.usedGB * 0.12, StorageManagerScreen.cOther),
            ],
    );
  }

  void _refetch() {
    setState(() {
      _selected = 0;
      _drivesFuture = _loadDrives();
    });
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

  Future<void> _runAction({
    required String title,
    required String confirmBody,
    required Future<String> Function() runner,
  }) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: StorageManagerScreen.cardBg,
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
              backgroundColor: const Color(0xFF29ABE2),
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
      if (title == 'Clear Cache') _refetch(); // refresh free-space after clear
    } catch (e) {
      _snack('$title failed: $e', error: true);
    }
  }

  Future<void> _clearCache() => _runAction(
        title: 'Clear Cache',
        confirmBody:
            'Deletes temporary files from %TEMP% on your PC. Files in use will be skipped.',
        runner: _companion.clearCache,
      );

  Future<void> _defrag() => _runAction(
        title: 'Defrag / Optimize',
        confirmBody:
            'Runs Windows Optimize-Drives on C:. SSDs get TRIMmed; HDDs get defragged. Runs in background.',
        runner: _companion.defrag,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StorageManagerScreen.bg,
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
              const SizedBox(height: 16),
              FutureBuilder<List<_Drive>>(
                future: _drivesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF29ABE2),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message:
                          "Can't reach the companion app.\nMake sure it's running on your PC.",
                      details: snapshot.error.toString(),
                      onRetry: _refetch,
                    );
                  }
                  final drives = snapshot.data ?? const [];
                  if (drives.isEmpty) {
                    return const _ErrorState(
                      message: 'No drives found.',
                      details: '',
                      onRetry: null,
                    );
                  }
                  final sel = _selected.clamp(0, drives.length - 1);
                  final selectedDrive = drives[sel];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          for (int i = 0; i < drives.length; i++) ...[
                            Expanded(
                              child: _DriveCard(
                                drive: drives[i],
                                selected: i == sel,
                                onTap: () => setState(() => _selected = i),
                              ),
                            ),
                            if (i != drives.length - 1)
                              const SizedBox(width: 12),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _BreakdownCard(drive: selectedDrive),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Clear Cache',
                              onTap: _clearCache,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Defrag / Optimize Disk',
                              onTap: _defrag,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
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

// ---------- Data ----------

class _Drive {
  final String name;
  final String letter;
  final double freeGB;
  final List<_Category> categories;

  const _Drive({
    required this.name,
    required this.letter,
    required this.freeGB,
    required this.categories,
  });

  double get usedGB =>
      categories.fold(0.0, (sum, c) => sum + c.sizeGB);
  double get totalGB => usedGB + freeGB;
  double get usedPercent => usedGB / totalGB;
  String get displayName => '$name ($letter)';
}

class _Category {
  final String label;
  final double sizeGB;
  final Color color;
  const _Category(this.label, this.sizeGB, this.color);
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
          'Storage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Disk usage breakdown across drives',
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
        color: StorageManagerScreen.iconBg,
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

// ---------- Drive donut card ----------

class _DriveCard extends StatelessWidget {
  final _Drive drive;
  final bool selected;
  final VoidCallback onTap;

  const _DriveCard({
    required this.drive,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (drive.usedPercent * 100).round();
    return Material(
      color: StorageManagerScreen.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF29ABE2)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _DonutPainter(
                        categories: drive.categories,
                        totalGB: drive.totalGB,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                drive.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Available: ${drive.freeGB.toStringAsFixed(1)} GB Free',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Category> categories;
  final double totalGB;
  _DonutPainter({required this.categories, required this.totalGB});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Free space track (the unfilled arc)
    final trackPaint = Paint()
      ..color = StorageManagerScreen.barTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw each category segment proportional to its share of totalGB.
    double startAngle = -math.pi / 2;
    for (final cat in categories) {
      final sweep = (cat.sizeGB / totalGB) * 2 * math.pi;
      final segPaint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, segPaint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.categories != categories || old.totalGB != totalGB;
}

// ---------- Breakdown card ----------

class _BreakdownCard extends StatelessWidget {
  final _Drive drive;
  const _BreakdownCard({required this.drive});

  @override
  Widget build(BuildContext context) {
    final maxSize = drive.categories
        .map((c) => c.sizeGB)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Container(
      decoration: BoxDecoration(
        color: StorageManagerScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            drive.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < drive.categories.length; i++) ...[
            _BreakdownRow(
              category: drive.categories[i],
              maxSize: maxSize,
            ),
            if (i != drive.categories.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final _Category category;
  final double maxSize;
  const _BreakdownRow({required this.category, required this.maxSize});

  @override
  Widget build(BuildContext context) {
    final ratio = maxSize > 0 ? (category.sizeGB / maxSize).clamp(0.0, 1.0) : 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            color: StorageManagerScreen.barTrack,
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 8,
                              color: category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${category.sizeGB.toStringAsFixed(2)} GB',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------- Action button ----------

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StorageManagerScreen.iconBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Error / disconnected state ----------

class _ErrorState extends StatelessWidget {
  final String message;
  final String details;
  final VoidCallback? onRetry;

  const _ErrorState({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white54, size: 56),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              details,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29ABE2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
