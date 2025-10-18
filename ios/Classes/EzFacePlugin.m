#import "EzFacePlugin.h"

// ==================== 函數聲明 ====================
// 基於靜態庫符號檢查結果，使用正確的函數名
extern int addNumbersC(int a, int b);
extern void initConfig(const char* pathImg, const char* detModelPath,
                       const char* landmarkModelPath1, const char* landmarkModelPath2,
                       const char* recognModelPath, const char* spoofModelPath1,
                       const char* spoofModelPath2, const char* meanShapePath,
                       const char* featurePath);
extern char* getRecMessage(const char* imagePath);
extern int accessImagePathC(const char* imagePath);  // 注意：是 accessImagePathC
extern char* getDetectionMessage(void);

@implementation EzFacePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    NSLog(@"FlutterFaceKit registered with Flutter");
}
@end

// ==================== TestFlight 符號保護 ====================
__attribute__((constructor))
static void register_symbols_for_testflight(void) {
    NSLog(@"EzFacePlugin: Starting TestFlight symbol protection...");

    // 🔥 修復：移除 volatile，使用正確的函數指針類型
    int (*addFunc)(int, int) = addNumbersC;
    void (*initFunc)(const char*, const char*, const char*, const char*, const char*, const char*, const char*, const char*, const char*) = initConfig;
    char* (*recFunc)(const char*) = getRecMessage;
    int (*accessFunc)(const char*) = accessImagePathC;  // 使用正確的函數名
    char* (*detectFunc)(void) = getDetectionMessage;

    // 簡單的測試調用
    if (addFunc) {
        int test_result = addFunc(0, 0);
        NSLog(@"EzFacePlugin: Basic FFI test completed, result: %d", test_result);
    }

    // 確保所有函數指針都被引用
    if (addFunc && initFunc && recFunc && accessFunc && detectFunc) {
        NSLog(@"EzFacePlugin: All 5 FFI symbols protected for TestFlight");
    } else {
        NSLog(@"EzFacePlugin: Warning - Some symbols may not be available");
    }

    NSLog(@"EzFacePlugin: TestFlight symbol protection completed");
}