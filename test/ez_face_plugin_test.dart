import 'package:flutter_test/flutter_test.dart';
import 'package:ez_face_plugin/ez_face_plugin.dart';
import 'package:ez_face_plugin/ez_face_plugin_platform_interface.dart';
import 'package:ez_face_plugin/ez_face_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEzFacePluginPlatform
    with MockPlatformInterfaceMixin
    implements EzFacePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EzFacePluginPlatform initialPlatform = EzFacePluginPlatform.instance;

  test('$MethodChannelEzFacePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEzFacePlugin>());
  });

  test('getPlatformVersion', () async {
    EzFacePlugin ezFacePlugin = EzFacePlugin();
    MockEzFacePluginPlatform fakePlatform = MockEzFacePluginPlatform();
    EzFacePluginPlatform.instance = fakePlatform;

    expect(await ezFacePlugin.getPlatformVersion(), '42');
  });
}
