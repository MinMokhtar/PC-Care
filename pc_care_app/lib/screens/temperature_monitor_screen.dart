import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/companion_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'main_shell.dart';

class TemperatureMonitorScreen extends StatefulWidget {
  const TemperatureMonitorScreen({super.key});

  static const Color bg = Color(0xFF03091F);
  static const Color cardBg = Color(0xFF11182C);
  static const Color iconBg = Color(0xFF1E2742);
  static const Color iconBgInner = Color(0xFF2A3550);
  static const Color barTrack = Color(0xFF2A3550);

  // Status colors
  static const Color coolGreen = Color(0xFF22C55E);
  static const Color warmYellow = Color(0xFFEAB308);
  static const Color hotRed = Color(0xFFEF4444);

  @override
  State<TemperatureMonitorScreen> createState() =>
      _TemperatureMonitorScreenState();
}

class _TemperatureMonitorScreenState extends State<TemperatureMonitorScreen> {
  final CompanionService _companion = CompanionService();
  CompanionTemps? _temps;
  String? _error;
  bool _initialLoad = true;
  Timer? _pollTimer;
  final List<double> _history = [];

  static const Duration _pollInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _fetchOnce();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchOnce());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOnce() async {
    try {
      final t = await _companion.fetchTemps();
      if (!mounted) return;
      setState(() {
        _temps = t;
        _error = null;
        _initialLoad = false;
        final overall = _overallOf(t);
        if (overall != null) {
          if (_history.length >= 13) _history.removeAt(0);
          _history.add(overall.toDouble());
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initialLoad = false;
      });
    }
  }

  int? _overallOf(CompanionTemps t) {
    final vals = [t.cpu, t.gpu, t.motherboard, t.storage]
        .whereType<int>()
        .toList();
    if (vals.isEmpty) return null;
    return (vals.reduce((a, b) => a + b) / vals.length).round();
  }

  List<_ComponentTemp> _componentsFrom(CompanionTemps t) => [
        _ComponentTemp(
          icon: Icons.memory,
          title: 'Processor (CPU)',
          tempC: t.cpu,
          minC: 30,
          maxC: 100,
        ),
        _ComponentTemp(
          icon: Icons.videogame_asset_outlined,
          title: 'Graphics Card (GPU)',
          tempC: t.gpu,
          minC: 30,
          maxC: 95,
        ),
        _ComponentTemp(
          icon: Icons.developer_board,
          title: 'Motherboard',
          tempC: t.motherboard,
          minC: 30,
          maxC: 80,
        ),
        _ComponentTemp(
          icon: Icons.sd_storage_outlined,
          title: 'Storage (SSD)',
          tempC: t.storage,
          minC: 30,
          maxC: 70,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemperatureMonitorScreen.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(),
              const SizedBox(height: 12),
              _BackPill(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              if (_initialLoad)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF29ABE2),
                    ),
                  ),
                )
              else if (_temps == null)
                _ErrorState(
                  message:
                      "Can't reach the companion app.\nMake sure it's running on your PC.",
                  details: _error ?? '',
                  onRetry: _fetchOnce,
                )
              else ...[
                _OverallCard(
                  tempC: _overallOf(_temps!),
                  history: _history,
                ),
                const SizedBox(height: 14),
                for (final c in _componentsFrom(_temps!)) ...[
                  _ComponentCard(data: c),
                  const SizedBox(height: 12),
                ],
              ],
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

// ---------- Data model ----------

class _ComponentTemp {
  final IconData icon;
  final String title;
  final int? tempC;
  final int minC;
  final int maxC;

  const _ComponentTemp({
    required this.icon,
    required this.title,
    required this.tempC,
    required this.minC,
    required this.maxC,
  });
}

// ---------- Status logic ----------

enum _TempStatus { cool, warm, hot }

_TempStatus _statusFor(int tempC) {
  if (tempC < 50) return _TempStatus.cool;
  if (tempC < 65) return _TempStatus.warm;
  return _TempStatus.hot;
}

String _statusLabel(_TempStatus s) {
  switch (s) {
    case _TempStatus.cool:
      return 'Cool';
    case _TempStatus.warm:
      return 'Warm';
    case _TempStatus.hot:
      return 'Hot';
  }
}

Color _statusColor(_TempStatus s) {
  switch (s) {
    case _TempStatus.cool:
      return TemperatureMonitorScreen.coolGreen;
    case _TempStatus.warm:
      return TemperatureMonitorScreen.warmYellow;
    case _TempStatus.hot:
      return TemperatureMonitorScreen.hotRed;
  }
}

// ---------- Header ----------

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temperatures',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Real-time component thermal readings',
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
        color: TemperatureMonitorScreen.iconBg,
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

// ---------- Overall card (arc + chart) ----------

class _OverallCard extends StatelessWidget {
  final int? tempC;
  final List<double> history;

  const _OverallCard({required this.tempC, required this.history});

  @override
  Widget build(BuildContext context) {
    final hasTemp = tempC != null;
    final status = hasTemp ? _statusFor(tempC!) : null;
    final color = status != null ? _statusColor(status) : Colors.white38;
    return Container(
      decoration: BoxDecoration(
        color: TemperatureMonitorScreen.cardBg,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _ArcPainter(
                    progress: hasTemp ? (tempC!.clamp(0, 100)) / 100 : 0.0,
                    color: color,
                  ),
                ),
                Text(
                  hasTemp ? '${tempC!}C' : '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Overall Temperature',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.thermostat_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: CustomPaint(
                    painter: _ChartPainter(
                      values: history,
                      currentTempC: tempC ?? 0,
                      lineColor: color,
                    ),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Component card ----------

class _ComponentCard extends StatelessWidget {
  final _ComponentTemp data;

  const _ComponentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasTemp = data.tempC != null;
    final status = hasTemp ? _statusFor(data.tempC!) : null;
    final statusColor =
        status != null ? _statusColor(status) : Colors.white38;
    final progress = hasTemp
        ? ((data.tempC! - data.minC) / (data.maxC - data.minC)).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: TemperatureMonitorScreen.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TemperatureMonitorScreen.iconBgInner,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: Colors.white70, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                hasTemp ? _statusLabel(status!) : 'N/A',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasTemp ? '${data.tempC}' : '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 2),
                child: Text(
                  '°C',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Min: ${data.minC}c  Max: ${data.maxC}c',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RangeBar(progress: progress, color: statusColor),
        ],
      ),
    );
  }
}

class _RangeBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _RangeBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (_, c) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: TemperatureMonitorScreen.barTrack,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------- CustomPainters ----------

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
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

    final progPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress.clamp(0.0, 1.0),
      false,
      progPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

/// Tiny line-chart painter: grid lines (Y at 0/20/40/60/80/100) +
/// a smooth wavy curve through [values] + a labeled marker at the end.
class _ChartPainter extends CustomPainter {
  final List<double> values;
  final int currentTempC;
  final Color lineColor;

  _ChartPainter({
    required this.values,
    required this.currentTempC,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double yMax = 100;
    const double xPad = 6;
    const double rightPad = 36;
    const double yPad = 8;

    final chartRect = Rect.fromLTWH(
      xPad,
      yPad,
      size.width - xPad - rightPad,
      size.height - yPad * 2,
    );

    // Grid lines (faint) + Y labels (left).
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    final textStyle = const TextStyle(color: Colors.white38, fontSize: 8);
    const ticks = [0, 20, 40, 60, 80, 100];
    for (final t in ticks) {
      final y = chartRect.bottom - (t / yMax) * chartRect.height;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: '$t', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    if (values.isEmpty) return;

    // Build smooth path through the points.
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = chartRect.left +
          (values.length == 1
              ? chartRect.width / 2
              : (i / (values.length - 1)) * chartRect.width);
      final y = chartRect.bottom - (values[i] / yMax) * chartRect.height;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Optional soft fill under the line.
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartRect.bottom)
      ..lineTo(points.first.dx, chartRect.bottom)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withOpacity(0.20),
          lineColor.withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    // Line stroke.
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Endpoint dot.
    final endPoint = points.last;
    canvas.drawCircle(
      endPoint,
      3,
      Paint()..color = lineColor,
    );

    // Current temp label at the right.
    final labelText = '$currentTempC°C';
    final labelTp = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: lineColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(
      canvas,
      Offset(endPoint.dx + 6, endPoint.dy - labelTp.height / 2),
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.values != values ||
      old.currentTempC != currentTempC ||
      old.lineColor != lineColor;
}

// ---------- Error / disconnected state ----------

class _ErrorState extends StatelessWidget {
  final String message;
  final String details;
  final VoidCallback onRetry;

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
      ),
    );
  }
}
