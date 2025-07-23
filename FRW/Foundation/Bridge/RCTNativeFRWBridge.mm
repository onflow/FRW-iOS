#import "RCTNativeFRWBridge.h"
#import <AVFoundation/AVCaptureMetadataOutput.h>
#import <AVKit/AVCaptureEventInteraction.h>
#import <FirebaseMessaging/FirebaseMessaging.h>
#import <React-RCTAppDelegate/RCTDefaultReactNativeFactoryDelegate.h>
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

#if defined(TARGET_FRW)

#import "FRW-Swift.h"

#elif defined(TARGET_FRWDEV)

#import "FRW_dev-Swift.h"

#endif

@interface RCTNativeFRWBridge ()
@end

@implementation RCTNativeFRWBridge

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeFRWBridgeSpecJSI>(params);
}

+ (NSString *)moduleName {
  return @"NativeFRWBridge";
}

- (void)getJWT:(nonnull RCTPromiseResolveBlock)resolve
        reject:(nonnull RCTPromiseRejectBlock)reject {
  [TurboModuleSwift getJWTWithCompletionHandler:^(
                        NSString *_Nullable token, NSError *_Nullable error) {
    if (error) {
      reject(@"jwt_error", error.localizedDescription, error);
    } else {
      resolve(token);
    }
  }];
}

- (NSString * _Nullable)getNetwork {
    return [TurboModuleSwift getNetwork];
}

- (NSString * _Nullable)getSelectedAddress {
    return [TurboModuleSwift getCurrentAddress];
}

- (void)sign:(nonnull NSString *)hexData
      resolve:(nonnull RCTPromiseResolveBlock)resolve
      reject:(nonnull RCTPromiseRejectBlock)reject {
  [TurboModuleSwift signWithHexData:hexData completionHandler:^(NSString *_Nullable signature, NSError *_Nullable error) {
    if (error) {
      reject(@"sign_error", error.localizedDescription, error);
    } else {
      resolve(signature);
    }
  }];
}

@end
