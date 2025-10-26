#import "FaceKitPlugin.h"

extern int addNumbersC(int a, int b);
extern void initConfig(const char* pathImg, const char* detModelPath,
                       const char* landmarkModelPath1, const char* landmarkModelPath2,
                       const char* recognModelPath, const char* spoofModelPath1,
                       const char* spoofModelPath2, const char* meanShapePath,
                       const char* featurePath);
extern char* getRecMessage(const char* imagePath);
extern int accessImagePathC(const char* imagePath);
extern char* getDetectionMessage(void);
extern char* registerFace(const char* imagePath, const char* userName);

@implementation FaceKitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    NSLog(@"FlutterFaceKit registered with Flutter");
}

+ (void)load {
    NSLog(@"FlutterFaceKit: +load method called");

    // Force symbols to be exported by actually calling them
    volatile int test1 = addNumbersC(1, 1);
    volatile int test2 = accessImagePathC("/tmp/nonexistent");

    NSLog(@"FlutterFaceKit: Symbol tests completed: add=%d, access=%d", (int)test1, (int)test2);
}
@end