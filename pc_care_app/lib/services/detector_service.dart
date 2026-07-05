import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

class Detection {
  final double x;
  final double y;
  final double w;
  final double h;
  final double confidence;
  final String label;

  Detection({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.confidence,
    required this.label,
  });

  @override
  String toString() =>
      '$label ${(confidence * 100).toStringAsFixed(1)}% '
      '@ (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, '
      '${w.toStringAsFixed(2)}, ${h.toStringAsFixed(2)})';
}

class DetectorService {
  static const int inputSize = 640;
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.5;
  static const List<String> labels = ['cpu', 'gpu', 'motherboard', 'ram'];

  OrtSession? _session;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    if (_isLoaded) return;

    OrtEnv.instance.init();

    final rawAsset = await rootBundle.load(
      'assets/models/motherboard_detector.onnx',
    );
    final bytes = rawAsset.buffer.asUint8List();

    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);
    _isLoaded = true;
  }

  Future<List<Detection>> detect(img.Image image) async {
    final session = _session;
    if (session == null || !_isLoaded) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    final input = _imageToFloat32List(resized);

    final inputTensor = OrtValueTensor.createTensorWithDataList(
      input,
      [1, 3, inputSize, inputSize],
    );

    final inputName = session.inputNames.first;
    final inputs = {inputName: inputTensor};
    final runOptions = OrtRunOptions();

    final outputs = session.run(runOptions, inputs);

    final detections = _parseOutput(outputs[0]?.value);

    inputTensor.release();
    for (final out in outputs) {
      out?.release();
    }
    runOptions.release();

    return detections;
  }

  Float32List _imageToFloat32List(img.Image image) {
    final input = Float32List(3 * inputSize * inputSize);
    final stride = inputSize * inputSize;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        final i = y * inputSize + x;
        input[i] = pixel.r / 255.0;
        input[stride + i] = pixel.g / 255.0;
        input[2 * stride + i] = pixel.b / 255.0;
      }
    }

    return input;
  }

  List<Detection> _parseOutput(dynamic raw) {
    if (raw is! List) return const [];

    final batch = raw[0];
    if (batch is! List) return const [];

    final channels = batch.length;
    if (channels < 5) return const [];

    final numDetections = (batch[0] as List).length;
    final List<Detection> candidates = [];

    for (int i = 0; i < numDetections; i++) {
      double bestConf = 0;
      int bestClass = 0;
      for (int c = 4; c < channels; c++) {
        final score = (batch[c][i] as num).toDouble();
        if (score > bestConf) {
          bestConf = score;
          bestClass = c - 4;
        }
      }

      if (bestConf < confidenceThreshold) continue;

      final cx = (batch[0][i] as num).toDouble() / inputSize;
      final cy = (batch[1][i] as num).toDouble() / inputSize;
      final w = (batch[2][i] as num).toDouble() / inputSize;
      final h = (batch[3][i] as num).toDouble() / inputSize;

      final label = bestClass < labels.length
          ? labels[bestClass]
          : 'class_$bestClass';

      candidates.add(Detection(
        x: cx,
        y: cy,
        w: w,
        h: h,
        confidence: bestConf,
        label: label,
      ));
    }

    return _nonMaxSuppression(candidates);
  }

  List<Detection> _nonMaxSuppression(List<Detection> detections) {
    if (detections.isEmpty) return detections;

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <Detection>[];
    final suppressed = List<bool>.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      kept.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (detections[i].label != detections[j].label) continue;
        if (_iou(detections[i], detections[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return kept;
  }

  double _iou(Detection a, Detection b) {
    final ax1 = a.x - a.w / 2;
    final ay1 = a.y - a.h / 2;
    final ax2 = a.x + a.w / 2;
    final ay2 = a.y + a.h / 2;

    final bx1 = b.x - b.w / 2;
    final by1 = b.y - b.h / 2;
    final bx2 = b.x + b.w / 2;
    final by2 = b.y + b.h / 2;

    final interX1 = ax1 > bx1 ? ax1 : bx1;
    final interY1 = ay1 > by1 ? ay1 : by1;
    final interX2 = ax2 < bx2 ? ax2 : bx2;
    final interY2 = ay2 < by2 ? ay2 : by2;

    if (interX2 <= interX1 || interY2 <= interY1) return 0;

    final interArea = (interX2 - interX1) * (interY2 - interY1);
    final aArea = a.w * a.h;
    final bArea = b.w * b.h;
    final union = aArea + bArea - interArea;

    return union <= 0 ? 0 : interArea / union;
  }

  void dispose() {
    _session?.release();
    _session = null;
    _isLoaded = false;
    OrtEnv.instance.release();
  }
}
