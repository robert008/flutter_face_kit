import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

typedef AddNumbersFunc = Int32 Function(Int32 a, Int32 b);
typedef AddNumbers = int Function(int a, int b);

typedef InitModelC = Int64 Function(Pointer<Utf8> modelPath);
typedef InitModelDart = int Function(Pointer<Utf8> modelPath);

typedef ProcessImageC = Pointer<Float> Function(
    Int64 modelPtr, Int64 matAddr, Pointer<Int32> outSize);
typedef ProcessImageDart = Pointer<Float> Function(
    int modelPtr, int matAddr, Pointer<Int32> outSize);

typedef ProcessImagePathC = Int32 Function(Pointer<Utf8> imagePath);
typedef ProcessImagePathDart = int Function(Pointer<Utf8> imagePath);

typedef AccessImagePathC = Int32 Function(Pointer<Utf8> imagePath);
typedef AccessImagePathDart = int Function(Pointer<Utf8> imagePath);

typedef GetDetectionMessageC = Pointer<Utf8> Function();
typedef GetDetectionMessageDart = Pointer<Utf8> Function();

typedef InitConfigC = Void Function(
  Pointer<Utf8> pathImg,
  Pointer<Utf8> detModelPath,
  Pointer<Utf8> landmarkModelPath1,
  Pointer<Utf8> landmarkModelPath2,
  Pointer<Utf8> recognModelPath,
  Pointer<Utf8> spoofModelPath1,
  Pointer<Utf8> spoofModelPath2,
  Pointer<Utf8> meanShapePath,
  Pointer<Utf8> featurePath,
);
typedef InitConfigDart = void Function(
  Pointer<Utf8> pathImg,
  Pointer<Utf8> detModelPath,
  Pointer<Utf8> landmarkModelPath1,
  Pointer<Utf8> landmarkModelPath2,
  Pointer<Utf8> recognModelPath,
  Pointer<Utf8> spoofModelPath1,
  Pointer<Utf8> spoofModelPath2,
  Pointer<Utf8> meanShapePath,
  Pointer<Utf8> featurePath,
);

typedef GetRecMessageC = Pointer<Utf8> Function(Pointer<Utf8> imagePath);
typedef GetRecMessageDart = Pointer<Utf8> Function(Pointer<Utf8> imagePath);

typedef RegisterFaceC = Pointer<Utf8> Function(Pointer<Utf8> imagePath, Pointer<Utf8> userName);
typedef RegisterFaceDart = Pointer<Utf8> Function(Pointer<Utf8> imagePath, Pointer<Utf8> userName);

/// Bridge class for connecting Flutter to native face recognition library via FFI.
///
/// This class provides direct access to native face recognition functions through
/// FFI (Foreign Function Interface). It handles initialization, face registration,
/// and recognition operations.
///
/// Use [instance] to access the singleton instance.
///
/// Example:
/// ```dart
/// // Initialize with model paths
/// FaceRecognitionBridge.instance.initializeConfig(
///   '',
///   detModelPath,
///   landmarkModelPath1,
///   landmarkModelPath2,
///   recognModelPath,
///   spoofModelPath1,
///   spoofModelPath2,
///   meanShapePath,
///   featurePath,
/// );
///
/// // Register a face
/// String result = FaceRecognitionBridge.instance.registerFace(imagePath, 'user');
///
/// // Recognize a face
/// String result = FaceRecognitionBridge.instance.getRecMessage(imagePath);
/// ```
class FaceRecognitionBridge {
  late final DynamicLibrary _nativeLib;
  late final AddNumbers _addNumbers;
  late final AccessImagePathDart _accessImagePath;
  late final GetDetectionMessageDart _getDetectionMessage;
  late final InitConfigDart _initConfig;
  late final GetRecMessageDart _getRecMessage;
  late final RegisterFaceDart _registerFace;

  /// Singleton instance of [FaceRecognitionBridge].
  static FaceRecognitionBridge get instance => _instance;
  static final FaceRecognitionBridge _instance = FaceRecognitionBridge._internal();

  FaceRecognitionBridge._internal() {
    if (Platform.isAndroid) {
      _nativeLib = DynamicLibrary.open("libnative_lib.so");
    } else if (Platform.isIOS) {
      _nativeLib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('Only Android and iOS platforms are currently supported.');
    }

    _initFunctions();
  }

  void _initFunctions() {
    try {
      _addNumbers = _nativeLib
          .lookup<NativeFunction<AddNumbersFunc>>('addNumbersC')
          .asFunction<AddNumbers>();

      _accessImagePath = _nativeLib
          .lookup<NativeFunction<AccessImagePathC>>('accessImagePathC')
          .asFunction<AccessImagePathDart>();

      _getDetectionMessage = _nativeLib
          .lookup<NativeFunction<GetDetectionMessageC>>('getDetectionMessage')
          .asFunction<GetDetectionMessageDart>();

      _initConfig = _nativeLib
          .lookup<NativeFunction<InitConfigC>>('initConfig')
          .asFunction<InitConfigDart>();

      _getRecMessage = _nativeLib
          .lookup<NativeFunction<GetRecMessageC>>('getRecMessage')
          .asFunction<GetRecMessageDart>();

      _registerFace = _nativeLib
          .lookup<NativeFunction<RegisterFaceC>>('registerFace')
          .asFunction<RegisterFaceDart>();

    } catch (e) {
      debugPrint('[FaceRecognitionBridge] Function initialization error: $e');
      rethrow;
    }
  }

  int add(int a, int b) {
    return _addNumbers(a, b);
  }

  int accessImagePath(String path) {
    final Pointer<Utf8> pathPtr = path.toNativeUtf8();
    final int result = _accessImagePath(pathPtr);
    malloc.free(pathPtr);
    return result;
  }

  String getDetectionMessage() {
    final Pointer<Utf8> resultPtr = _getDetectionMessage();
    final String message = resultPtr.toDartString();
    malloc.free(resultPtr);
    return message;
  }

  /// Performs face recognition on an image.
  ///
  /// Compares the face in the image against registered faces in the system.
  /// The system must be initialized and have at least one registered face.
  ///
  /// Parameters:
  /// - [imgPath]: Path to the image file to recognize
  ///
  /// Returns a comma-separated string with status codes:
  /// - Format: "detectionStatus,recognitionStatus,..."
  /// - Status 201: Recognition successful
  /// - Status 301: Spoofing detected
  /// - Status 302: Face not matched
  /// - Status 303: Face obstructed
  String getRecMessage(String imgPath) {
    final Pointer<Utf8> imgPathPtr = imgPath.toNativeUtf8();
    final Pointer<Utf8> resultPtr = _getRecMessage(imgPathPtr);
    final String message = resultPtr.toDartString();
    malloc.free(imgPathPtr);
    malloc.free(resultPtr);
    return message;
  }

  /// Asynchronous version of [getRecMessage].
  ///
  /// Runs recognition in a Future to avoid blocking the UI thread.
  Future<String> getRecMessageAsync(String imgPath) async {
    return await Future(() {
      return getRecMessage(imgPath);
    });
  }

  /// Initializes the face recognition system with AI model paths and configuration.
  ///
  /// This method must be called before using any recognition or registration features.
  ///
  /// Parameters:
  /// - [pathImg]: Reserved parameter (can be empty string)
  /// - [detModelPath]: Path to face detection model (det_10g.onnx)
  /// - [landmarkModelPath1]: Path to first landmark model (2d106det.onnx)
  /// - [landmarkModelPath2]: Path to second landmark model
  /// - [recognModelPath]: Path to recognition model (w600k_r50.onnx)
  /// - [spoofModelPath1]: Path to first anti-spoofing model (fasnet_v1se.onnx)
  /// - [spoofModelPath2]: Path to second anti-spoofing model (fasnet_v2.onnx)
  /// - [meanShapePath]: Path to mean shape data file
  /// - [featurePath]: Path to saved face features JSON file
  void initializeConfig(
    String pathImg,
    String detModelPath,
    String landmarkModelPath1,
    String landmarkModelPath2,
    String recognModelPath,
    String spoofModelPath1,
    String spoofModelPath2,
    String meanShapePath,
    String featurePath,
  ) {
    _initConfig(
      pathImg.toNativeUtf8(),
      detModelPath.toNativeUtf8(),
      landmarkModelPath1.toNativeUtf8(),
      landmarkModelPath2.toNativeUtf8(),
      recognModelPath.toNativeUtf8(),
      spoofModelPath1.toNativeUtf8(),
      spoofModelPath2.toNativeUtf8(),
      meanShapePath.toNativeUtf8(),
      featurePath.toNativeUtf8(),
    );
  }

  /// Registers a new face to the recognition system.
  ///
  /// Extracts facial features from the image and saves them for future recognition.
  /// The system must be initialized with [initializeConfig] before calling this method.
  ///
  /// Parameters:
  /// - [imgPath]: Path to the image file containing the face
  /// - [userName]: Name/identifier for the registered user
  ///
  /// Returns a JSON string containing face features and registration status.
  /// Check the result for success/failure status codes.
  String registerFace(String imgPath, String userName) {
    final Pointer<Utf8> imgPathPtr = imgPath.toNativeUtf8();
    final Pointer<Utf8> userNamePtr = userName.toNativeUtf8();
    final Pointer<Utf8> resultPtr = _registerFace(imgPathPtr, userNamePtr);
    final String result = resultPtr.toDartString();
    malloc.free(imgPathPtr);
    malloc.free(userNamePtr);
    malloc.free(resultPtr);
    return result;
  }

  /// Asynchronous version of [registerFace].
  ///
  /// Runs registration in a Future to avoid blocking the UI thread.
  Future<String> registerFaceAsync(String imgPath, String userName) async {
    return await Future(() {
      return registerFace(imgPath, userName);
    });
  }
}
