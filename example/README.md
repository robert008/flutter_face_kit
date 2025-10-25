# Flutter Face Kit Example

This example demonstrates how to use the Flutter Face Kit plugin for on-device face recognition.

## Features

The example app includes two implementation approaches:

### Advanced Mode (Default)
- **Custom Isolate Processing**: Optimal performance with manual isolate management
- **Real-time Camera Stream**: Continuous frame processing with automatic frame skipping
- **Dynamic Resolution Adjustment**: Automatically adjusts camera resolution based on device performance
- **Performance Monitoring**: Tracks conversion times and optimizes accordingly
- Best for: Production apps requiring maximum performance and control

### Simple Mode
- **Service API**: Easy-to-use high-level API with built-in isolate support
- **Manual Capture**: User-triggered photo capture for processing
- **Simplified Code**: Minimal setup with automatic background processing
- Best for: Quick prototyping and simpler use cases

Switch between modes using the tabs at the top of the main screen.

## Prerequisites

### iOS
- iOS 12.0 or later
- Xcode 12.0 or later
- Physical device recommended (face recognition works better on real devices)

### Android
- Android 5.0 (API level 21) or later
- Minimum 2GB RAM recommended
- Physical device recommended

## Getting Started

### 1. Install Dependencies

```bash
cd example
flutter pub get
```

### 2. Download AI Models

On first launch, the app will prompt you to download the required AI models (~60MB total):
- Face Detection Model (det_10g.onnx)
- Face Recognition Model (w600k_r50.onnx)
- Landmark Detection Model (2d106det.onnx)
- Anti-Spoofing Models (fasnet_v1se.onnx, fasnet_v2.onnx)

The models will be automatically downloaded and saved to the device.

### 3. Grant Permissions

The app requires the following permissions:
- **Camera**: For capturing face images
- **Storage**: For saving/loading face data and AI models

Permissions will be requested automatically on first use.

### 4. Run the App

```bash
flutter run
```

Or use your IDE's run button.

## Using the App

### Step 1: Download Models
1. Launch the app
2. Tap "Download AI Models" button
3. Wait for download to complete (~60MB)
4. App will initialize automatically

### Step 2: Register a Face
1. Select "Advanced" or "Simple" mode using the tabs
2. Tap "Register Face" card
3. **Advanced Mode**: Position your face in front of camera, processing starts automatically
4. **Simple Mode**: Position your face and tap "Capture & Register"
5. Wait for "Registration successful" message

### Step 3: Recognize Face
1. Tap "Recognize Face" card (enabled after registration)
2. **Advanced Mode**: Position your face, recognition happens automatically
3. **Simple Mode**: Position your face and tap "Capture & Recognize"
4. Result will be displayed immediately

## Project Structure

```
example/
├── lib/
│   ├── main.dart                          # App entry point with tab navigation
│   └── pages/
│       ├── simple/                        # Simple mode implementations
│       │   ├── simple_register_page.dart  # Registration using Service API
│       │   └── simple_rec_page.dart       # Recognition using Service API
│       └── advanced/                      # Advanced mode implementations
│           ├── face_register_page.dart    # Registration with custom isolate
│           ├── face_register_page_vm.dart # Registration view model
│           ├── face_rec_page.dart         # Recognition with custom isolate
│           └── face_rec_page_vm.dart      # Recognition view model
```

## Performance Tips

### For Best Results:
- Use good lighting conditions
- Keep face within camera frame
- Maintain steady position during capture
- Use physical device (emulators may have reduced performance)

### Advanced Mode Performance:
- Automatically adjusts resolution on slower devices
- Skips frames to maintain UI responsiveness
- Monitors conversion times for optimization
- Typical processing time: 200-500ms per frame

### Simple Mode Performance:
- Processes single frame per capture
- All processing happens in background isolate
- Typical processing time: 500-1000ms per capture

## Troubleshooting

### Models Not Downloading
- Check internet connection
- Ensure sufficient storage space (at least 100MB free)
- Try restarting the app

### Camera Not Working
- Grant camera permissions in device settings
- Restart the app after granting permissions
- Check if camera is being used by another app

### Recognition Fails
- Ensure face is well-lit and clearly visible
- Try re-registering the face
- Check that models are fully downloaded

### App Crashes on Launch
- Clear app data and reinstall
- Ensure device meets minimum requirements (iOS 12+ or Android 5+)
- Check Xcode/Android Studio console for error messages

## Platform-Specific Notes

### iOS
- Camera permission is required before first use
- Models are saved in app's Documents directory
- Background processing may be limited by iOS

### Android
- Camera and storage permissions required
- Models are saved in app-specific external storage
- Requires arm64-v8a or armeabi-v7a architecture

## Code Examples

### Using Simple Mode (Service API)
```dart
// Registration
final result = await FaceRegistrationService.registerFace(
  imageBytes: imageBytes,
  userName: 'user',
);

if (result.success) {
  print('Registration successful!');
}

// Recognition
final result = await FaceRecognitionService.recognizeFace(
  imageBytes: imageBytes,
);

if (result.isRecognized) {
  print('Face recognized!');
}
```

### Using Advanced Mode (Custom Isolate)
See `FaceRegisterPageVM` and `FaceRecPageVM` for complete implementation examples with camera stream processing and performance optimization.

## Additional Resources

- [Flutter Face Kit Documentation](../README.md)
- [InsightFace Models](https://github.com/deepinsight/insightface)
- [Flutter Camera Plugin](https://pub.dev/packages/camera)

## Support

For issues or questions:
- Open an issue on [GitHub](https://github.com/robert008/flutter_face_kit/issues)
- Email: figo007007@gmail.com
