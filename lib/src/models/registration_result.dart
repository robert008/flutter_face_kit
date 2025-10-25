/// Result of a face registration operation.
///
/// Contains the registration status, user information, and error details.
///
/// Example:
/// ```dart
/// final result = await FaceRegistrationService.registerFace(
///   imageBytes: imageBytes,
///   userName: 'John Doe',
/// );
///
/// if (result.success) {
///   print('Face registered successfully!');
///   print('User: ${result.userName}');
/// } else {
///   print('Registration failed: ${result.error ?? result.message}');
/// }
/// ```
class FaceRegistrationResult {
  /// Whether the registration was successful
  final bool success;

  /// User name that was registered
  final String? userName;

  /// Face ID if available
  final String? faceId;

  /// Status message
  final String? message;

  /// Error message if failed
  final String? error;

  /// Raw result from native code
  final String rawResult;

  FaceRegistrationResult({
    required this.success,
    this.userName,
    this.faceId,
    this.message,
    this.error,
    required this.rawResult,
  });

  factory FaceRegistrationResult.fromRawResult(String rawResult) {
    try {
      if (rawResult.contains('error') ||
          rawResult.contains('No face') ||
          rawResult.contains('NO_FACE_DETECTED')) {
        return FaceRegistrationResult(
          success: false,
          message: 'No face detected',
          rawResult: rawResult,
        );
      }

      if (rawResult.contains('user_name') ||
          rawResult.contains('face_id') ||
          rawResult.contains('feature')) {
        return FaceRegistrationResult(
          success: true,
          message: 'Face registered successfully',
          rawResult: rawResult,
        );
      }

      return FaceRegistrationResult(
        success: false,
        message: rawResult,
        rawResult: rawResult,
      );
    } catch (e) {
      return FaceRegistrationResult(
        success: false,
        error: 'Failed to parse result: $e',
        rawResult: rawResult,
      );
    }
  }

  factory FaceRegistrationResult.error(String error) {
    return FaceRegistrationResult(
      success: false,
      error: error,
      rawResult: '',
    );
  }
}
