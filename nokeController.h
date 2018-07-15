#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "nokeSDK.h"

typedef void (*store_viewcontroller) (void *viewcontroller,void *util);
typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (*clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@interface NokeViewController : NSObject <nokeSDKDelegate>

@property (nonatomic, assign) clientfunc mClient;
@property (nonatomic, assign) callbackfunc mCallback;
@property (nonatomic, assign) void* mUtil;

+(NokeViewController*) sharedInstance;
-(void) isBluetoothEnabled:(bool)enabled;
-(void) didDiscoverNokeDevice:(nokeDevice*)noke;
-(void) didConnect:(nokeDevice*) noke;
-(void) didDisconnect:(nokeDevice*) noke;
-(void) didReceiveData:(NSData*)data;

@end

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func, store_viewcontroller viewcontroller, void *util);
