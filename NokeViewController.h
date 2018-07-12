#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "nokeDevice.h"
#import "nokeSDK.h"
#import "nokeClient.h"
#import "Reachability.h"

typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (*clientfunc) (const char *session, const char *macAddr, void *reqTokenFunc);

@interface NokeViewController : UIViewController< nokeSDKDelegate, nokeClientDelegate, CLLocationManagerDelegate>
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
@property (nonatomic, assign) callbackfunc mCallback;
@property (nonatomic, assign) void* mUtil;


@property (nonatomic) Reachability *hostReachability;
+(NokeViewController*) sharedInstance;
-(void) setPythonFunc:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;
-(NSString*) requestCommandStr:(NSString*)session Mac:(NSString*)mac;
-(void) logCallback:(NSString)msg;
-(void)setIsLoggedIn:(BOOL)loggedin;
-(void)setUserData:(NSString*)name Email:(NSString*)email Flag:(int)flag CompanyName:(NSString*)company;
-(NSString*)getUsername;
-(NSString*)getEmail;
-(NSString*)getPassword;
-(NSString*)getCompany;
-(void)setPassword:(NSString*)password;
-(int)getInstallerFlag;
-(void)checkLogin;

@end

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util);