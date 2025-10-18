Pod::Spec.new do |s|
  s.name             = 'flutter_face_kit'
  s.version          = '1.0.2'
  s.summary          = 'A comprehensive on-device face recognition SDK for Flutter'
  s.homepage         = 'https://github.com/yourusername/flutter_face_kit'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }

  s.source_files = [
    'Classes/**/*.{h,m}',
  ]

  s.vendored_libraries = 'libez_face_3_0724.a'

  s.ios.deployment_target = '12.0'
  s.static_framework = true

  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-force_load $(PODS_TARGET_SRCROOT)/libez_face_3_0724.a -lc++',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'DEFINES_MODULE' => 'YES',
    'GCC_SYMBOLS_PRIVATE_EXTERN' => 'NO'
  }

  s.dependency 'Flutter'
end
