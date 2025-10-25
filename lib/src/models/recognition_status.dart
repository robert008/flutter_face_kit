/// Maps recognition status codes to human-readable descriptions
class RecognitionStatus {
  /*
   * Status Code Meanings:
   * 101 - No face detected
   * 102 - Multiple faces detected
   * 103 - Too close, please move back
   * 104 - Too far, please move closer
   * 200 - Distance is appropriate
   * 201 - Recognition successful
   * 301 - Recognition failed: Spoofing detected
   * 302 - Recognition failed: Face not matched
   * 303 - Recognition failed: Face is obstructed
   */

  static const Map<String, String> _statusDescriptions = {
    '101': 'No face detected',
    '102': 'Multiple faces detected',
    '103': 'Too close, please move back',
    '104': 'Too far, please move closer',
    '200': 'Distance is appropriate',
    '201': 'Recognition successful',
    '301': 'Recognition failed: Spoofing detected',
    '302': 'Recognition failed: Face not matched',
    '303': 'Recognition failed: Face is obstructed',
  };

  /// Gets the description for a given status code
  static String getDescription(String code) {
    return _statusDescriptions[code] ?? '';
  }
}
