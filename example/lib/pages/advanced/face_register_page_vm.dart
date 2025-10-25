import 'dart:ffi';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_face_kit/flutter_face_kit.dart';

class FaceRegisterPageVM extends ChangeNotifier {
  bool isReady = false;
  String registrationStatus = '';

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool isDetectionOn = true;
  int _frameSkipCount = 0;
  Uint8List? imageData;
  String detString = 'Position your face to the camera';

  static const String _userName = 'user';
  String? _tempDirPath;
  bool _isProcessing = false;

  bool _isCameraDisposed = false;

  CameraController? get controller => _isCameraDisposed ? null : _controller;

  bool get isCameraAvailable => _controller != null && !_isCameraDisposed && _controller!.value.isInitialized;

  List<int> _conversionTimes = [];
  int _slowConversionCount = 0;
  bool _autoOptimizationEnabled = true;

  Future<void> init() async {
    await _initTempDirectory();
    await initializeCamera();
    await initializeCameraWithOptimization();
    isReady = true;
    notifyListeners();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => throw Exception('Front camera not found'),
    );
    _controller = CameraController(frontCamera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    _controller!.startImageStream(_onImageFrame);
    notifyListeners();
  }

  Future<void> initializeCameraWithOptimization() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => throw Exception('Front camera not found'),
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(_onImageFrame);

    debugPrint('[Init] ✅ Camera initialized with optimized resolution');
    notifyListeners();
  }

  Future<void> _initTempDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _tempDirPath = tempDir.path;
      debugPrint('[Init] ✅ Temp directory: $_tempDirPath');
    } catch (e) {
      debugPrint('[Init] ❌ Temp directory initialization failed: $e');
    }
  }

  void _onImageFrame(CameraImage image) {
    if (_isCameraDisposed || _controller == null) {
      return;
    }

    final dynamicSkipFrame = _calculateDynamicSkipFrame();

    if (_frameSkipCount % dynamicSkipFrame == 0 &&
        isDetectionOn &&
        !_isProcessing &&
        (image.format.group == ImageFormatGroup.yuv420 ||
            image.format.group == ImageFormatGroup.bgra8888)) {

      isDetectionOn = true;
      _isProcessing = true;

      _processImageWithDelayedIsolate(image);
    }
    _frameSkipCount++;
  }

  int _calculateDynamicSkipFrame() {
    if (_conversionTimes.isEmpty) return 30;

    final recentTimes = _conversionTimes.length > 5
        ? _conversionTimes.sublist(_conversionTimes.length - 5)
        : _conversionTimes;

    final avgTime = recentTimes.fold<double>(0, (sum, time) => sum + time) / recentTimes.length;

    if (avgTime > 200) {
      return 60;
    } else if (avgTime > 100) {
      return 45;
    } else {
      return 30;
    }
  }

  void _processImageWithDelayedIsolate(CameraImage image) {
    Future.microtask(() async {
      try {
        if (_isCameraDisposed || _controller == null) {
          _isProcessing = false;
          return;
        }

        final startConvert = DateTime.now().millisecondsSinceEpoch;
        Uint8List png = convertCameraImageToImage(image, _controller!);
        final convertTime = DateTime.now().millisecondsSinceEpoch - startConvert;

        imageData = png;

        _conversionTimes.add(convertTime);
        if (_conversionTimes.length > 10) {
          _conversionTimes.removeAt(0);
        }

        debugPrint('[Main] 📊 Image conversion time: ${convertTime}ms, size: ${png.length} bytes');

        if (convertTime > 150) {
          _slowConversionCount++;
          debugPrint('[Main] ⚠️ Slow image conversion: ${convertTime}ms (count: $_slowConversionCount)');

          if (_slowConversionCount >= 3 && _autoOptimizationEnabled) {
            _triggerAutoOptimization();
          }
        } else {
          _slowConversionCount = 0;
        }

        _startIsolateProcessing(png);

      } catch (e) {
        debugPrint('[Main] ❌ Image conversion failed: $e');
        _isProcessing = false;
      }
    });
  }

  void _triggerAutoOptimization() {
    debugPrint('[Main] 🔧 Triggering auto performance optimization...');

    Future.microtask(() async {
      try {
        if (_controller?.description != null && !_isCameraDisposed) {
          final currentResolution = _controller!.resolutionPreset;

          if (currentResolution == ResolutionPreset.high) {
            await switchToLowResolutionMode();
          } else if (currentResolution == ResolutionPreset.medium) {
            await _switchToLowResolution();
          }

          _slowConversionCount = 0;
          _autoOptimizationEnabled = false;

          Future.delayed(Duration(seconds: 30), () {
            _autoOptimizationEnabled = true;
            debugPrint('[Main] 🔧 Auto optimization re-enabled');
          });
        }
      } catch (e) {
        debugPrint('[Main] ❌ Auto optimization failed: $e');
      }
    });
  }

  Future<void> _switchToLowResolution() async {
    try {
      if (_isCameraDisposed) return;

      debugPrint('[Main] 🔄 Switching to low resolution mode...');

      await _controller?.stopImageStream();
      await _controller?.dispose();

      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => throw Exception('Front camera not found'),
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.startImageStream(_onImageFrame);

      debugPrint('[Main] ✅ Switched to low resolution mode');
      notifyListeners();

    } catch (e) {
      debugPrint('[Main] ❌ Low resolution switch failed: $e');
    }
  }

  void _startIsolateProcessing(Uint8List imageBytes) {
    compute(_isolateImageRegistration, {
      'imageBytes': imageBytes,
      'tempDirPath': _tempDirPath!,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'userName': _userName,
    }).then((result) {
      _handleIsolateResult(result);
    }).catchError((error) {
      debugPrint('[Main] ❌ Isolate processing error: $error');
      _isProcessing = false;
    });
  }

  static Map<String, dynamic> _isolateImageRegistration(Map<String, dynamic> params) {
    try {
      final Uint8List imageBytes = params['imageBytes'];
      final String tempDirPath = params['tempDirPath'];
      final int timestamp = params['timestamp'];
      final String userName = params['userName'];

      late final DynamicLibrary nativeLib;
      late final Function(String, String) registerFace;

      try {
        nativeLib = Platform.isIOS
            ? DynamicLibrary.process()
            : DynamicLibrary.open("libnative_lib.so");

        final registerFaceNative = nativeLib
            .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>>('registerFace')
            .asFunction<Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>)>();

        registerFace = (String imagePath, String userName) {
          final pathPtr = imagePath.toNativeUtf8();
          final namePtr = userName.toNativeUtf8();
          final resultPtr = registerFaceNative(pathPtr, namePtr);
          final result = resultPtr.toDartString();

          malloc.free(pathPtr);
          malloc.free(namePtr);
          malloc.free(resultPtr);

          return result;
        };

      } catch (e) {
        return {'success': false, 'error': 'FFI initialization failed: $e'};
      }

      final fileName = 'register_$timestamp.png';
      final filePath = '$tempDirPath/$fileName';

      try {
        File(filePath).writeAsBytesSync(imageBytes, flush: false);

        final savedFile = File(filePath);
        if (!savedFile.existsSync()) {
          return {'success': false, 'error': 'File save failed'};
        }

        final savedSize = savedFile.lengthSync();
        if (savedSize != imageBytes.length) {
          return {'success': false, 'error': 'File size mismatch: $savedSize vs ${imageBytes.length}'};
        }

        final faceResult = registerFace(filePath, userName);

        try { savedFile.deleteSync(); } catch (e) {
          debugPrint('[Isolate] ⚠️ File cleanup failed: $e');
        }

        return {
          'success': true,
          'result': faceResult,
        };

      } catch (e) {
        try { File(filePath).deleteSync(); } catch (_) {}
        return {'success': false, 'error': 'Registration processing failed: $e'};
      }

    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: $e'};
    }
  }

  void _handleIsolateResult(Map<String, dynamic> result) {
    try {
      if (result['success']) {
        _handleRegistrationResult(result['result']).then((_) {
          notifyListeners();
        });
      } else {
        detString = 'Registration failed: ${result['error']}';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Main] ❌ Result processing exception: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> safeDisposeCamera() async {
    try {
      debugPrint('VM safeDisposeCamera started...');

      _isCameraDisposed = true;

      isDetectionOn = false;
      _isProcessing = false;

      notifyListeners();

      if (_controller != null) {
        debugPrint('Stopping image stream...');

        try {
          await _controller!.stopImageStream();
          debugPrint('Image stream stopped');
        } catch (e) {
          debugPrint('Failed to stop image stream: $e');
        }

        await Future.delayed(Duration(milliseconds: 50));

        try {
          await _controller!.dispose();
          debugPrint('Camera controller disposed');
        } catch (e) {
          debugPrint('Failed to dispose controller: $e');
        }

        _controller = null;
      }

      debugPrint('VM safeDisposeCamera completed');

    } catch (e) {
      debugPrint('Error during camera disposal: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('FaceRegisterPageVM dispose called');

    _isCameraDisposed = true;

    if (_controller != null) {
      try {
        _controller!.dispose();
        _controller = null;
      } catch (e) {
        debugPrint('Camera disposal failed in dispose: $e');
      }
    }

    super.dispose();
  }

  Future<void> switchToLowResolutionMode() async {
    try {
      if (_isCameraDisposed) return;

      debugPrint('[Main] Switching to lower resolution mode to improve performance...');

      await _controller?.stopImageStream();
      await _controller?.dispose();

      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => throw Exception('Front camera not found'),
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.startImageStream(_onImageFrame);

      debugPrint('[Main] Switched to medium resolution mode');
      notifyListeners();

    } catch (e) {
      debugPrint('[Main] Resolution switch failed: $e');
    }
  }

  Future<void> _handleRegistrationResult(String result) async {
    debugPrint('[Register] Raw result: $result');

    if (result.contains('error') || result.contains('No face') || result.contains('NO_FACE_DETECTED')) {
      detString = 'No face detected, please position your face to the camera';
      isDetectionOn = true;
    } else if (result.contains('user_name') || result.contains('face_id') || result.contains('feature')) {
      debugPrint('[Register] Detected successful JSON response');

      try {
        final directory = await getApplicationDocumentsDirectory();
        final featureFile = File('${directory.path}/downloaded_file.json');

        await featureFile.writeAsString('[$result]');

        debugPrint('[Register] Feature file saved: ${featureFile.path}');
        debugPrint('[Register] File content first 100 chars: ${result.substring(0, result.length > 100 ? 100 : result.length)}');
      } catch (e) {
        debugPrint('[Register] Failed to save feature file: $e');
      }

      detString = 'Face registered successfully';
      isDetectionOn = false;
      await handleRegisterResult();
    } else {
      detString = result;
      isDetectionOn = true;
    }
  }

  Future<void> handleRegisterResult() async {
    debugPrint('[Register] Setting registrationStatus = success');
    registrationStatus = 'success';
    debugPrint('[Register] Calling notifyListeners()');
    notifyListeners();
  }
}
