#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "nokeSDK.h"

typedef void (*store_viewcontroller) (void *viewcontroller,void *util);
typedef void (*callbackfunc) (const char *name, void *callback);
typedef const char* (*clientfunc) (const char *session, const char *macAddr, void *util);
typedef void(^myCompletion)(NSString*);

@interface NokeCallback : NSObject

@property (nonatomic, assign) clientfunc nClient;
@property (nonatomic, assign) callbackfunc nCallback;
@property (nonatomic, assign) void* nUtil;

+(NokeCallback*) sharedInstance;
+(NSString*) sendTokenToServer:(NSString*)session mac:(NSString*)mac;
@end