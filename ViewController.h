#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@interface NokeViewController : NSObject

@property NSString* mac;
@property callbackfunc callback;
@property clientfunc client_func;
@property (void*) util;

- (NokeViewController *) init:(char*)mac callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;

- (void) startUnlock:(char*)lockMacAddr;
@end

void StartUnlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util);