import 'package:flutter/material.dart';

import '../services/detector_service.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;

  BoundingBoxPainter({required this.detections});

  static const Map<String, Color> _colors = {
    'motherboard': Colors.lightGreenAccent,
    'cpu': Colors.cyanAccent,
    'ram': Colors.pinkAccent,
    'gpu': Colors.orangeAccent,
  };

  static Color colorFor(String label) =>
      _colors[label] ?? Colors.lightGreenAccent;

  @override
  void paint(Canvas canvas, Size size) {
    for (final det in detections) {
      final color = colorFor(det.label);

      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final labelBackground = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final left = (det.x - det.w / 2) * size.width;
      final top = (det.y - det.h / 2) * size.height;
      final width = det.w * size.width;
      final height = det.h * size.height;

      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, boxPaint);

      final labelText =
          '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        left,
        top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(labelRect, labelBackground);
      textPainter.paint(canvas, Offset(left + 4, top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) =>
      oldDelegate.detections != detections;
}
