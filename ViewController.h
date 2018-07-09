#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@interface NokeViewController : NSObject{
    clientfunc client_func;
    callbackfunc callback;
}

@property (nonatomic, assign) clientfunc client_func;
@property (nonatomic, assign) callbackfunc callback;
@property (void*) util;

- (NokeViewController *) init:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;

- (void) startUnlock:(char*)lockMacAddr;
@end

void StartUnlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util);