#import "EnvConfigModule.h"
#import <React/RCTLog.h>

@implementation EnvConfigModule

RCT_EXPORT_MODULE();

+ (NSString *)getEnvVar:(NSString *)key {
    NSString *value = [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
    return value ?: @"";
}

+ (BOOL)isDebugMode {
    NSString *debugMode = [self getEnvVar:@"DEBUG_MODE"];
    return [debugMode.lowercaseString isEqualToString:@"true"];
}

+ (NSString *)getApiBaseUrl {
    return [self getEnvVar:@"API_BASE_URL"];
}

+ (NSString *)getApiKey {
    return [self getEnvVar:@"API_KEY"];
}

+ (NSString *)getEnvironment {
    NSString *env = [self getEnvVar:@"ENVIRONMENT"];
    return env.length > 0 ? env : @"production";
}

+ (NSString *)getFlowNetwork {
    NSString *network = [self getEnvVar:@"FLOW_NETWORK"];
    return network.length > 0 ? network : @"mainnet";
}

+ (NSString *)getFlowAccessNodeUrl {
    return [self getEnvVar:@"FLOW_ACCESS_NODE_URL"];
}

+ (NSString *)getFlowDiscoveryWalletUrl {
    return [self getEnvVar:@"FLOW_DISCOVERY_WALLET_URL"];
}

// Native App Environment Variables
+ (NSString *)getDriveAesIv {
    return [self getEnvVar:@"DRIVE_AES_IV"];
}

+ (NSString *)getDriveAesKey {
    return [self getEnvVar:@"DRIVE_AES_KEY"];
}

+ (NSString *)getWalletConnectProjectId {
    return [self getEnvVar:@"WALLET_CONNECT_PROJECT_ID"];
}

+ (NSString *)getInstabugTokenDev {
    return [self getEnvVar:@"INSTABUG_TOKEN_DEV"];
}

+ (NSString *)getInstabugTokenProd {
    return [self getEnvVar:@"INSTABUG_TOKEN_PROD"];
}

+ (NSString *)getCrowdinProjectId {
    return [self getEnvVar:@"CROWDIN_PROJECT_ID"];
}

+ (NSString *)getCrowdinApiToken {
    return [self getEnvVar:@"CROWDIN_API_TOKEN"];
}

+ (NSString *)getCrowdinDistribution {
    return [self getEnvVar:@"CROWDIN_DISTRIBUTION"];
}

+ (NSString *)getMixpanelTokenDev {
    return [self getEnvVar:@"MIXPANEL_TOKEN_DEV"];
}

+ (NSString *)getMixpanelTokenProd {
    return [self getEnvVar:@"MIXPANEL_TOKEN_PROD"];
}

+ (NSString *)getDropboxAppKeyDev {
    return [self getEnvVar:@"DROPBOX_APP_KEY_DEV"];
}

+ (NSString *)getDropboxAppKeyProd {
    return [self getEnvVar:@"DROPBOX_APP_KEY_PROD"];
}

+ (NSString *)getXSignatureKey {
    return [self getEnvVar:@"X_SIGNATURE_KEY"];
}

RCT_EXPORT_METHOD(getAllEnvVars:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSDictionary *envVars = @{
            @"API_BASE_URL": [self getApiBaseUrl],
            @"API_KEY": [self getApiKey],
            @"DEBUG_MODE": @([self isDebugMode]),
            @"APP_VERSION": [self getEnvVar:@"APP_VERSION"],
            @"ANALYTICS_ENABLED": @([[self getEnvVar:@"ANALYTICS_ENABLED"].lowercaseString isEqualToString:@"true"]),
            @"ENVIRONMENT": [self getEnvironment],
            @"FLOW_NETWORK": [self getFlowNetwork],
            @"FLOW_ACCESS_NODE_URL": [self getFlowAccessNodeUrl],
            @"FLOW_DISCOVERY_WALLET_URL": [self getFlowDiscoveryWalletUrl],
            
            // Native App Environment Variables
            @"DRIVE_AES_IV": [self getDriveAesIv],
            @"DRIVE_AES_KEY": [self getDriveAesKey],
            @"WALLET_CONNECT_PROJECT_ID": [self getWalletConnectProjectId],
            @"INSTABUG_TOKEN_DEV": [self getInstabugTokenDev],
            @"INSTABUG_TOKEN_PROD": [self getInstabugTokenProd],
            @"CROWDIN_PROJECT_ID": [self getCrowdinProjectId],
            @"CROWDIN_API_TOKEN": [self getCrowdinApiToken],
            @"CROWDIN_DISTRIBUTION": [self getCrowdinDistribution],
            @"MIXPANEL_TOKEN_DEV": [self getMixpanelTokenDev],
            @"MIXPANEL_TOKEN_PROD": [self getMixpanelTokenProd],
            @"DROPBOX_APP_KEY_DEV": [self getDropboxAppKeyDev],
            @"DROPBOX_APP_KEY_PROD": [self getDropboxAppKeyProd],
            @"X_SIGNATURE_KEY": [self getXSignatureKey]
        };
        resolve(envVars);
    } @catch (NSException *exception) {
        reject(@"ENV_ERROR", @"Failed to get environment variables", nil);
    }
}

@end 