import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'face_register_page_vm.dart';

class FaceRegisterPage extends StatefulWidget {
  const FaceRegisterPage({Key? key}) : super(key: key);

  @override
  State<FaceRegisterPage> createState() => _FaceRegisterPageState();
}

class _FaceRegisterPageState extends State<FaceRegisterPage> {
  late FaceRegisterPageVM vm;

  @override
  void initState() {
    super.initState();
    vm = FaceRegisterPageVM();
    vm.init();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FaceRegisterPageVM>.value(
      value: vm,
      child: Consumer<FaceRegisterPageVM>(
        builder: (context, vm, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.registrationStatus.isNotEmpty) {
              didReceiveRegisterStatus(context, vm);
            }
          });

          if (!vm.isReady) {
            return Scaffold(
              appBar: AppBar(title: const Text("Face Registration")),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return _buildMainContent(context, vm);
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, FaceRegisterPageVM vm) {
    if (vm.controller == null || !vm.controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text("Face Registration")),
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
          title: Text("Face Registration"),
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

  Future<void> didReceiveRegisterStatus(
      BuildContext context, FaceRegisterPageVM vm) async {
    String sts = vm.registrationStatus;
    debugPrint('didReceiveRegisterStatus : $sts');

    if (sts == 'success') {
      _showSuccessAndAutoClose(context, vm);
      return;
    }
  }

  Future<void> _safeExitWithResult(BuildContext context, FaceRegisterPageVM vm,
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

  void _showSuccessAndAutoClose(BuildContext context, FaceRegisterPageVM vm) {
    vm.registrationStatus = '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Registration Successful!',
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
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Future.delayed(Duration(seconds: 2), () async {
      final result = {
        'status': 'success',
      };

      await _safeExitWithResult(context, vm, result);
    });
  }
}
