import 'package:flutter_face_kit_example/shared_function.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'MyFFIManager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('flutter main init');
  try {
    // String detModelPath = await writeAssetImageToFile('packages/flutter_face_kit/assets/face/model/det_500m.onnx', 'det_500m.onnx'); //小 model
    String detModelPath = await writeAssetImageToFile(
        'packages/flutter_face_kit/assets/face/l_models/det_10g.onnx', 'det_10g.onnx'); //大 model
    String landmarkModelPath1 = await writeAssetImageToFile(
        '', '');
    String landmarkModelPath2 = await writeAssetImageToFile(
        'packages/flutter_face_kit/assets/face/model/2d106det.onnx', '2d106det.onnx');
    // String recModelPath = await writeAssetImageToFile('packages/flutter_face_kit/assets/face/model/w600k_mbf.onnx', 'w600k_mbf.onnx'); //小 model
    String recModelPath = await writeAssetImageToFile(
        'packages/flutter_face_kit/assets/face/l_models/w600k_r50.onnx', 'w600k_r50.onnx'); //大 model
    String spoofModelPath1 = await writeAssetImageToFile(
        'packages/flutter_face_kit/assets/face/model/fasnet_v1se.onnx', 'fasnet_v1se.onnx');
    String spoofModelPath2 = await writeAssetImageToFile(
        'packages/flutter_face_kit/assets/face/model/fasnet_v2.onnx', 'fasnet_v2.onnx');

    final directory = await getApplicationDocumentsDirectory();
    String meanShapePath = '${directory.path}/downloaded_file.json';

    MyFFIManager.instance.initializeConfig(
      "",
      detModelPath,
      landmarkModelPath1,
      landmarkModelPath2,
      recModelPath,
      spoofModelPath1,
      spoofModelPath2,
      meanShapePath,
      meanShapePath,
    );
    // print('flutter init success !');
    // final result = MyFFIManager.instance.getSimpleTest();
    // print('SimpleTest 回傳: $result'); // 預期為 999

    final manager = MyFFIManager.instance;
    // final resultGetSimpleTest = manager.getSimpleTest();
    // print('SimpleTest 回傳: $resultGetSimpleTest'); // 預期為 999

    // 嘗試呼叫加法函數
    try {
      final result = manager.add(1, 2);
      print('加法結果: $result');

    } catch (e) {
      print('呼叫加法函數失敗: $e');
    }

    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            // 用 WidgetsBinding 來確保在畫面出來後再顯示 dialog
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("初始化錯誤"),
                  content: Text("$e"),
                  actions: [
                    TextButton(
                      child: Text("OK"),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
              );
            });

            return Center(child: Text("App 初始化失敗"));
          },
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('初始化成功 '),
        ),
      ),
    );
  }
}
