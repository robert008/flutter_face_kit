import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_kit/flutter_face_kit.dart';

/// Simple example using FaceRegistrationService
/// This demonstrates the easiest way to use the face recognition SDK
class SimpleRegisterPage extends StatefulWidget {
  const SimpleRegisterPage({Key? key}) : super(key: key);

  @override
  State<SimpleRegisterPage> createState() => _SimpleRegisterPageState();
}

class _SimpleRegisterPageState extends State<SimpleRegisterPage> {
  CameraController? _controller;
  bool _isProcessing = false;
  String _statusMessage = 'Position your face to the camera';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);
    setState(() {});
  }

  Future<void> _captureAndRegister() async {
    if (_isProcessing || _controller == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing...';
    });

    try {
      // Step 1: Capture image
      final image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();

      // Step 2: Call Service API (runs in isolate, non-blocking)
      final result = await FaceRegistrationService.registerFace(
        imageBytes: imageBytes,
        userName: 'user',
      );

      // Step 3: Handle result
      setState(() {
        if (result.success) {
          _statusMessage = 'Registration successful!';
          _showSuccessDialog();
        } else {
          _statusMessage = result.message ?? result.error ?? 'Registration failed';
        }
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Face registered successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop({'status': 'success'});
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Simple Register')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Register'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black87,
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _captureAndRegister,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Capture & Register',
                            style: TextStyle(fontSize: 18),
                          ),
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
