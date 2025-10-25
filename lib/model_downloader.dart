import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class DownloadProgress {
  final String fileName;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final DownloadStatus status;

  DownloadProgress({
    required this.fileName,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.status,
  });
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

class ModelDownloadManager {
  static final ModelDownloadManager _instance = ModelDownloadManager._internal();
  factory ModelDownloadManager() => _instance;
  ModelDownloadManager._internal();

  // Cloudflare R2 Base URL (can be dynamically configured)
  static String _baseUrl = 'https://pub-8be3637077824ed1ad6d8fb19604799a.r2.dev/';

  // Set Base URL
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url : '$url/';
    debugPrint('[ModelDownloader] AI model download URL updated: $_baseUrl');
  }

  // Get current Base URL
  static String get baseUrl => _baseUrl;

  // Model file URLs (dynamically generated)
  static Map<String, String> get MODEL_URLS => {
    'det_10g.onnx': '${_baseUrl}det_10g.onnx',
    'w600k_r50.onnx': '${_baseUrl}w600k_r50.onnx',
    '2d106det.onnx': '${_baseUrl}2d106det.onnx',
    'fasnet_v1se.onnx': '${_baseUrl}fasnet_v1se.onnx',
    'fasnet_v2.onnx': '${_baseUrl}fasnet_v2.onnx',
  };

  // Model file sizes (for progress calculation)
  static const Map<String, int> MODEL_SIZES = {
    'det_10g.onnx': 16777216,      // 16MB
    'w600k_r50.onnx': 174063616,   // 166MB
    '2d106det.onnx': 5033165,      // 4.8MB
    'fasnet_v1se.onnx': 1887436,   // 1.8MB
    'fasnet_v2.onnx': 1992294,     // 1.9MB
  };

  final Dio _dio = Dio();
  final StreamController<DownloadProgress> _progressController = StreamController<DownloadProgress>.broadcast();
  final Map<String, CancelToken> _cancelTokens = {};

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// Get model storage directory
  Future<String> getModelDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final modelDir = Directory('${appDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  /// Get model file path
  Future<String> getModelPath(String modelName) async {
    final modelDir = await getModelDirectory();
    return '$modelDir/$modelName';
  }

  /// Check if model is downloaded
  Future<bool> isModelDownloaded(String modelName) async {
    final modelPath = await getModelPath(modelName);
    final file = File(modelPath);

    if (!await file.exists()) {
      return false;
    }

    // Check if file size is reasonable (greater than 1KB)
    final fileSize = await file.length();
    if (fileSize < 1024) {
      debugPrint('[ModelDownloader] Model file size abnormal: $modelName (size: $fileSize bytes)');
      return false;
    }

    // Temporarily remove strict size check as actual download size may differ
    // TODO: Update MODEL_SIZES to correct values
    debugPrint('[ModelDownloader] Model exists: $modelName (size: $fileSize bytes)');

    return true;
  }

  /// Check if all models are downloaded
  Future<bool> areAllModelsDownloaded() async {
    for (final modelName in MODEL_URLS.keys) {
      if (!await isModelDownloaded(modelName)) {
        return false;
      }
    }
    return true;
  }

  /// Download a single model
  Future<bool> downloadModel(String modelName, {Function(double)? onProgress}) async {
    final url = MODEL_URLS[modelName];
    if (url == null) {
      debugPrint('[ModelDownloader] Unknown model name: $modelName');
      return false;
    }

    final modelPath = await getModelPath(modelName);
    final tempPath = '$modelPath.tmp';

    // Create cancel token
    final cancelToken = CancelToken();
    _cancelTokens[modelName] = cancelToken;

    try {
      debugPrint('[ModelDownloader] Starting download: $modelName');

      await _dio.download(
        url,
        tempPath,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;

            // Update progress
            _progressController.add(DownloadProgress(
              fileName: modelName,
              progress: progress,
              downloadedBytes: received,
              totalBytes: total,
              status: DownloadStatus.downloading,
            ));

            // Call progress callback
            onProgress?.call(progress);
          }
        },
      );

      // Download complete, move file
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.rename(modelPath);

        // Mark as completed
        _progressController.add(DownloadProgress(
          fileName: modelName,
          progress: 1.0,
          downloadedBytes: MODEL_SIZES[modelName] ?? 0,
          totalBytes: MODEL_SIZES[modelName] ?? 0,
          status: DownloadStatus.completed,
        ));

        debugPrint('[ModelDownloader] Download complete: $modelName');
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        debugPrint('[ModelDownloader] Download cancelled: $modelName');
        _progressController.add(DownloadProgress(
          fileName: modelName,
          progress: 0,
          downloadedBytes: 0,
          totalBytes: MODEL_SIZES[modelName] ?? 0,
          status: DownloadStatus.cancelled,
        ));
      } else {
        debugPrint('[ModelDownloader] Download failed: $modelName - $e');
        _progressController.add(DownloadProgress(
          fileName: modelName,
          progress: 0,
          downloadedBytes: 0,
          totalBytes: MODEL_SIZES[modelName] ?? 0,
          status: DownloadStatus.failed,
        ));
      }

      // Clean up temp file
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return false;
    } finally {
      _cancelTokens.remove(modelName);
    }
  }

  /// Download all models
  Future<bool> downloadAllModels({
    Function(double)? onTotalProgress,
    Function(int, int)? onModelIndexChanged,
  }) async {
    final totalSize = MODEL_SIZES.values.reduce((a, b) => a + b);
    var downloadedSize = 0;

    final modelList = MODEL_URLS.keys.toList();
    var completedCount = 0;

    for (int i = 0; i < modelList.length; i++) {
      final modelName = modelList[i];

      // Check if already downloaded
      if (await isModelDownloaded(modelName)) {
        downloadedSize += MODEL_SIZES[modelName] ?? 0;
        onTotalProgress?.call(downloadedSize / totalSize);
        completedCount++;
        continue;
      }

      // Notify which model is being downloaded
      onModelIndexChanged?.call(completedCount + 1, modelList.length);

      // Download model
      final success = await downloadModel(
        modelName,
        onProgress: (progress) {
          final modelSize = MODEL_SIZES[modelName] ?? 0;
          final currentDownloaded = downloadedSize + (modelSize * progress).toInt();
          onTotalProgress?.call(currentDownloaded / totalSize);
        },
      );

      if (!success) {
        return false;
      }

      downloadedSize += MODEL_SIZES[modelName] ?? 0;
      completedCount++;
    }

    return true;
  }

  /// Cancel download
  void cancelDownload(String modelName) {
    final cancelToken = _cancelTokens[modelName];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled download');
    }
  }

  /// Cancel all downloads
  void cancelAllDownloads() {
    for (final cancelToken in _cancelTokens.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('User cancelled all downloads');
      }
    }
    _cancelTokens.clear();
  }

  /// Clear downloaded models
  Future<void> clearDownloadedModels() async {
    final modelDir = await getModelDirectory();
    final dir = Directory(modelDir);

    if (await dir.exists()) {
      await for (final file in dir.list()) {
        if (file is File && file.path.endsWith('.onnx')) {
          await file.delete();
          debugPrint('[ModelDownloader] Deleted: ${file.path}');
        }
      }
    }
  }

  /// Get total download size
  int getTotalDownloadSize() {
    return MODEL_SIZES.values.reduce((a, b) => a + b);
  }

  /// Get pending download size
  Future<int> getPendingDownloadSize() async {
    var pendingSize = 0;

    for (final entry in MODEL_SIZES.entries) {
      if (!await isModelDownloaded(entry.key)) {
        pendingSize += entry.value;
      }
    }

    return pendingSize;
  }

  void dispose() {
    cancelAllDownloads();
    _progressController.close();
  }

  /// Get all model paths (for initialization)
  Future<Map<String, String>> getModelPaths() async {
    final modelDir = await getModelDirectory();
    return {
      'detModel': '$modelDir/det_10g.onnx',
      'landmarkModel1': '',
      'landmarkModel2': '$modelDir/2d106det.onnx',
      'recModel': '$modelDir/w600k_r50.onnx',
      'spoofModel1': '$modelDir/fasnet_v1se.onnx',
      'spoofModel2': '$modelDir/fasnet_v2.onnx',
      // meanShape is optional - native library has fallback/default values
      'meanShape': '',
    };
  }
}
