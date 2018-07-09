#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "NokeMobileLibrary.framework/Headers/NokeMobileLibrary-Swift.h"

typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (*clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@interface ViewController : UIViewController <NokeDeviceManagerDelegate>

@property (nonatomic, assign) clientfunc client;
@property (nonatomic, assign) callbackfunc callback;
@property (nonatomic, assign) void* util;

- (ViewController *) init:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;

- (void) startUnlock:(char*)lockMacAddr;
@end

void StartUnlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util);