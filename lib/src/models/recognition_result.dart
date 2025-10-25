import 'package:flutter/foundation.dart';

/// Result of a face recognition operation.
///
/// Contains the recognition status, error information, and helper getters
/// for checking specific recognition outcomes.
///
/// Status Codes:
/// - 101: No face detected
/// - 200: Face detected, distance appropriate
/// - 201: Recognition successful
/// - 301: Spoofing detected
/// - 302: Face not matched
/// - 303: Face obstructed
///
/// Example:
/// ```dart
/// final result = await FaceRecognitionService.recognizeFace(...);
///
/// if (result.isRecognized) {
///   print('Welcome back!');
/// } else if (result.isSpoofingDetected) {
///   print('Please use a real face');
/// } else if (result.isFaceNotMatched) {
///   print('Face not recognized');
/// }
/// ```
class FaceRecognitionResult {
  /// Whether the recognition was successful
  final bool success;

  /// Status code (101-303)
  final String? statusCode;

  /// Human-readable status message
  final String? message;

  /// Error message if failed
  final String? error;

  /// Raw result from native code
  final String rawResult;

  FaceRecognitionResult({
    required this.success,
    this.statusCode,
    this.message,
    this.error,
    required this.rawResult,
  });

  /// Check if recognition was successful (status code 201)
  bool get isRecognized => statusCode == '201';

  /// Check if face was detected but not recognized
  bool get isFaceDetected => statusCode != null && statusCode!.startsWith('2');

  /// Check if spoofing was detected (status code 301)
  bool get isSpoofingDetected => statusCode == '301';

  /// Check if face not matched (status code 302)
  bool get isFaceNotMatched => statusCode == '302';

  /// Check if face is obstructed (status code 303)
  bool get isFaceObstructed => statusCode == '303';

  factory FaceRecognitionResult.fromRawResult(String rawResult) {
    try {
      debugPrint('[RecognitionResult] Raw result: $rawResult');

      final parts = rawResult.split(',');

      // Format: detectionStatus,recognitionStatus,... (e.g., "200,201,...")
      // - First part (200): detection status
      // - Second part (201): recognition status (this is what we care about!)
      final detectionStatus = parts.isNotEmpty ? parts[0] : null;
      final recognitionStatus = parts.length > 1 ? parts[1] : null;

      debugPrint('[RecognitionResult] Detection: $detectionStatus, Recognition: $recognitionStatus');

      // Use recognition status (second part) for result
      final statusCode = recognitionStatus ?? detectionStatus;

      return FaceRecognitionResult(
        success: statusCode == '201',
        statusCode: statusCode,
        message: statusCode,
        rawResult: rawResult,
      );
    } catch (e) {
      return FaceRecognitionResult(
        success: false,
        error: 'Failed to parse result: $e',
        rawResult: rawResult,
      );
    }
  }

  factory FaceRecognitionResult.error(String error) {
    return FaceRecognitionResult(
      success: false,
      error: error,
      rawResult: '',
    );
  }
}
