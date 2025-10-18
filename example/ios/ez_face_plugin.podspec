Pod::Spec.new do |s|
  s.name             = 'ez_face_plugin'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin using FFI with static libraries'
  s.description      = 'Direct FFI access to native AI code bundled as static library'
  s.homepage         = 'https://github.com/yourname/ez_face_plugin'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your@email.com' }
  s.source           = { :git => 'https://github.com/yourname/ez_face_plugin.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.platform = :ios, '12.0'

  s.libraries = 'c++'
  s.source_files = '*.m'  # 修正路徑
  
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
    'OTHER_LDFLAGS' => '-force_load $(PODS_ROOT)/../.symlinks/plugins/ez_face_plugin/ios/libez_face_plugin.a'
  }

  s.dependency 'Flutter'
end
