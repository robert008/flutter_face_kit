import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../ffi/face_recognition_bridge.dart';
import '../models/recognition_result.dart';

/// High-level service for face recognition with automatic isolate support.
///
/// This service provides an easy-to-use API for face recognition that automatically
/// handles background processing in isolates to prevent UI blocking.
///
/// Features:
/// - Automatic isolate execution via [compute]
/// - Strongly-typed results with [FaceRecognitionResult]
/// - Built-in error handling
///
/// Example:
/// ```dart
/// final image = await controller.takePicture();
/// final imageBytes = await image.readAsBytes();
///
/// final result = await FaceRecognitionService.recognizeFace(
///   imageBytes: imageBytes,
/// );
///
/// if (result.isRecognized) {
///   print('Face recognized successfully!');
/// } else if (result.isSpoofingDetected) {
///   print('Spoofing attempt detected');
/// }
/// ```
class FaceRecognitionService {
  /// Recognize a face from image bytes in an isolate (non-blocking)
  ///
  /// This method runs the AI inference in a background isolate, preventing UI freezing.
  ///
  /// Example:
  /// ```dart
  /// final result = await FaceRecognitionService.recognizeFace(
  ///   imageBytes: pngBytes,
  /// );
  ///
  /// if (result.isRecognized) {
  ///   print('Face recognized!');
  /// }
  /// ```
  static Future<FaceRecognitionResult> recognizeFace({
    required Uint8List imageBytes,
    String? tempDirectory,
  }) async {
    return compute(_isolateRecognizeFace, {
      'imageBytes': imageBytes,
      'tempDirectory': tempDirectory,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Isolate entry point for face recognition
  /// Must be static or top-level function
  static FaceRecognitionResult _isolateRecognizeFace(Map<String, dynamic> params) {
    try {
      final Uint8List imageBytes = params['imageBytes'];
      final String? tempDir = params['tempDirectory'];
      final int timestamp = params['timestamp'];

      // Get temp directory path
      String tempDirPath;
      if (tempDir != null) {
        tempDirPath = tempDir;
      } else {
        // In isolate, we need to get it synchronously
        final dir = Directory.systemTemp;
        tempDirPath = dir.path;
      }

      // Save image to temp file
      final fileName = 'recognize_$timestamp.png';
      final filePath = '$tempDirPath/$fileName';

      try {
        File(filePath).writeAsBytesSync(imageBytes, flush: false);

        final savedFile = File(filePath);
        if (!savedFile.existsSync()) {
          return FaceRecognitionResult.error('File save failed');
        }

        final savedSize = savedFile.lengthSync();
        if (savedSize != imageBytes.length) {
          return FaceRecognitionResult.error(
            'File size mismatch: $savedSize vs ${imageBytes.length}',
          );
        }

        // Initialize FFI bridge in isolate
        late final DynamicLibrary nativeLib;
        late final GetRecMessageDart getRecMessageNative;

        try {
          nativeLib = Platform.isIOS
              ? DynamicLibrary.process()
              : DynamicLibrary.open("libnative_lib.so");

          getRecMessageNative = nativeLib
              .lookup<NativeFunction<GetRecMessageC>>('getRecMessage')
              .asFunction<GetRecMessageDart>();
        } catch (e) {
          return FaceRecognitionResult.error('FFI initialization failed: $e');
        }

        // Call native recognition function
        final pathPtr = filePath.toNativeUtf8();
        final resultPtr = getRecMessageNative(pathPtr);
        final rawResult = resultPtr.toDartString();

        // Free memory
        malloc.free(pathPtr);
        malloc.free(resultPtr);

        // Clean up temp file
        try {
          savedFile.deleteSync();
        } catch (e) {
          debugPrint('[Isolate] Warning: File cleanup failed: $e');
        }

        return FaceRecognitionResult.fromRawResult(rawResult);
      } catch (e) {
        // Clean up on error
        try {
          File(filePath).deleteSync();
        } catch (_) {}
        return FaceRecognitionResult.error('Recognition processing failed: $e');
      }
    } catch (e) {
      return FaceRecognitionResult.error('Unexpected error: $e');
    }
  }
}
