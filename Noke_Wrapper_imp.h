#import <Foundation/Foundation.h>
#import "NokeMobileLibrary.framework/Headers/NokeMobileLibrary-Swift.h"

typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@property nokeDevice* currentNokeDevice;

@interface NokeTokenReq : NSObject
- (void) unlockNoke:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;
@end
void request_Unlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util);