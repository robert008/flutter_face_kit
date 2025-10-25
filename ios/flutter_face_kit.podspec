Pod::Spec.new do |s|
  s.name             = 'flutter_face_kit'
  s.version          = '1.0.1'
  s.summary          = 'A comprehensive on-device face recognition SDK for Flutter'
  s.homepage         = 'https://github.com/robert008/flutter_face_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'robert' => 'figo007007@gmail.com' }
  s.source           = { :path => '.' }

  s.source_files = [
    'Classes/**/*.{h,m}',
  ]

  s.vendored_libraries = 'libflutter_face_kit.a'

  s.ios.deployment_target = '12.0'
  s.static_framework = true

  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-force_load $(PODS_TARGET_SRCROOT)/libflutter_face_kit.a -lc++',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'DEFINES_MODULE' => 'YES',
    'GCC_SYMBOLS_PRIVATE_EXTERN' => 'NO'
  }

  s.dependency 'Flutter'
end
