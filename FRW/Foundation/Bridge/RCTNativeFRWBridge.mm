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

- (NSString *)getVersion {
    return [TurboModuleSwift getVersion];
}

- (NSString *)getBuildNumber {
    return [TurboModuleSwift getBuildNumber];
}

- (NSString *)getNetwork {
    return [TurboModuleSwift getNetwork];
}

- (void)getCurrentUserUid:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    resolve([TurboModuleSwift getCurrentUserUid]);
}

- (NSString * _Nullable)getSelectedAddress {
    return [TurboModuleSwift getCurrentAddress];
}

- (NSString * _Nullable)getDebugAddress {
  return [TurboModuleSwift getDebugAddress];
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

- (void)signRotationRequest:(NSString *)address
              signatureData:(NSString *)signatureData
                    resolve:(RCTPromiseResolveBlock)resolve
                     reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift signRotationRequestWithAddress:address signatureData:signatureData completionHandler:^(NSDictionary<NSString *,id> * _Nullable info, NSError * _Nullable error) {
    if (error) {
      reject(@"sign_rotation_error", error.localizedDescription, error);
    } else {
      resolve(info);
    }
  }];
}

- (void)removeOldKey:(nonnull NSString *)address
         publicKey:(nonnull NSString *)publicKey
             resolve:(nonnull RCTPromiseResolveBlock)resolve
              reject:(nonnull RCTPromiseRejectBlock)reject {
  [TurboModuleSwift removeOldKeyWithAddress:address
                                publicKey:publicKey
                          completionHandler:^(NSError *_Nullable error) {
    if (error) {
      reject(@"remove_old_key_error", error.localizedDescription, error);
    } else {
      resolve(nil);
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

- (void)closeRN:(NSString * _Nullable)id; {
  [TurboModuleSwift closeRNWithId:id];
}

- (void)isFreeGasEnabled:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  resolve(@([TurboModuleSwift isFreeGasEnabled]));
}

- (void)listenTransaction:(NSString *)txid {
  [TurboModuleSwift listenTransactionWithTxid:txid];
}

- (NSDictionary *)getEnv {
  return [TurboModuleSwift getEnv];
}

- (void)getSelectedAccount:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift getSelectedWalletAccountWithCompletionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
    if (error) {
      reject(@"selected account", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
  
}

- (void)getMigrationAssets:(NSString *)sourceAddress
                   resolve:(RCTPromiseResolveBlock)resolve
                    reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift getMigrationAssetsWithSourceAddress:sourceAddress
                                     completionHandler:^(NSDictionary<NSString *,id> * _Nullable result,
                                                         NSError * _Nullable error) {
    if (error) {
      reject(@"migration_assets_error", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}

- (void)refreshCoaAfterMigration:(RCTPromiseResolveBlock)resolve
                          reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift refreshCoaAfterMigrationWithCompletionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"refresh_coa_after_migration_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (NSDictionary *)getCurrency {
  return [TurboModuleSwift getCurrency];
}

- (NSString *)getTokenRate:(NSString *)token {
  return @([TurboModuleSwift getTokenRateWithTokenId:token]).stringValue;
}

- (void)getWalletProfiles:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  
  [TurboModuleSwift getWalletProfilesWithCompletionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
    if (error) {
      reject(@"get wallet profile", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}

- (void)clearAllToasts { 
  return [TurboModuleSwift clearAllToasts];
}

- (void)hideToast:(NSString *)toastId { 
  return [TurboModuleSwift hideToastWithId: toastId];
}

- (void)showToast:(NSString *)title
          message:(NSString * _Nullable)message
             type:(NSString *)type
         duration:(NSNumber *)duration {
  return [TurboModuleSwift showToastWithTitle:title message:message type:type duration:duration.intValue];
}

- (NSString *)getLanguage {
  return [TurboModuleSwift getLanguage];
}

- (void)logToNative:(NSString *)level message:(NSString *)message args:(NSArray *)args {
  [TurboModuleSwift logToNativeWithLevel:level message:message args:args];
}

- (void)ethSign:(NSString *)hexData resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    NSString *result = [TurboModuleSwift ethSign:hexData];
    if (result == nil) {
      NSError *error = [NSError errorWithDomain:@"NativeFRWBridge" 
                                           code:-1 
                                       userInfo:@{NSLocalizedDescriptionKey: @"Failed to sign data with Ethereum signature"}];
      reject(@"eth_sign_error", @"Failed to sign data with Ethereum signature", error);
    } else {
      resolve(result);
    }
}
//TODO: screenName
- (void)launchNativeScreen:(NSString *)screenName params:(NSString * _Nullable)params {
  [TurboModuleSwift launchNativeScreenWithScreen:screenName params:params];
}

// MARK: - Device Info
- (NSString *)getDeviceId {
  return [TurboModuleSwift getDeviceId];
}

// MARK: - Notification Permissions
- (void)requestNotificationPermission:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift requestNotificationPermissionWithCompletionHandler:^(BOOL granted, NSError * _Nullable error) {
    if (error) {
      reject(@"notification_permission_error", error.localizedDescription, error);
    } else {
      resolve(@(granted));
    }
  }];
}
// MARK: - Key Rotation (Seed Phrase)

- (void)createSeedKey:(double)strength
               resolve:(nonnull RCTPromiseResolveBlock)resolve
                reject:(nonnull RCTPromiseRejectBlock)reject {
  [TurboModuleSwift createSeedKeyWithStrength:strength
                           completionHandler:^(NSDictionary<NSString *,id> * _Nullable result,
                                               NSError * _Nullable error) {
    if (error) {
      reject(@"create_seed_key_error", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}

- (void)saveNewKey:(JS::NativeFRWBridge::NewKeyInfo &)key resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift saveNewKeyWithSeedphrase:key.seedphrase() completionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"save_new_key_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (void)checkNotificationPermission:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift checkNotificationPermissionWithCompletionHandler:^(BOOL granted, NSError * _Nullable error) {
    if (error) {
      reject(@"notification_permission_error", error.localizedDescription, error);
    } else {
      resolve(@(granted));
    }
  }];
}

// MARK: - Screen Security
- (void)setScreenSecurityLevel:(NSString *)level {
  [TurboModuleSwift setScreenSecurityLevelWithLevel:level];
}

// MARK: - Onboarding Methods
- (void)generateSeedPhrase:(NSNumber *)strength resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift generateSeedPhraseWithStrength:strength completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
    if (error) {
      reject(@"seed_phrase_generation_error", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}

- (void)registerSecureTypeAccount:(NSString *)username resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift registerSecureTypeAccountWithUsername:username completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
    if (error) {
      reject(@"register_account_error", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}

- (void)initSecureEnclaveWallet:(NSString *)txId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift initSecureEnclaveWalletWithTxId:txId completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
    if (error) {
      reject(@"init_wallet_error", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}

- (void)signInWithCustomToken:(NSString *)customToken resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift signInWithCustomTokenWithCustomToken:customToken completionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"sign_in_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (void)saveMnemonic:(NSString *)mnemonic customToken:(NSString *)customToken txId:(NSString *)txId username:(NSString *)username evmAddress:(NSString *)evmAddress resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift saveMnemonicWithMnemonic:mnemonic customToken:customToken txId:txId username:username evmAddress:evmAddress completionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"save_mnemonic_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (void)getRecoverableProfiles:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift getRecoverableProfilesWithCompletionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
    if (error) {
      reject(@"get_recoverable_profiles_error", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}

- (void)switchToProfile:(NSString *)userId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift switchToProfileWithUserId:userId completionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"switch_profile_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (void)shareQRCode:(NSString *)address qrCodeDataUrl:(NSString *)qrCodeDataUrl resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift shareQRCodeWithAddress:address qrCodeDataUrl:qrCodeDataUrl completionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"share_qr_error", error.localizedDescription, error);
    } else {
      resolve(nil);
    }
  }];
}

- (void)getV4RegistrationSignatures:(NSString *)mnemonic resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  [TurboModuleSwift getV4RegisteredSignatureWithMnemonic:mnemonic completionHandler:^(NSDictionary<NSString *,id> * _Nullable result, NSError * _Nullable error) {
    if (error) {
      reject(@"fet signature fail for regist v4 ", error.localizedDescription, error);
    } else {
      resolve(result);
    }
  }];
}



@end
