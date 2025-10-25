import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'face_rec_page_vm.dart';

class FaceRecPage extends StatefulWidget {
  const FaceRecPage({Key? key}) : super(key: key);

  @override
  State<FaceRecPage> createState() => _FaceRecPageState();
}

class _FaceRecPageState extends State<FaceRecPage> {
  late FaceRecPageVM vm;

  @override
  void initState() {
    super.initState();
    vm = FaceRecPageVM();
    vm.init();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FaceRecPageVM>.value(
      value: vm,
      child: Consumer<FaceRecPageVM>(
        builder: (context, vm, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.recognitionStatus.isNotEmpty) {
              didReceiveRecStatus(context, vm);
            }
          });

          if (!vm.isReady) {
            return Scaffold(
              appBar: AppBar(title: const Text("Face Recognition")),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return _buildMainContent(context, vm);
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, FaceRecPageVM vm) {
    if (vm.controller == null || !vm.controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text("Face Recognition")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic object) async {
        if (didPop) {
          await vm.safeDisposeCamera();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("Face Recognition"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Transform(
                alignment: Alignment.center,
                transform: (vm.controller!.description.lensDirection ==
                        CameraLensDirection.front)
                    ? Matrix4.identity()
                    : (Matrix4.identity()..setEntry(0, 0, -1)),
                child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                        width: vm.controller!.value.previewSize!.height,
                        height: vm.controller!.value.previewSize!.width,
                        child: CameraPreview(vm.controller!))),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vm.detString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    if (vm.isDetectionOn)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> didReceiveRecStatus(
      BuildContext context, FaceRecPageVM vm) async {
    String sts = vm.recognitionStatus;
    debugPrint('didReceiveRecStatus : $sts');

    if (sts == 'success') {
      _showSuccessAndAutoClose(context, vm);
      return;
    }

    if (sts == 'fail') {
      vm.recognitionStatus = '';

      try {
        final confirmed = await _showCustomResultDialog(
          context,
          title: 'Recognition Failed',
          message: 'Unable to recognize registered face\nPlease try again',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          iconBorderColor: Colors.red,
          confirmLabel: 'Try Again',
          confirmColor: Colors.blue,
        );

        await Future.delayed(Duration(milliseconds: 300));

        if (confirmed == true) {
          debugPrint('User chose to retry recognition');
          vm.isDetectionOn = true;
        }
      } catch (e) {
        debugPrint('Error handling recognition failure dialog: $e');
        vm.recognitionStatus = '';
        vm.isDetectionOn = true;
      }
    }
  }

  Future<void> _safeExitWithResult(BuildContext context, FaceRecPageVM vm,
      Map<String, dynamic> result) async {
    try {
      debugPrint('Starting safe exit process');

      await vm.safeDisposeCamera();
      debugPrint('Camera resources released');

      await Future.delayed(Duration(milliseconds: 100));

      if (!context.mounted) {
        debugPrint('Context no longer mounted, cannot return');
        return;
      }

      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(result);
        debugPrint('Safely returned');
      } else {
        debugPrint('Cannot return, Navigator stack error');
      }
    } catch (e) {
      debugPrint('Error during safe exit: $e');

      try {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(result);
        }
      } catch (forceError) {
        debugPrint('Force return also failed: $forceError');
      }
    }
  }

  void _showSuccessAndAutoClose(BuildContext context, FaceRecPageVM vm) {
    vm.recognitionStatus = '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Recognition Successful!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Future.delayed(Duration(seconds: 1), () async {
      final result = {
        'status': 'success',
      };

      await _safeExitWithResult(context, vm, result);
    });
  }

  Future<bool?> _showCustomResultDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color iconBorderColor,
    required String confirmLabel,
    required Color confirmColor,
    String? cancelLabel,
    Color? cancelColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 56),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (cancelLabel != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            minimumSize: const Size.fromHeight(40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(confirmLabel,
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cancelColor,
                            minimumSize: const Size.fromHeight(40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(cancelLabel,
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        confirmLabel,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
