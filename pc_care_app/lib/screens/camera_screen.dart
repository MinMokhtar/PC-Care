import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../services/detector_service.dart';
import '../widgets/bounding_box_painter.dart';
import 'instruction_list_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  final DetectorService _detector = DetectorService();

  bool _isInitializing = true;
  bool _isDetecting = false;
  String? _error;

  List<Detection> _detections = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
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

      if (mounted) {
        setState(() => _isInitializing = false);
      }
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
    if (cameras.isEmpty) {
      throw Exception('No cameras found');
    }

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
  }

  Future<void> _detect() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isDetecting) {
      return;
    }

    setState(() => _isDetecting = true);

    try {
      final xfile = await controller.takePicture();
      final bytes = await File(xfile.path).readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception('Failed to decode captured image');
      }

      final detections = await _detector.detect(decoded);

      if (mounted) {
        setState(() {
          _detections = detections;
          _imageSize = Size(
            decoded.width.toDouble(),
            decoded.height.toDouble(),
          );
        });
      }

      debugPrint('Detected ${detections.length} object(s)');
      for (final d in detections) {
        debugPrint('  - $d');
      }
    } catch (e) {
      debugPrint('Detection error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detection failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PC Care — Detection'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildDetectButton(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.lightGreenAccent),
            SizedBox(height: 16),
            Text(
              'Loading model and camera...',
              style: TextStyle(color: Colors.white),
            ),
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
        child: Text(
          'Camera not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (_detections.isNotEmpty && _imageSize != null)
          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: BoundingBoxPainter(detections: _detections),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );
            },
          ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _detections.isEmpty
                  ? 'Tap detect to find PC components'
                  : 'Detected ${_detections.length} component(s)',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (_detections.isNotEmpty)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _buildGuidesCard(),
          ),
      ],
    );
  }

  Widget _buildGuidesCard() {
    final detectedComponents = _detections
        .map((d) => d.label)
        .toSet()
        .toList();

    return Card(
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              detectedComponents.length == 1
                  ? 'Detected: ${detectedComponents.first}'
                  : 'Detected ${detectedComponents.length} types',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: detectedComponents
                  .map((c) => FilledButton.icon(
                        onPressed: () => _openGuides(c),
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: Text('${_capitalize(c)} guides'),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _openGuides(String component) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InstructionListScreen(component: component),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildDetectButton() {
    if (_isInitializing || _error != null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: _isDetecting ? null : _detect,
      backgroundColor: Colors.lightGreenAccent,
      foregroundColor: Colors.black,
      icon: _isDetecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : const Icon(Icons.search),
      label: Text(_isDetecting ? 'Detecting...' : 'Detect'),
    );
  }
}
