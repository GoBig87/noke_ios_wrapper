#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>
#import "NokeMobileLibrary.framework/Headers/NokeMobileLibrary-Swift.h"

typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (*clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@interface ViewController : UIViewController <NokeDeviceManagerDelegate>

@property (nonatomic, assign) clientfunc mClient;
@property (nonatomic, assign) callbackfunc mCallback;
@property (nonatomic, assign) void* mUtil;

- (ViewController *) init:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;

- (void) startUnlock:(char*)name mac:(char*)lockMacAddr;
@end

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util);