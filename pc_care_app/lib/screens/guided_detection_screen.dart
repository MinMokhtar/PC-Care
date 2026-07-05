import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../data/instructions.dart';
import '../services/detector_service.dart';
import '../widgets/bounding_box_painter.dart';

class GuidedDetectionScreen extends StatefulWidget {
  final MaintenanceGuide guide;

  const GuidedDetectionScreen({super.key, required this.guide});

  @override
  State<GuidedDetectionScreen> createState() => _GuidedDetectionScreenState();
}

class _GuidedDetectionScreenState extends State<GuidedDetectionScreen> {
  CameraController? _cameraController;
  final DetectorService _detector = DetectorService();

  bool _isInitializing = true;
  String? _error;
  bool _isProcessingFrame = false;
  DateTime _lastProcessTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minProcessInterval = Duration(milliseconds: 300);

  bool _isLiveMode = false;
  bool _captureNextFrame = false;

  int _currentStep = 0;
  List<Detection> _detections = [];
  Set<String> _detectedComponents = {};
  bool _safetyAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _safetyAcknowledged = widget.guide.safetyNote == null;
    _setup();
  }

  Future<void> _setup() async {
    try {
      final granted = await _requestCameraPermission();
      if (!granted) {
        setState(() {
          _isInitializing = false;
          _error = 'Camera permission denied. Enable it in app settings.';
        });
        return;
      }

      await _detector.loadModel();
      await _initCamera();

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = 'Setup failed: $e';
        });
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras found');

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      back,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    await _cameraController!.startImageStream(_onCameraFrame);
  }

  void _onCameraFrame(CameraImage cameraImage) {
    if (_isProcessingFrame || !mounted) return;

    final shouldProcess = _isLiveMode || _captureNextFrame;
    if (!shouldProcess) return;

    if (_isLiveMode) {
      final now = DateTime.now();
      if (now.difference(_lastProcessTime) < _minProcessInterval) return;
      _lastProcessTime = now;
    }

    _captureNextFrame = false;
    _isProcessingFrame = true;

    _processFrame(cameraImage).whenComplete(() {
      _isProcessingFrame = false;
    });
  }

  void _triggerDetect() {
    if (_isProcessingFrame) return;
    setState(() => _captureNextFrame = true);
  }

  void _toggleMode() {
    setState(() {
      _isLiveMode = !_isLiveMode;
      if (!_isLiveMode) {
        _detections = [];
        _detectedComponents = {};
      }
    });
  }

  Future<void> _processFrame(CameraImage cameraImage) async {
    try {
      final rgbImage = _yuv420ToImage(cameraImage);
      final rotated = img.copyRotate(rgbImage, angle: 90);
      final detections = await _detector.detect(rotated);

      if (mounted) {
        setState(() {
          _detections = detections;
          _detectedComponents = detections.map((d) => d.label).toSet();
        });
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    }
  }

  img.Image _yuv420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final rgbBytes = Uint8List(width * height * 3);
    int rgbIdx = 0;

    for (int y = 0; y < height; y++) {
      final uvY = y ~/ 2;
      final yRowOffset = y * yRowStride;
      final uvRowOffset = uvY * uvRowStride;

      for (int x = 0; x < width; x++) {
        final yValue = yBytes[yRowOffset + x];
        final uvOffset = uvRowOffset + (x ~/ 2) * uvPixelStride;
        final uValue = uBytes[uvOffset] - 128;
        final vValue = vBytes[uvOffset] - 128;

        int r = (yValue + 1.402 * vValue).round();
        int g = (yValue - 0.344 * uValue - 0.714 * vValue).round();
        int b = (yValue + 1.772 * uValue).round();

        if (r < 0) r = 0; else if (r > 255) r = 255;
        if (g < 0) g = 0; else if (g > 255) g = 255;
        if (b < 0) b = 0; else if (b > 255) b = 255;

        rgbBytes[rgbIdx++] = r;
        rgbBytes[rgbIdx++] = g;
        rgbBytes[rgbIdx++] = b;
      }
    }

    return img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbBytes.buffer,
      numChannels: 3,
    );
  }

  @override
  void dispose() {
    final controller = _cameraController;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    final totalSteps = guide.steps.length;
    final progress = (_currentStep + 1) / totalSteps;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(guide.title),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Icon(
                  _isLiveMode ? Icons.videocam : Icons.camera_alt,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(_isLiveMode ? 'Live' : 'Tap',
                    style: const TextStyle(fontSize: 13)),
                Switch(
                  value: _isLiveMode,
                  onChanged: (_) => _toggleMode(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(child: _buildCameraView()),
          _buildStepCard(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading camera and model...',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text('Camera not available',
            style: TextStyle(color: Colors.white)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (_detections.isNotEmpty)
          CustomPaint(
            painter: BoundingBoxPainter(detections: _detections),
          ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: _buildRequiredComponentsBar(),
        ),
        if (_isLiveMode)
          Positioned(
            top: 12,
            right: 12,
            child: _buildLiveBadge(),
          ),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.circle, color: Colors.white, size: 8),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredComponentsBar() {
    final guide = widget.guide;
    if (guide.requiredComponents.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Required components',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: guide.requiredComponents.map((c) {
              final detected = _detectedComponents.contains(c);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: detected
                      ? Colors.lightGreenAccent
                      : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      detected ? Icons.check_circle : Icons.search,
                      color: detected ? Colors.black : Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      c,
                      style: TextStyle(
                        color: detected ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard() {
    final guide = widget.guide;
    final totalSteps = guide.steps.length;
    final isLastStep = _currentStep == totalSteps - 1;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_currentStep == 0 &&
                  guide.safetyNote != null &&
                  !_safetyAcknowledged)
                _SafetyDialog(
                  note: guide.safetyNote!,
                  onAcknowledge: () =>
                      setState(() => _safetyAcknowledged = true),
                )
              else ...[
                Row(
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $totalSteps',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (_detections.isNotEmpty)
                      Text(
                        '${_detections.length} detected',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  guide.steps[_currentStep],
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _currentStep > 0
                          ? () => setState(() => _currentStep--)
                          : null,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                    ),
                    const Spacer(),
                    if (!_isLiveMode) ...[
                      FilledButton.tonalIcon(
                        onPressed:
                            _isProcessingFrame ? null : _triggerDetect,
                        icon: _isProcessingFrame
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: const Text('Detect'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton.icon(
                      onPressed: isLastStep
                          ? () => Navigator.of(context).pop()
                          : () => setState(() => _currentStep++),
                      icon: Icon(
                          isLastStep ? Icons.check : Icons.arrow_forward,
                          size: 18),
                      label: Text(isLastStep ? 'Finish' : 'Next'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyDialog extends StatelessWidget {
  final String note;
  final VoidCallback onAcknowledge;

  const _SafetyDialog({required this.note, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Before you start',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onAcknowledge,
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
