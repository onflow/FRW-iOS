#import "NativeRequestEventEmitter.h"

@interface NativeRequestEventEmitter ()
@property (nonatomic, assign) BOOL hasListeners;
@end

@implementation NativeRequestEventEmitter

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents {
  return @[ @"nativeRequest" ];
}

- (void)startObserving {
  self.hasListeners = YES;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleNativeRequest:)
                                               name:@"nativeRequest"
                                             object:nil];
}

- (void)stopObserving {
  self.hasListeners = NO;
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"nativeRequest"
                                                object:nil];
}

- (void)invalidate {
  [super invalidate];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleNativeRequest:(NSNotification *)notification {
  if (!self.hasListeners) {
    return;
  }

  NSDictionary *userInfo = [notification.userInfo isKindOfClass:[NSDictionary class]]
    ? notification.userInfo
    : @{};

  if (userInfo.count == 0) {
    return;
  }

  [self sendEventWithName:@"nativeRequest" body:userInfo];
}

@end
