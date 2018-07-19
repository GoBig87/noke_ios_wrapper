#import "NokeCallback.h"

@interface NokeCallback ()

@end

@implementation NokeCallback

@synthesize nCallback = _callback;
@synthesize nUtil = _util;
@synthesize nClient = _client;

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
    _callback = callback;
    _util = util;
    _client = client_func;

}
+ (NSString*) sendTokenToMyServer:(NSString*)session mac:(NSString*)mac{
    const char *charDeeMacDennis = [mac UTF8String];
    const char *sessionChar = [session UTF8String];
    const char *rspChar = self.nClient(sessionChar,charDeeMacDennis,self.nUtil);
    NSString* rsp = [NSString stringWithUTF8String:rspChar];
    return rsp;
}

@end