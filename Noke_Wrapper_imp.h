#import <Foundation/Foundation.h>
typedef void (*callbackfunc) (const char *name, void *callback);
typedef char (*clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@interface NokeTokenReq : NSObject
- (void) unlockNoke:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;
@end
void request_Unlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util);