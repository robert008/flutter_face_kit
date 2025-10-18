
import 'flutter_face_kit_platform_interface.dart';

class FlutterFaceKit {
  Future<String?> getPlatformVersion() {
    return FlutterFaceKitPlatform.instance.getPlatformVersion();
  }
}
