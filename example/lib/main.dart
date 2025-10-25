import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_face_kit/flutter_face_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'pages/simple/simple_register_page.dart';
import 'pages/simple/simple_rec_page.dart';
import 'pages/advanced/face_register_page.dart';
import 'pages/advanced/face_rec_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  bool _isInitialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Preparing...';
  bool _isStatusExpanded = true;

  bool _isModelDownloaded = false;
  bool _hasRegisteredFace = false;
  bool _useSimpleVersion = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {
        _useSimpleVersion = _tabController.index == 0;
      });
    });
    _checkAndInitialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAndInitialize() async {
    setState(() {
      _statusMessage = 'Checking AI models...';
    });

    final downloader = ModelDownloadManager();
    final allDownloaded = await downloader.areAllModelsDownloaded();

    setState(() {
      _isModelDownloaded = allDownloaded;
    });

    if (!allDownloaded) {
      setState(() {
        _statusMessage = 'AI models need to be downloaded';
      });
    } else {
      await _initializeFFI();
      await _checkRegisteredFace();
    }
  }

  Future<void> _checkRegisteredFace() async {
    try {
      final exists = await checkFaceJsonExists();

      if (exists) {
        setState(() {
          _hasRegisteredFace = true;
        });
        debugPrint('[Init] Found registered face feature file');
      } else {
        debugPrint('[Init] No face registered yet');
      }
    } catch (e) {
      debugPrint('[Init] Failed to check registration status: $e');
    }
  }

  Future<void> _downloadModels(BuildContext context) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'Starting AI model download...';
    });

    final downloader = ModelDownloadManager();

    final success = await downloader.downloadAllModels(
      onTotalProgress: (progress) {
        setState(() {
          _downloadProgress = progress;
          _statusMessage = 'Downloading... ${(progress * 100).toStringAsFixed(0)}%';
        });
      },
    );

    setState(() {
      _isDownloading = false;
    });

    if (success) {
      setState(() {
        _isModelDownloaded = true;
      });

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('AI models downloaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      await _initializeFFI();
    } else {
      setState(() {
        _statusMessage = 'Download failed, please try again';
      });
    }
  }

  Future<void> _initializeFFI() async {
    setState(() {
      _statusMessage = 'Initializing...';
    });

    try {
      final downloader = ModelDownloadManager();
      final paths = await downloader.getModelPaths();
      final directory = await getApplicationDocumentsDirectory();

      final featureFilePath = '${directory.path}/downloaded_file.json';

      final featureFile = File(featureFilePath);
      if (await featureFile.exists()) {
        final content = await featureFile.readAsString();
        debugPrint('[Init] Feature file exists');
        debugPrint('[Init] File size: ${content.length} bytes');
        debugPrint('[Init] File beginning: ${content.substring(0, content.length > 200 ? 200 : content.length)}');

        try {
          final jsonData = json.decode(content);
          if (jsonData is List) {
            debugPrint('[Init] JSON format correct: array format, contains ${jsonData.length} objects');
          } else {
            debugPrint('[Init] JSON format: not array format');
          }
        } catch (e) {
          debugPrint('[Init] JSON parsing failed: $e');
        }
      } else {
        debugPrint('[Init] Feature file does not exist');
      }

      FaceRecognitionBridge.instance.initializeConfig(
        '',
        paths['detModel']!,
        paths['landmarkModel1']!,
        paths['landmarkModel2']!,
        paths['recModel']!,
        paths['spoofModel1']!,
        paths['spoofModel2']!,
        paths['meanShape']!,
        featureFilePath,
      );

      debugPrint('[Init] Feature file path: $featureFilePath');

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Initialization successful!';
      });

      final testResult = FaceRecognitionBridge.instance.add(1, 2);
      debugPrint('FFI test: 1 + 2 = $testResult');

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isStatusExpanded = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Face Kit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Flutter Face Kit',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'On-Device Face Recognition',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Status Card
                  _buildStatusCard(),
                  SizedBox(height: 24),

                  // Function Cards
                  if (_isInitialized) ...[
                    Text(
                      'Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.blue.shade900,
                        unselectedLabelColor: Colors.grey.shade600,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            icon: Icon(Icons.rocket_launch),
                            text: 'Simple',
                          ),
                          Tab(
                            icon: Icon(Icons.settings),
                            text: 'Advanced',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildFeatureCard(
                      icon: Icons.download_rounded,
                      iconColor: Colors.green,
                      title: 'Download Models',
                      description: 'Manage AI models',
                      isCompleted: _isModelDownloaded,
                      onTap: () {
                        // Navigate to download page
                      },
                    ),
                    SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.person_add_rounded,
                      iconColor: Colors.blue,
                      title: 'Register Face',
                      description: 'Add new face to database',
                      isCompleted: _hasRegisteredFace,
                      onTap: () async {
                        if (mounted) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _useSimpleVersion
                                  ? SimpleRegisterPage()
                                  : FaceRegisterPage(),
                            ),
                          );
                          if (result != null && mounted) {
                            setState(() {
                              _hasRegisteredFace = true;
                            });
                            debugPrint('Registration result: $result');
                          }
                        }
                      },
                    ),
                    SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.face_rounded,
                      iconColor: Colors.purple,
                      title: 'Recognize Face',
                      description: 'Identify registered faces',
                      isEnabled: _hasRegisteredFace,
                      onTap: _hasRegisteredFace ? () async {
                        if (mounted) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _useSimpleVersion
                                  ? SimpleRecPage()
                                  : FaceRecPage(),
                            ),
                          );
                          if (result != null) {
                            debugPrint('Recognition result: $result');
                          }
                        }
                      } : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isReady = _isInitialized;
    final statusColor = isReady ? Colors.green : Colors.orange;
    final statusIcon = isReady ? Icons.check_circle : Icons.pending;

    return GestureDetector(
      onTap: isReady ? () {
        setState(() {
          _isStatusExpanded = !_isStatusExpanded;
        });
      } : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isReady
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.orange.shade50, Colors.orange.shade100],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isReady ? Colors.green.shade200 : Colors.orange.shade200,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isReady && !_isStatusExpanded) ...[
              Row(
                children: [
                  Icon(statusIcon, size: 28, color: statusColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'System Ready',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ] else ...[
              if (_isDownloading) ...[
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _downloadProgress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, size: 48, color: statusColor),
                    if (isReady) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (!_isInitialized && !_isDownloading) ...[
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) => ElevatedButton.icon(
                      onPressed: () => _downloadModels(context),
                      icon: Icon(Icons.download_rounded),
                      label: Text('Download AI Models'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback? onTap,
    bool isCompleted = false,
    bool isEnabled = true,
  }) {
    final effectiveIconColor = isEnabled ? iconColor : Colors.grey;
    final effectiveTextColor = isEnabled ? Colors.black : Colors.grey.shade400;
    final effectiveDescColor = isEnabled ? Colors.grey.shade600 : Colors.grey.shade300;

    return Card(
      color: isEnabled ? null : Colors.grey.shade50,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: effectiveIconColor),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: effectiveTextColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: effectiveDescColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.chevron_right,
                color: isCompleted
                  ? Colors.green
                  : (isEnabled ? Colors.grey.shade400 : Colors.grey.shade300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
