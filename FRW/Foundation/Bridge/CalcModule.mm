#import <React/RCTBridgeModule.h>
#import <React/RCTLog.h>
#import <ReactCommon/RCTTurboModule.h>
#import <React-RCTAppDelegate/RCTDefaultReactNativeFactoryDelegate.h>
#import <WebKit/WebKit.h>
#import <WebKit/WKUIDelegate.h>
#import <WebKit/WKNavigationDelegate.h>
#import <WebKit/WKNavigationAction.h>
#import <WebKit/WKScriptMessageHandler.h>
#import <FirebaseMessaging/FirebaseMessaging.h>
#import <AVKit/AVCaptureEventInteraction.h>
#import <AVFoundation/AVCaptureMetadataOutput.h>
#import "FRW-Swift.h"

@interface CalcModule : NSObject <RCTBridgeModule, RCTTurboModule>
@end

@implementation CalcModule

RCT_EXPORT_MODULE()

// Turbo Module synchronous methods
- (NSNumber *)add:(double)a b:(double)b {
    return [CalcModuleSwift addWithA:a b:b];
}

- (NSNumber *)subtract:(double)a b:(double)b {
    return [CalcModuleSwift subtractWithA:a b:b];
}

- (NSNumber *)multiply:(double)a b:(double)b {
    return [CalcModuleSwift multiplyWithA:a b:b];
}

- (NSNumber *)divide:(double)a b:(double)b {
    return [CalcModuleSwift divideWithA:a b:b];
}

- (NSDictionary *)getConstants {
    return [CalcModuleSwift getConstants];
}

// Required for RCTTurboModule
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::ObjCTurboModule>(params);
}

@end
