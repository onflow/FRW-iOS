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

// Native App Environment Variables
+ (NSString *)getDriveAesIv;
+ (NSString *)getDriveAesKey;
+ (NSString *)getWalletConnectProjectId;
+ (NSString *)getInstabugTokenDev;
+ (NSString *)getInstabugTokenProd;
+ (NSString *)getCrowdinProjectId;
+ (NSString *)getCrowdinApiToken;
+ (NSString *)getCrowdinDistribution;
+ (NSString *)getMixpanelTokenDev;
+ (NSString *)getMixpanelTokenProd;
+ (NSString *)getDropboxAppKeyDev;
+ (NSString *)getDropboxAppKeyProd;
+ (NSString *)getXSignatureKey;

@end 