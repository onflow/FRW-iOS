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
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSDictionary *infoDict = [mainBundle infoDictionary];
        
        // Log all available keys for debugging
        NSLog(@"Available Info.plist keys: %@", [infoDict allKeys]);
        
        // Try to read environment variables from Info.plist
        NSMutableDictionary *envVars = [NSMutableDictionary dictionary];
        
        // Define the keys we're looking for
        NSArray *envKeys = @[
            @"API_BASE_URL", @"API_KEY", @"DEBUG_MODE", @"APP_VERSION", 
            @"ANALYTICS_ENABLED", @"ENVIRONMENT", @"FLOW_NETWORK",
            @"FLOW_ACCESS_NODE_URL", @"FLOW_DISCOVERY_WALLET_URL",
            @"DRIVE_AES_IV", @"DRIVE_AES_KEY", @"WALLET_CONNECT_PROJECT_ID",
            @"INSTABUG_TOKEN_DEV", @"INSTABUG_TOKEN_PROD", @"CROWDIN_PROJECT_ID",
            @"CROWDIN_API_TOKEN", @"CROWDIN_DISTRIBUTION", @"MIXPANEL_TOKEN_DEV",
            @"MIXPANEL_TOKEN_PROD", @"DROPBOX_APP_KEY_DEV", @"DROPBOX_APP_KEY_PROD",
            @"X_SIGNATURE_KEY"
        ];
        
        for (NSString *key in envKeys) {
            id value = [infoDict objectForKey:key];
            if (value) {
                [envVars setObject:value forKey:key];
                NSLog(@"Found env var %@: %@", key, value);
            } else {
                // If not found in Info.plist, use default values from .env.development
                if ([key isEqualToString:@"API_BASE_URL"]) {
                    [envVars setObject:@"https://api.dev.com" forKey:key];
                } else if ([key isEqualToString:@"API_KEY"]) {
                    [envVars setObject:@"dev_key_123" forKey:key];
                } else if ([key isEqualToString:@"DEBUG_MODE"]) {
                    [envVars setObject:@YES forKey:key];
                } else if ([key isEqualToString:@"APP_VERSION"]) {
                    [envVars setObject:@"1.0.0-dev" forKey:key];
                } else if ([key isEqualToString:@"ANALYTICS_ENABLED"]) {
                    [envVars setObject:@NO forKey:key];
                } else if ([key isEqualToString:@"ENVIRONMENT"]) {
                    [envVars setObject:@"development" forKey:key];
                } else if ([key isEqualToString:@"FLOW_NETWORK"]) {
                    [envVars setObject:@"testnet" forKey:key];
                } else if ([key isEqualToString:@"FLOW_ACCESS_NODE_URL"]) {
                    [envVars setObject:@"https://rest-testnet.onflow.org" forKey:key];
                } else if ([key isEqualToString:@"FLOW_DISCOVERY_WALLET_URL"]) {
                    [envVars setObject:@"https://fcl-discovery.onflow.org/testnet/authn" forKey:key];
                } else {
                    [envVars setObject:[NSString stringWithFormat:@"dev_%@_here", [key lowercaseString]] forKey:key];
                }
                NSLog(@"Using default value for %@: %@", key, [envVars objectForKey:key]);
            }
        }
        
        NSLog(@"Final env vars: %@", envVars);
        resolve(envVars);
    } @catch (NSException *exception) {
        NSLog(@"Error getting environment variables: %@", exception);
        reject(@"ENV_ERROR", @"Failed to get environment variables", nil);
    }
}

- (NSString *)getVersion {
    return [TurboModuleSwift getVersion];
}

- (NSString *)getBuildNumber {
    return [TurboModuleSwift getBuildNumber];
}

- (NSString *)getNetwork {
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

- (NSNumber *)getSignKeyIndex {
  return @([TurboModuleSwift getSignKeyIndex]);
}

- (void)scanQRCode:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  
  [TurboModuleSwift scanQRCodeWithCompletionHandler:^(NSString * _Nullable address, NSError * _Nullable error) {
    if (error) {
      reject(@"sign_error", error.localizedDescription, error);
    } else {
      resolve(address);
    }
  }];
}

- (void)closeRN {
  [TurboModuleSwift closeRN];
}

- (void)isFreeGasEnabled:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  resolve(@([TurboModuleSwift isFreeGasEnabled]));
}

- (void)listenTransaction:(NSString *)txid {
  [TurboModuleSwift listenTransactionWithTxid:txid];
}

@end
