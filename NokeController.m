#import <LocalAuthentication/LocalAuthentication.h>
#import "NokeController.h"

@interface NokeController ()

@end

@implementation NokeController
{
    NSString* longitude;
    NSString* latitude;
}
@synthesize mStrongObjectArray = _mStrongObjectArray;
@synthesize mCallback = _callback;
@synthesize mUtil = _util;
@synthesize mUtilSendMessage = _utilSendMessage;
@synthesize mClient = _client;


static NokeController *nokeController;

+ (NokeController*) sharedInstance
{
    if(nokeController == nil)
    {
        nokeController = [[NokeController alloc] init];
    }
    return nokeController;
}
-(void) startNokeScan:(char*)name mac:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func viewcontroller:(store_viewcontroller)viewcontroller util:(void*)util utilSendMessage:(void*)utilSendMessage{
    _callback = callback;
    _util = [NSValue valueWithPointer:util];
    _utilSendMessage = [NSValue valueWithPointer:utilSendMessage];
    _client = client_func;

    [[NokeCallback sharedInstance] initWithCallBacks:callback client_func:client_func util:util];

    self.mStrongObjectArray = [[NSMutableArray alloc] init];
    [self.mStrongObjectArray addObject:self.mUtil];
    [self.mStrongObjectArray addObject:self.mUtilSendMessage];
    NSLog(@"DEBUG-NC-1");
//    //Make strong refrence
//    [self.pythonCallbacks addObject:self.mCallback];
//    [self.pythonCallbacks addObject:self.mClient];

    [nokeSDK sharedInstance].delegate = self;
    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];
    NSLog(@"%@",NSlockMacAddr);
    NSString* NSname = [NSString stringWithUTF8String:name];
    NSLog(@"%@",NSname);
    nokeDevice *noke = [[nokeDevice alloc] initWithName:NSname Mac:NSlockMacAddr];
    [[nokeSDK sharedInstance] insertNokeDevice:noke];
    NSLog(@"DEBUG-NC-2");
    NSString *callbackStr = @"Bluetooth Enabled";
    const char *callbackChar = [callbackStr UTF8String];
    void* myUtilPointer = [self.mUtilSendMessage pointerValue];
    self.mClient(callbackChar,callbackChar,myUtilPointer);

}

-(void) submitTokenToBackend:(NSString*)session mac:(NSString*)mac compblock:(myCompletion)compblock{

    NSString *rsp = [[NokeCallback sharedInstance] sendTokenToServer:session mac:mac];
    NSLog(@"Got server rsp");
    NSLog(@"%@",rsp);
    compblock(rsp);
}

#pragma mark - nokeSDK
 -(void) isBluetoothEnabled:(bool)enabled
{
    NSLog(@"Bluetooth loop hit.");

    if(enabled){
        NSString *callbackStr = @"Bluetooth Enabled";
        const char *callbackChar = [callbackStr UTF8String];
        void* myUtilPointer = [self.mUtil pointerValue];
        self.mCallback(callbackChar,myUtilPointer);
        [[nokeSDK sharedInstance] startScanForNokeDevices];
        NSLog(@"Bluetooth enabled");
    }else{
        NSLog(@"Bluetooth disabled");
    }
    //Called when bluetooth is enabled or disabled
}

-(void) didDiscoverNokeDevice:(nokeDevice*)noke RSSI:(NSNumber*)RSSI
{
    NSLog(@"Lock Discovered");
    NSString *callbackStr = @"Lock Discovered";
    const char *callbackChar = [callbackStr UTF8String];
    void* myUtilPointer = [self.mUtil pointerValue];
    self.mCallback(callbackChar,myUtilPointer);
    [[nokeSDK sharedInstance] connectToNokeDevice:noke];
    //Is called when a noke device is discovered.
}

-(void) didConnect:(nokeDevice*) noke
{
    NSString *callbackStr = @"Lock Connected";
    const char *callbackChar = [callbackStr UTF8String];
    void* myUtilPointer = [self.mUtil pointerValue];
    self.mCallback(callbackChar,myUtilPointer);
    NSLog(@"Lock Connected");
    NSString *mac = noke.mac;
    NSString *session = [noke getSessionAsString];

    [self submitTokenToBackend:session mac:mac compblock:^(NSString* commands) {
        if(commands != nil){
            NSLog(@"Noke Token Req:No response from server.");
        }
        if(![commands isEqualToString:@"Access Denied"]){
            [noke addDataToArray:[commands dataUsingEncoding:NSUTF8StringEncoding]];
            [noke writeDataArray];
        }else{
            NSLog(@"Error getting noke commands.  Access Denied");
        }
    }];
    //[noke sendCommand:commands];
    //Called when a noke device has successfully connected to the app
}

-(void) didDisconnect:(nokeDevice*) noke
{
    NSLog(@"Lock Disconnected");
    //Called after a noke device has been disconnected
}

-(void) didReceiveData:(NSData*) data Noke:(nokeDevice*)noke
{
    NSLog(@"Data received");
    //Called when the lock sends back data that needs to be passed to the server
}
@end

@interface NokeCallback ()

@end

@implementation NokeCallback

static NokeCallback *nokeCallback;

@synthesize nCallback = _callback;
@synthesize nUtil = _util;
@synthesize nClient = _client;


+ (NokeCallback*) sharedInstance
{
    if(nokeCallback == nil)
    {
        nokeCallback = [[NokeCallback alloc] init];
    }
    return nokeCallback;
}
- (NokeCallback *) initWithCallBacks:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util
{
    _callback = callback;
    _util = util;
    _client = client_func;

    return self;
}
+ (NSString*) sendTokenToServer:(NSString*)session mac:(NSString*)mac{
    const char *charDeeMacDennis = [mac UTF8String];
    const char *sessionChar = [session UTF8String];
    const char *rspChar = self.nClient(sessionChar,charDeeMacDennis,self.nUtil);
    NSString* rsp = [NSString stringWithUTF8String:rspChar];
    return rsp;
}

@end
void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func,store_viewcontroller viewcontroller, void *util, void *utilSendMessage){
    [[NokeController sharedInstance] startNokeScan:name mac:lockMacAddr callback:callback client_func:client_func viewcontroller:viewcontroller util:util utilSendMessage:utilSendMessage];
}
