import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Checks if the face feature JSON file exists
Future<bool> checkFaceJsonExists() async {
  final directory = await getApplicationDocumentsDirectory();
  String path = '${directory.path}/downloaded_file.json';
  final file = File(path);
  return await file.exists();
}
