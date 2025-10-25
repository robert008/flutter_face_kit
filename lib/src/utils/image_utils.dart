import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Writes image data to a file in the application documents directory
Future<String> writeImageDataToFile(Uint8List data, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(data);
  return filePath;
}

/// Converts a CameraImage to PNG format
Uint8List convertCameraImageToImage(CameraImage image, CameraController controller) {
  final int width = image.width;
  final int height = image.height;

  if (image.format.group == ImageFormatGroup.yuv420) {
    final img.Image imgBuffer = img.Image(width: width, height: height);

    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;

    final int yRowStride = image.planes[0].bytesPerRow;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int uvIndex = ((y ~/ 2) * uvRowStride) + (x ~/ 2) * uvPixelStride;

        final int yValue = yPlane[yIndex];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];

        final int r = (yValue + 1.402 * (vValue - 128)).toInt().clamp(0, 255);
        final int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).toInt().clamp(0, 255);
        final int b = (yValue + 1.772 * (uValue - 128)).toInt().clamp(0, 255);

        imgBuffer.setPixelRgb(x, y, r, g, b);
      }
    }

    img.Image rotated = img.copyRotate(imgBuffer, angle: controller.description.sensorOrientation);

    return Uint8List.fromList(img.encodePng(rotated));
  } else if (image.format.group == ImageFormatGroup.bgra8888) {
    final plane = image.planes[0];

    final img.Image imgBuffer = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: plane.bytes.buffer,
      format: img.Format.uint8,
      numChannels: 4,
      rowStride: plane.bytesPerRow,
      order: img.ChannelOrder.bgra,
    );

    img.Image rotated = img.copyRotate(imgBuffer, angle: 0);

    if (controller.description.lensDirection == CameraLensDirection.front) {
      rotated = img.flipHorizontal(rotated);
    }

    return Uint8List.fromList(img.encodePng(rotated));
  }

  throw UnsupportedError('Unsupported image format group: ${image.format.group}');
}
