import 'dart:io';
// import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show ByteData, Uint8List, WriteBuffer, rootBundle;
import 'package:path_provider/path_provider.dart';
// import 'package:loading_indicator/loading_indicator.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image/image.dart' as img;


/// 讀取 assets 中的檔案，並寫入臨時目錄，返回該檔案的路徑
Future<String> writeAssetImageToFile(String assetPath, String filename) async {
  // 讀取 asset 檔案資料
  final ByteData data = await rootBundle.load(assetPath);

  // 取得臨時目錄
  final Directory tempDir = await getTemporaryDirectory();
  final String filePath = '${tempDir.path}/$filename';

  // 寫入檔案
  final File file = File(filePath);
  await file.writeAsBytes(
    data.buffer.asUint8List(),
    flush: true,
  );

  return filePath;
}

Future<String> writeImageDataToFile(Uint8List data, String fileName) async {
  // 取得應用程式文件目錄或暫存目錄
  final directory = await getApplicationDocumentsDirectory();
  // 組成檔案路徑
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  // 寫入 Uint8List 資料
  await file.writeAsBytes(data);
  return filePath;
}

Future<Uint8List> loadAssetImage(String assetPath) async {
  ByteData byteData = await rootBundle.load(assetPath);
  return byteData.buffer.asUint8List();
}

///取得包含url前綴的base64
String getBase64WithUrl(String mimeType, String base64String) {
  String dataUrl = 'data:$mimeType;base64,$base64String';
  return dataUrl;
}

// Uint8List convertCameraImageToImage(CameraImage image , CameraController controller) {
//   final int width = image.width;
//   final int height = image.height;
//
//   if (image.format.group == ImageFormatGroup.yuv420) {
//     // ✅ Android 專用：YUV420 處理邏輯
//     final img.Image imgBuffer = img.Image(width: width, height: height);
//
//     final Uint8List yPlane = image.planes[0].bytes;
//     final Uint8List uPlane = image.planes[1].bytes;
//     final Uint8List vPlane = image.planes[2].bytes;
//
//     final int yRowStride = image.planes[0].bytesPerRow;
//     final int uvRowStride = image.planes[1].bytesPerRow;
//     final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;
//
//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final int yIndex = y * yRowStride + x;
//         final int uvIndex =
//             ((y ~/ 2) * uvRowStride) + (x ~/ 2) * uvPixelStride;
//
//         final int yValue = yPlane[yIndex];
//         final int uValue = uPlane[uvIndex];
//         final int vValue = vPlane[uvIndex];
//
//         final int r = (yValue + 1.402 * (vValue - 128)).toInt().clamp(0, 255);
//         final int g =
//         (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
//             .toInt()
//             .clamp(0, 255);
//         final int b = (yValue + 1.772 * (uValue - 128)).toInt().clamp(0, 255);
//
//         imgBuffer.setPixelRgb(x, y, r, g, b);
//       }
//     }
//
//     img.Image rotated = img.copyRotate(imgBuffer,
//         angle: controller.description.sensorOrientation);
//
//     // android 不用鏡像 所以不用反轉
//     // if (controller.description.lensDirection == CameraLensDirection.front) {
//     //   rotated = img.flipHorizontal(rotated);
//     // }
//
//     return Uint8List.fromList(img.encodePng(rotated));
//   } else if (image.format.group == ImageFormatGroup.bgra8888) {
//     // ✅ iOS 專用：BGRA8888 處理邏輯
//     final plane = image.planes[0];
//
//     final img.Image imgBuffer = img.Image.fromBytes(
//       width: width,
//       height: height,
//       bytes: plane.bytes.buffer,
//       format: img.Format.uint8,
//       numChannels: 4,
//       rowStride: plane.bytesPerRow,
//       order: img.ChannelOrder.bgra,
//     );
//
//     // iOS 的 sensorOrientation 有些裝置是 270，實測轉 0 最穩
//     img.Image rotated = img.copyRotate(imgBuffer, angle: 0);
//
//     if (controller.description.lensDirection == CameraLensDirection.front) {
//       rotated = img.flipHorizontal(rotated);
//     }
//
//     return Uint8List.fromList(img.encodePng(rotated));
//   }
//
//   //  其他格式不支援
//   throw UnsupportedError(
//       'Unsupported image format group: ${image.format.group}');
// }
//
// List<List<List<int>>>? convertYUV420toRGBArray(CameraImage image) {
//   try {
//     final int width = image.width;
//     final int height = image.height;
//     final int uvRowStride = image.planes[1].bytesPerRow;
//     final int? uvPixelStride = image.planes[1].bytesPerPixel;
//
//     List<List<List<int>>> rgbList = [];
//
//     for (int y = 0; y < height; y++) {
//       List<List<int>> row = [];
//       for (int x = 0; x < width; x++) {
//         final int uvIndex = (uvPixelStride! * (x / 2).floor()) +
//             (uvRowStride * (y / 2).floor());
//         final int index = y * width + x;
//
//         final int yp = image.planes[0].bytes[index];
//         final int up = image.planes[1].bytes[uvIndex];
//         final int vp = image.planes[2].bytes[uvIndex];
//
//         int r = (yp + (vp * 1436 / 1024 - 179)).round().clamp(0, 255);
//         int g = (yp - (up * 46549 / 131072) + 44 - (vp * 93604 / 131072) + 91)
//             .round()
//             .clamp(0, 255);
//         int b = (yp + (up * 1814 / 1024 - 227)).round().clamp(0, 255);
//
//         row.add([r, g, b]);
//       }
//       rgbList.add(row);
//     }
//     return rgbList;
//   } catch (e) {
//     print("Error>>> $e");
//     return null;
//   }
// }

//將辨識失敗圖片存到 path
Future<String> saveFaceImage(Uint8List imageBytes, String fileName) async  {
  // 🔍 取得 app 文件資料夾
  final dir = await getApplicationDocumentsDirectory();

  // 📁 建立子資料夾路徑
  final folder = Directory('${dir.path}/face_log_img');

  // 📂 如果資料夾不存在就建立
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  // 🖼️ 建立檔案路徑
  final filePath = '${folder.path}/$fileName';

  // 💾 寫入檔案
  final file = File(filePath);
  await file.writeAsBytes(imageBytes);

  print('saveFaceImage filePath : $filePath');
  return filePath; // ✅ 回傳完整路徑
}

