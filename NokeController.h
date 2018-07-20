#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "nokeSDK.h"
#import "NokeCallback.h"

typedef void (*store_viewcontroller) (void *viewcontroller,void *util);
typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (*clientfunc) (const char *session, const char *macAddr, void *util);
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

@property (retain) NSMutableArray *strongRefArray;


+(NokeController*) sharedInstance;
- (void) isBluetoothEnabled:(bool) enabled;
- (void) didDiscoverNokeDevice:(nokeDevice*) noke RSSI:(NSNumber *)RSSI;
- (void) didConnect:(nokeDevice*) noke;
- (void) didDisconnect:(nokeDevice*) noke;
- (void) didReceiveData:(NSData*) data Noke:(nokeDevice*)noke;

@end



void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func, store_viewcontroller viewcontroller, void *util, void *utilSendMessage);
