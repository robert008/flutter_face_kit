import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_face_kit_platform_interface.dart';

class MethodChannelFlutterFaceKit extends FlutterFaceKitPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_face_kit');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
