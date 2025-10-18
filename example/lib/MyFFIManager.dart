import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';



typedef AddNumbersFunc = Int32 Function(Int32 a, Int32 b);
typedef AddNumbers = int Function(int a, int b);

typedef InitModelC = Int64 Function(Pointer<Utf8> model_path);
typedef InitModelDart = int Function(Pointer<Utf8> model_path);

typedef ProcessImageC = Pointer<Float> Function(
    Int64 model_ptr, Int64 mat_addr, Pointer<Int32> out_size);
typedef ProcessImageDart = Pointer<Float> Function(
    int model_ptr, int mat_addr, Pointer<Int32> out_size);

typedef ProcessImagePathC = Int32 Function(Pointer<Utf8> imagePath);
typedef ProcessImagePathDart = int Function(Pointer<Utf8> imagePath);

typedef AccessImagePathC = Int32 Function(Pointer<Utf8> imagePath);
typedef AccessImagePathDart = int Function(Pointer<Utf8> imagePath);


typedef GetDetectionMessageC = Pointer<Utf8> Function();
typedef GetDetectionMessageDart = Pointer<Utf8> Function();

typedef InitConfigC = Void Function(
  Pointer<Utf8> pathImg,
  Pointer<Utf8> detModelPath,
  Pointer<Utf8> landmarkModelPath1,
  Pointer<Utf8> landmarkModelPath2,
  Pointer<Utf8> recognModelPath,
  Pointer<Utf8> spoofModelPath1,
  Pointer<Utf8> spoofModelPath2,
  Pointer<Utf8> meanShapePath,
  Pointer<Utf8> featurePath,
);
typedef InitConfigDart = void Function(
  Pointer<Utf8> pathImg,
  Pointer<Utf8> detModelPath,
  Pointer<Utf8> landmarkModelPath1,
  Pointer<Utf8> landmarkModelPath2,
  Pointer<Utf8> recognModelPath,
  Pointer<Utf8> spoofModelPath1,
  Pointer<Utf8> spoofModelPath2,
  Pointer<Utf8> meanShapePath,
  Pointer<Utf8> featurePath,
);

typedef GetRecMessageC = Pointer<Utf8> Function(Pointer<Utf8> imagePath);
typedef GetRecMessageDart = Pointer<Utf8> Function(Pointer<Utf8> imagePath);

class MyFFIManager {

  late final DynamicLibrary _nativeLib;
  late final AddNumbers _addNumbers;
  late final AccessImagePathDart _accessImagePath;
  late final GetDetectionMessageDart _getDetectionMessage;
  late final InitConfigDart _initConfig;
  late final GetRecMessageDart _getRecMessage;

  static MyFFIManager get instance => _instance;
  static final MyFFIManager _instance = MyFFIManager._internal();

  MyFFIManager._internal() {
    if (Platform.isAndroid) {
      _nativeLib = DynamicLibrary.open("libnative_lib.so");
    } else if (Platform.isIOS) {

      _nativeLib = DynamicLibrary.process();
    } else {
      throw UnsupportedError('目前只支援 Android 和 iOS 平台。');
    }

    _initFunctions();
  }

  void _initFunctions() {
    try {

      _addNumbers = _nativeLib
          .lookup<NativeFunction<AddNumbersFunc>>('addNumbersC')
          .asFunction<AddNumbers>();


      _accessImagePath = _nativeLib
          .lookup<NativeFunction<AccessImagePathC>>('accessImagePathC')
          .asFunction<AccessImagePathDart>();

      _getDetectionMessage = _nativeLib
          .lookup<NativeFunction<GetDetectionMessageC>>('getDetectionMessage')
          .asFunction<GetDetectionMessageDart>();

      _initConfig = _nativeLib
          .lookup<NativeFunction<InitConfigC>>('initConfig')
          .asFunction<InitConfigDart>();

      _getRecMessage = _nativeLib
          .lookup<NativeFunction<GetRecMessageC>>('getRecMessage')
          .asFunction<GetRecMessageDart>();

    } catch (e) {
      print('初始化函數錯誤: $e');
      rethrow;
    }
  }

  int add(int a, int b) {
    return _addNumbers(a, b);
  }

  int accessImagePath(String path) {
    final Pointer<Utf8> pathPtr = path.toNativeUtf8();
    final int result = _accessImagePath(pathPtr);
    malloc.free(pathPtr);
    return result;
  }

  String getDetectionMessage() {
    final Pointer<Utf8> resultPtr = _getDetectionMessage();
    final String message = resultPtr.toDartString();
    // 釋放 C++ 分配的記憶體
    malloc.free(resultPtr);
    return message;
  }

  String getRecMessage(String imgPath) {
    final Pointer<Utf8> imgPathPtr = imgPath.toNativeUtf8();
    final Pointer<Utf8> resultPtr = _getRecMessage(imgPathPtr);
    final String message = resultPtr.toDartString();
    // 釋放 C++ 分配的記憶體
    malloc.free(imgPathPtr);
    malloc.free(resultPtr);
    return message;
  }

  Future<String> getRecMessageAsync(String imgPath) async {
    return await Future(() {
      return getRecMessage(imgPath);
    });
  }

  void initializeConfig(
    String pathImg,
    String detModelPath,
    String landmarkModelPath1,
    String landmarkModelPath2,
    String recognModelPath,
    String spoofModelPath1,
    String spoofModelPath2,
    String meanShapePath,
    String featurePath,
  ) {
    _initConfig(
      pathImg.toNativeUtf8(),
      detModelPath.toNativeUtf8(),
      landmarkModelPath1.toNativeUtf8(),
      landmarkModelPath2.toNativeUtf8(),
      recognModelPath.toNativeUtf8(),
      spoofModelPath1.toNativeUtf8(),
      spoofModelPath2.toNativeUtf8(),
      meanShapePath.toNativeUtf8(),
      featurePath.toNativeUtf8(),
    );
  }
}
