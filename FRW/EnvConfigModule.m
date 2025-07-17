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
            @"FLOW_DISCOVERY_WALLET_URL": [self getFlowDiscoveryWalletUrl]
        };
        resolve(envVars);
    } @catch (NSException *exception) {
        reject(@"ENV_ERROR", @"Failed to get environment variables", nil);
    }
}

@end 