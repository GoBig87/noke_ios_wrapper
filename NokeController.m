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
-(void) startNokeScan:(char*)name mac:(char*)lockMacAddr lockState:(bool)lockState callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{

    _callback = callback;
    _util = util;
    _client = client_func;

    NSLog(@"DEBUG-NC-1");

    [nokeSDK sharedInstance].delegate = self;
    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];
    NSLog(@"%@",NSlockMacAddr);
    NSString* NSname = [NSString stringWithUTF8String:name];
    NSLog(@"%@",NSname);
    [[nokeSDK sharedInstance] resetCMDelegate];
    nokeDevice *noke = [[nokeDevice alloc] initWithName:NSname Mac:NSlockMacAddr];
    [[nokeSDK sharedInstance] insertNokeDevice:noke];
    NSLog(@"DEBUG-NC-2");
    if(lockState){
        [[nokeSDK sharedInstance] startScanForNokeDevices];
    }
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
    [[nokeSDK sharedInstance] connectToNokeDevice:noke];
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

    const char* commands = self.mClient(sessionChar,charDeeMacDennis,self.mUtil);
    NSString* hexString = [NSString stringWithUTF8String:commands];
    char * myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2)
    {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSData* cmdData = [NSData dataWithBytes:myBuffer length:20];
    NSLog(@"Fineshed converting to NS data");
    if([noke dataPackets] != nil)
    {
        [[noke dataPackets] removeAllObjects];
    }
    [noke addDataToArray:cmdData];
    NSLog(@"Adding data to array");
    [noke writeDataArray];
    NSLog(@" Sending data to lock");
}

-(void) didDisconnect:(nokeDevice*) noke
{
    NSString *callbackStr = @"Disconnected";
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil);
    NSLog(@"Lock Disconnected");
    [[nokeSDK sharedInstance] removeAllLocks];
    [[nokeSDK sharedInstance] stopScan];
    //Called after a noke device has been disconnected
}

-(void) didReceiveData:(NSData*) data Noke:(nokeDevice*)noke
{
    NSLog(@"Data received");
    NSString *callbackStr = @"Unlocked";
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil);
    [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
    //Called when the lock sends back data that needs to be passed to the server
}
@end

void StartUnlock(char* name, char* lockMacAddr,bool lockState, callbackfunc callback, clientfunc client_func, void *util){
    [[NokeController sharedInstance] startNokeScan:name mac:lockMacAddr lockState:lockState callback:callback client_func:client_func util:util];
}
