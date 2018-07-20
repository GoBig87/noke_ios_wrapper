#import <LocalAuthentication/LocalAuthentication.h>
#include <CFNetwork/CFSocketStream.h>
#import "NokeController.h"


@interface NokeController ()

@end

@implementation NokeController
{
    NSString* longitude;
    NSString* latitude;
}

@synthesize mCallback = _callback;
@synthesize mUtil = _util;
@synthesize mClient = _client;
@synthesize mStatusfunc = _statusfunc;

static NokeController *nokeController;

+ (NokeController*) sharedInstance
{
    if(nokeController == nil)
    {
        nokeController = [[NokeController alloc] init];
    }
    return nokeController;
}
-(void) startNokeScan:(char*)name mac:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func statusfunc:(checkStatusfunc)statusfunc util:(void*)util utilSendMessage:(void*)utilSendMessage{

    _callback = callback;
    _util = util;
    _client = client_func;
    _statusfunc = statusfunc

    self.strongRefArray = [[NSMutableArray alloc] init];
    [self.strongRefArray addObject:[NokeCallback sharedInstance]];
    NSLog(@"DEBUG-NC-1");

    [nokeSDK sharedInstance].delegate = self;
    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];
    NSLog(@"%@",NSlockMacAddr);
    NSString* NSname = [NSString stringWithUTF8String:name];
    NSLog(@"%@",NSname);
    nokeDevice *noke = [[nokeDevice alloc] initWithName:NSname Mac:NSlockMacAddr];
    [[nokeSDK sharedInstance] insertNokeDevice:noke];
    NSLog(@"DEBUG-NC-2");

    bool alive = true;
    bool status = false
    while(alive){
        status = self.mStatusfunc(self.mUtil);
        if(status){
            NSLog(@"Sending noke info to server.");
            NSString *session = [noke getSessionAsString];
            NSString *mac = noke.mac;
            const char *charDeeMacDennis = [mac UTF8String];
            const char *sessionChar = [session UTF8String];
            const char *rspChar = self.mClient(sessionChar,charDeeMacDennis,self.mUtil);
            NSString* rsp = [NSString stringWithUTF8String:rspChar];
            NSData* commands = [rsp dataUsingEncoding:NSUTF8StringEncoding];
            [noke addDataToArray:commands];
            [noke writeDataArray];
            alive = false
         }
        [NSThread sleepForTimeInterval:0.5];
    }
}


#pragma mark - nokeSDK
 -(void) isBluetoothEnabled:(bool)enabled
{
    NSLog(@"Bluetooth loop hit.");

    if(enabled){
        NSString *callbackStr = @"Bluetooth Enabled";
        [[NokeCallback sharedInstance] sendCallBack:callbackStr];
        [[nokeSDK sharedInstance] startScanForNokeDevices];
        NSLog(@"Bluetooth enabled");
    }else{
        NSLog(@"Bluetooth disabled");
    }
}

-(void) didDiscoverNokeDevice:(nokeDevice*)noke RSSI:(NSNumber*)RSSI
{
    NSLog(@"Lock Discovered");
    NSString *callbackStr = @"Lock Discovered";
    [[NokeCallback sharedInstance] sendCallBack:callbackStr];
    [[nokeSDK sharedInstance] connectToNokeDevice:noke];
    //Is called when a noke device is discovered.
}

-(void) didConnect:(nokeDevice*) noke
{
    NSString *callbackStr = @"Connected";
    [[NokeCallback sharedInstance] sendCallBack:callbackStr];
    NSLog(@"Lock Connected");
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

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func,checkStatusfunc statusfunc, void *util){
    [[NokeController sharedInstance] startNokeScan:name mac:lockMacAddr callback:callback client_func:client_func statusfunc:statusfunc util:util];
}
