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

- (void)getWalletAccounts:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift getCurrentAllAccountsWithCompletionHandler:^(NSDictionary<NSString *,id> * _Nullable list, NSError * _Nullable error) {
      if (error) {
          reject(@"wallet error", error.localizedDescription,error);
      } else {
          resolve(list);
      }
  }];
}

- (void)getRecentContacts:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [TurboModuleSwift getRecentContactsWithCompletionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
        if (error) {
            reject(@"recent_error", error.localizedDescription, error);
        } else {
            resolve(result);
        }
    }];
}

- (void)getCOAFlowBalance:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([TurboModuleSwift getCOAFlowBalance]);
}

- (void)getAllEnvVars:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    @try {
        NSString *debugMode = [NSBundle.mainBundle objectForInfoDictionaryKey:@"DEBUG_MODE"];
        NSString *analyticsEnabled = [NSBundle.mainBundle objectForInfoDictionaryKey:@"ANALYTICS_ENABLED"];
        NSString *environment = [NSBundle.mainBundle objectForInfoDictionaryKey:@"ENVIRONMENT"];
        
        NSDictionary *envVars = @{
            @"API_BASE_URL": [NSBundle.mainBundle objectForInfoDictionaryKey:@"API_BASE_URL"] ?: @"",
            @"API_KEY": [NSBundle.mainBundle objectForInfoDictionaryKey:@"API_KEY"] ?: @"",
            @"DEBUG_MODE": @([debugMode.lowercaseString isEqualToString:@"true"]),
            @"APP_VERSION": [TurboModuleSwift getVersion],
            @"ANALYTICS_ENABLED": @([analyticsEnabled.lowercaseString isEqualToString:@"true"]),
            @"ENVIRONMENT": environment.length > 0 ? environment : @"production",
            @"FLOW_NETWORK": [NSBundle.mainBundle objectForInfoDictionaryKey:@"FLOW_NETWORK"] ?: @"mainnet",
            @"FLOW_ACCESS_NODE_URL": [NSBundle.mainBundle objectForInfoDictionaryKey:@"FLOW_ACCESS_NODE_URL"] ?: @"",
            @"FLOW_DISCOVERY_WALLET_URL": [NSBundle.mainBundle objectForInfoDictionaryKey:@"FLOW_DISCOVERY_WALLET_URL"] ?: @"",
            
            // Native App Environment Variables
            @"DRIVE_AES_IV": [NSBundle.mainBundle objectForInfoDictionaryKey:@"DRIVE_AES_IV"] ?: @"",
            @"DRIVE_AES_KEY": [NSBundle.mainBundle objectForInfoDictionaryKey:@"DRIVE_AES_KEY"] ?: @"",
            @"WALLET_CONNECT_PROJECT_ID": [NSBundle.mainBundle objectForInfoDictionaryKey:@"WALLET_CONNECT_PROJECT_ID"] ?: @"",
            @"INSTABUG_TOKEN_DEV": [NSBundle.mainBundle objectForInfoDictionaryKey:@"INSTABUG_TOKEN_DEV"] ?: @"",
            @"INSTABUG_TOKEN_PROD": [NSBundle.mainBundle objectForInfoDictionaryKey:@"INSTABUG_TOKEN_PROD"] ?: @"",
            @"CROWDIN_PROJECT_ID": [NSBundle.mainBundle objectForInfoDictionaryKey:@"CROWDIN_PROJECT_ID"] ?: @"",
            @"CROWDIN_API_TOKEN": [NSBundle.mainBundle objectForInfoDictionaryKey:@"CROWDIN_API_TOKEN"] ?: @"",
            @"CROWDIN_DISTRIBUTION": [NSBundle.mainBundle objectForInfoDictionaryKey:@"CROWDIN_DISTRIBUTION"] ?: @"",
            @"MIXPANEL_TOKEN_DEV": [NSBundle.mainBundle objectForInfoDictionaryKey:@"MIXPANEL_TOKEN_DEV"] ?: @"",
            @"MIXPANEL_TOKEN_PROD": [NSBundle.mainBundle objectForInfoDictionaryKey:@"MIXPANEL_TOKEN_PROD"] ?: @"",
            @"DROPBOX_APP_KEY_DEV": [NSBundle.mainBundle objectForInfoDictionaryKey:@"DROPBOX_APP_KEY_DEV"] ?: @"",
            @"DROPBOX_APP_KEY_PROD": [NSBundle.mainBundle objectForInfoDictionaryKey:@"DROPBOX_APP_KEY_PROD"] ?: @"",
            @"X_SIGNATURE_KEY": [NSBundle.mainBundle objectForInfoDictionaryKey:@"X_SIGNATURE_KEY"] ?: @""
        };
        resolve(envVars);
    } @catch (NSException *exception) {
        reject(@"ENV_ERROR", @"Failed to get environment variables", nil);
    }
}

- (NSString *)getVersion {
    return [TurboModuleSwift getVersion];
}

- (NSString *)getBuildNumber {
    return [TurboModuleSwift getBuildNumber];
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
