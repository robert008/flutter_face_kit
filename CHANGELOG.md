## 1.0.1 (2025-10-22)

### Initial Release

**Core Features:**
* On-device face recognition with InsightFace AI models
* Real-time face detection with Buffalo_L model
* 106-point facial landmark extraction
* Face feature extraction and matching
* Anti-spoofing detection support

**Platform Support:**
* iOS 12.0+ support with static library integration
* Android API 21+ support with JNI libraries
* Cross-platform ONNX model inference

**Example App:**
* Simple version using Service API (easy integration)
* Advanced version with custom isolate (performance optimization)
* Tab-based UI to switch between Simple and Advanced modes
* Real-time camera preview and face processing

**Architecture:**
* FFI-based native library integration
* Isolate support for non-blocking AI inference
* Strongly-typed Result models
* Model download manager with cloud storage support

**Performance:**
* Complete face recognition pipeline < 500ms
* Optimized image conversion and processing
* Automatic resolution adjustment for performance
