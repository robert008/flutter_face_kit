import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_face_kit/flutter_face_kit.dart';

/// Simple example using FaceRecognitionService
/// This demonstrates the easiest way to recognize faces
class SimpleRecPage extends StatefulWidget {
  const SimpleRecPage({Key? key}) : super(key: key);

  @override
  State<SimpleRecPage> createState() => _SimpleRecPageState();
}

class _SimpleRecPageState extends State<SimpleRecPage> {
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

  Future<void> _captureAndRecognize() async {
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
      final result = await FaceRecognitionService.recognizeFace(
        imageBytes: imageBytes,
      );

      // Step 3: Handle result
      debugPrint('[SimpleRec] Result - isRecognized: ${result.isRecognized}');
      debugPrint('[SimpleRec] Result - statusCode: ${result.statusCode}');
      debugPrint('[SimpleRec] Result - rawResult: ${result.rawResult}');

      if (result.isRecognized) {
        // Status code 201: Recognition successful
        setState(() {
          _statusMessage = 'Recognition successful!';
          _isProcessing = false;
        });
        _showSuccessDialog();
      } else if (result.isSpoofingDetected) {
        // Status code 301: Spoofing detected
        setState(() {
          _statusMessage = 'Spoofing detected!';
          _isProcessing = false;
        });
        _showFailureDialog('Spoofing Detected', 'Please use a real face');
      } else if (result.isFaceNotMatched) {
        // Status code 302: Face not matched
        setState(() {
          _statusMessage = 'Face not matched';
          _isProcessing = false;
        });
        _showFailureDialog('Not Recognized', 'Face does not match registered user');
      } else if (result.isFaceObstructed) {
        // Status code 303: Face obstructed
        setState(() {
          _statusMessage = 'Face is obstructed';
          _isProcessing = false;
        });
        _showFailureDialog('Face Obstructed', 'Please remove any obstructions');
      } else {
        // Other status codes (101, 102, 103, 104, 200, etc.)
        final description = RecognitionStatus.getDescription(
          result.statusCode ?? '',
        );
        final message = description.isEmpty
            ? 'Status: ${result.statusCode ?? "Unknown"}'
            : description;

        setState(() {
          _statusMessage = message;
          _isProcessing = false;
        });

        debugPrint('[SimpleRec] Status message: $message');

        // Show dialog for detection issues
        if (result.statusCode == '101') {
          _showFailureDialog('No Face', 'No face detected in image');
        }
      }
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            const Text('Success'),
          ],
        ),
        content: const Text('Face recognized successfully!'),
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

  void _showFailureDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Try Again'),
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
        appBar: AppBar(title: const Text('Simple Recognition')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Recognition'),
        backgroundColor: Colors.purple,
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
                    onPressed: _isProcessing ? null : _captureAndRecognize,
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
                            'Capture & Recognize',
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
