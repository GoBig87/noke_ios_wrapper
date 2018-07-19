#import "NokeCallback.h"

@interface NokeCallback ()

@end

@implementation NokeCallback
{
    clientfunc mClient;
    callbackfunc mCallback;
    void* mUtil;
}
//@synthesize mCallback = _callback;
//@synthesize mUtil = _util;
//@synthesize mClient = _client;

static NokeCallback *nokeCallback;
+ (NokeCallback*) sharedInstance
{
    if(nokeCallback == nil)
    {
        nokeCallback = [[NokeCallback alloc] init];
    }
    return nokeCallback;
}
- (void) setCallBacks:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util
{
    mCallback = callback;
    mUtil = util;
    mClient = client_func;

}
- (NSString*) sendTokenToMyServer:(NSString*)session mac:(NSString*)mac{
    const char *charDeeMacDennis = [mac UTF8String];
    const char *sessionChar = [session UTF8String];
    const char *rspChar = self.mClient(sessionChar,charDeeMacDennis,self.mUtil);
    NSString* rsp = [NSString stringWithUTF8String:rspChar];
    return rsp;
}

@end