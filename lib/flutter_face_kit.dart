library flutter_face_kit;

import 'flutter_face_kit_platform_interface.dart';

// Export model downloader
export 'model_downloader.dart';

// Export core face recognition functionality (Low-level FFI)
export 'src/ffi/face_recognition_bridge.dart';

// Export services (High-level isolate-based API)
export 'src/services/face_recognition_service.dart';
export 'src/services/face_registration_service.dart';

// Export models
export 'src/models/recognition_status.dart';
export 'src/models/recognition_result.dart';
export 'src/models/registration_result.dart';

// Export utilities
export 'src/storage/face_storage.dart';
export 'src/utils/image_utils.dart';

class FlutterFaceKit {
  Future<String?> getPlatformVersion() {
    return FlutterFaceKitPlatform.instance.getPlatformVersion();
  }
}
