#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "nokeSDK.h"

typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (*clientfunc) (const char *session, const char *macAddr, void *util);
typedef int (*blockunlockfunc) (void *util);
typedef void(^myCompletion)(NSString*);


@interface NokeController : NSObject <nokeSDKDelegate>
{
    BOOL isLoggedIn;
    NSString* username;
    NSString* useremail;
    NSString* userpassword;
    int installerFlag;
    NSString* companyname;
    NSMutableArray *connectedLocks;

}

@property (nonatomic, assign) clientfunc mClient;
@property (nonatomic, assign) blockunlockfunc mBlockunlock;
@property (nonatomic, assign) callbackfunc mCallback;
@property (nonatomic, assign) void* mUtil;
@property (nonatomic, assign) bool mLockState;

+(NokeController*) sharedInstance;
- (void) isBluetoothEnabled:(bool) enabled;
- (void) didDiscoverNokeDevice:(nokeDevice*) noke RSSI:(NSNumber *)RSSI;
- (void) didConnect:(nokeDevice*) noke;
- (void) didDisconnect:(nokeDevice*) noke;
- (void) didReceiveData:(NSData*) data Noke:(nokeDevice*)noke;
@end

void StartUnlock(char* name, char* lockMacAddr,bool lockState, callbackfunc callback, clientfunc client_func, void *util);
void DisconnectLock(char* name, char* lockMacAddr);