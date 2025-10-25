import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../ffi/face_recognition_bridge.dart';
import '../models/registration_result.dart';

/// High-level service for face registration with automatic isolate support.
///
/// This service provides an easy-to-use API for registering new faces that automatically
/// handles background processing in isolates to prevent UI blocking.
///
/// Features:
/// - Automatic isolate execution via [compute]
/// - Strongly-typed results with [FaceRegistrationResult]
/// - Automatic feature file saving
/// - Built-in error handling
///
/// Example:
/// ```dart
/// final image = await controller.takePicture();
/// final imageBytes = await image.readAsBytes();
///
/// final result = await FaceRegistrationService.registerFace(
///   imageBytes: imageBytes,
///   userName: 'John Doe',
/// );
///
/// if (result.success) {
///   print('Face registered successfully!');
/// } else {
///   print('Registration failed: ${result.error}');
/// }
/// ```
class FaceRegistrationService {
  /// Register a face from image bytes in an isolate (non-blocking)
  ///
  /// This method runs the AI inference in a background isolate, preventing UI freezing.
  ///
  /// Example:
  /// ```dart
  /// final result = await FaceRegistrationService.registerFace(
  ///   imageBytes: pngBytes,
  ///   userName: 'user123',
  /// );
  ///
  /// if (result.success) {
  ///   print('Registration successful!');
  /// }
  /// ```
  static Future<FaceRegistrationResult> registerFace({
    required Uint8List imageBytes,
    required String userName,
    String? tempDirectory,
    String? documentsDirectory,
  }) async {
    // Get documents directory for feature file
    String docsDir = documentsDirectory ?? '';
    if (docsDir.isEmpty) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        docsDir = dir.path;
      } catch (e) {
        debugPrint('[Service] Warning: Could not get documents directory: $e');
      }
    }

    return compute(_isolateRegisterFace, {
      'imageBytes': imageBytes,
      'userName': userName,
      'tempDirectory': tempDirectory,
      'documentsDirectory': docsDir,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Isolate entry point for face registration
  /// Must be static or top-level function
  static FaceRegistrationResult _isolateRegisterFace(Map<String, dynamic> params) {
    try {
      final Uint8List imageBytes = params['imageBytes'];
      final String userName = params['userName'];
      final String? tempDir = params['tempDirectory'];
      final String docsDir = params['documentsDirectory'] ?? '';
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
      final fileName = 'register_$timestamp.png';
      final filePath = '$tempDirPath/$fileName';

      try {
        File(filePath).writeAsBytesSync(imageBytes, flush: false);

        final savedFile = File(filePath);
        if (!savedFile.existsSync()) {
          return FaceRegistrationResult.error('File save failed');
        }

        final savedSize = savedFile.lengthSync();
        if (savedSize != imageBytes.length) {
          return FaceRegistrationResult.error(
            'File size mismatch: $savedSize vs ${imageBytes.length}',
          );
        }

        // Initialize FFI bridge in isolate
        late final DynamicLibrary nativeLib;
        late final RegisterFaceDart registerFaceNative;

        try {
          nativeLib = Platform.isIOS
              ? DynamicLibrary.process()
              : DynamicLibrary.open("libnative_lib.so");

          registerFaceNative = nativeLib
              .lookup<NativeFunction<RegisterFaceC>>('registerFace')
              .asFunction<RegisterFaceDart>();
        } catch (e) {
          return FaceRegistrationResult.error('FFI initialization failed: $e');
        }

        // Call native register function
        final pathPtr = filePath.toNativeUtf8();
        final namePtr = userName.toNativeUtf8();
        final resultPtr = registerFaceNative(pathPtr, namePtr);
        final rawResult = resultPtr.toDartString();

        // Free memory
        malloc.free(pathPtr);
        malloc.free(namePtr);
        malloc.free(resultPtr);

        // Clean up temp file
        try {
          savedFile.deleteSync();
        } catch (e) {
          debugPrint('[Isolate] Warning: File cleanup failed: $e');
        }

        // Save feature file if registration successful
        if (rawResult.contains('user_name') ||
            rawResult.contains('face_id') ||
            rawResult.contains('feature')) {
          if (docsDir.isNotEmpty) {
            try {
              final featureFile = File('$docsDir/downloaded_file.json');
              featureFile.writeAsStringSync('[$rawResult]');
              debugPrint('[Isolate] Feature file saved: ${featureFile.path}');
            } catch (e) {
              debugPrint('[Isolate] Warning: Failed to save feature file: $e');
            }
          } else {
            debugPrint('[Isolate] Warning: Documents directory not provided, cannot save feature file');
          }
        }

        return FaceRegistrationResult.fromRawResult(rawResult);
      } catch (e) {
        // Clean up on error
        try {
          File(filePath).deleteSync();
        } catch (_) {}
        return FaceRegistrationResult.error('Registration processing failed: $e');
      }
    } catch (e) {
      return FaceRegistrationResult.error('Unexpected error: $e');
    }
  }
}
