import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_face_kit/flutter_face_kit.dart';
import 'package:flutter_face_kit/flutter_face_kit_platform_interface.dart';
import 'package:flutter_face_kit/flutter_face_kit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterFaceKitPlatform
    with MockPlatformInterfaceMixin
    implements FlutterFaceKitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterFaceKitPlatform initialPlatform = FlutterFaceKitPlatform.instance;

  test('$MethodChannelFlutterFaceKit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterFaceKit>());
  });

  test('getPlatformVersion', () async {
    FlutterFaceKit flutterFaceKitPlugin = FlutterFaceKit();
    MockFlutterFaceKitPlatform fakePlatform = MockFlutterFaceKitPlatform();
    FlutterFaceKitPlatform.instance = fakePlatform;

    expect(await flutterFaceKitPlugin.getPlatformVersion(), '42');
  });
}
