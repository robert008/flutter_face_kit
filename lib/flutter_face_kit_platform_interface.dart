import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_face_kit_method_channel.dart';

abstract class FlutterFaceKitPlatform extends PlatformInterface {
  FlutterFaceKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterFaceKitPlatform _instance = MethodChannelFlutterFaceKit();

  static FlutterFaceKitPlatform get instance => _instance;

  static set instance(FlutterFaceKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
