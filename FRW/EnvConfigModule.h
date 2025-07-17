#import <React/RCTBridgeModule.h>
#import <Foundation/Foundation.h>

@interface EnvConfigModule : NSObject <RCTBridgeModule>

+ (NSString *)getEnvVar:(NSString *)key;
+ (BOOL)isDebugMode;
+ (NSString *)getApiBaseUrl;
+ (NSString *)getApiKey;
+ (NSString *)getEnvironment;
+ (NSString *)getFlowNetwork;
+ (NSString *)getFlowAccessNodeUrl;
+ (NSString *)getFlowDiscoveryWalletUrl;

@end 