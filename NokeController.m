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

static NokeController *nokeController;

+ (NokeController*) sharedInstance
{
    if(nokeController == nil)
    {
        nokeController = [[NokeController alloc] init];
    }
    return nokeController;
}
-(void) startNokeScan:(char*)name mac:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{

    _callback = callback;
    _util = util;
    _client = client_func;

    NSLog(@"DEBUG-NC-1");

    [nokeSDK sharedInstance].delegate = self;
    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];
    NSLog(@"%@",NSlockMacAddr);
    NSString* NSname = [NSString stringWithUTF8String:name];
    NSLog(@"%@",NSname);
    nokeDevice *noke = [[nokeDevice alloc] initWithName:NSname Mac:NSlockMacAddr];
    [[nokeSDK sharedInstance] insertNokeDevice:noke];
    NSLog(@"DEBUG-NC-2");
}

#pragma mark - nokeSDK
 -(void) isBluetoothEnabled:(bool)enabled
{
    NSLog(@"Bluetooth loop hit.");

    if(enabled){
        NSString *callbackStr = @"Bluetooth Enabled";
        const char *callbackChar = [callbackStr UTF8String];
        self.mCallback(callbackChar,self.mUtil);
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
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil);
    NSString *callbackStr = @"Lock Discovered";
    //Is called when a noke device is discovered.
}

-(void) didConnect:(nokeDevice*) noke
{
    NSLog(@"Connected");
    NSString *callbackStr = @"Connected";
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil);
    NSString *mac = noke.mac;
    NSString *session = [noke getSessionAsString];
    const char *charDeeMacDennis = [mac UTF8String];
    const char *sessionChar = [session UTF8String];
    const char *rspChar = self.mClient(sessionChar,charDeeMacDennis,self.mUtil);
    NSString* rsp = [NSString stringWithUTF8String:rspChar];

    self.mClient(sessionChar,charDeeMacDennis,self.mUtil);
    NSLog(@"Lock Connected");
}

-(void) didDisconnect:(nokeDevice*) noke
{
    NSString *callbackStr = @"Disconnected";
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil);
    NSLog(@"Lock Disconnected");
    //Called after a noke device has been disconnected
}

-(void) didReceiveData:(NSData*) data Noke:(nokeDevice*)noke
{
    NSLog(@"Data received");
    NSLog(@"Data received");
    NSString *callbackStr = @"Received Data";
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil);
    //Called when the lock sends back data that needs to be passed to the server
}
@end

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util){
    [[NokeController sharedInstance] startNokeScan:name mac:lockMacAddr callback:callback client_func:client_func util:util];
}
