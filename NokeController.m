#import <LocalAuthentication/LocalAuthentication.h>
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
-(void) startNokeScan:(char*)name mac:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func viewcontroller:(store_viewcontroller)viewcontroller util:(void*)util{
    _callback = callback;
    _util = util;
    _client = client_func;

    [nokeSDK sharedInstance].delegate = self;
    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];
    NSLog(@"%@",NSlockMacAddr);
    NSString* NSname = [NSString stringWithUTF8String:name];
    NSLog(@"%@",NSname);
    nokeDevice *noke = [[nokeDevice alloc] initWithName:NSname Mac:NSlockMacAddr];
    [[nokeSDK sharedInstance] insertNokeDevice:noke];

}

#pragma mark - nokeSDK
 -(void) isBluetoothEnabled:(bool)enabled
{
    NSLog(@"Bluetooth loop hit.");

    if(enabled){
        NSString callbackStr = @"Bluetooth Enabled";
        const char *callbackChar = [callbackStr UTF8String];
        self.mCallback(callbackChar,self.mUtil)
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
    NSString callbackStr = @"Lock Discovered";
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil)
    [[nokeSDK sharedInstance] connectToNokeDevice:noke];
    //Is called when a noke device is discovered.
}

-(void) didConnect:(nokeDevice*) noke
{
    NSString callbackStr = @"Lock Connected";
    const char *callbackChar = [callbackStr UTF8String];
    self.mCallback(callbackChar,self.mUtil)
    NSLog(@"Lock Connected");
    const char *charDeeMacDennis = [noke.mac UTF8String];
    const char *session = [[noke getSessionAsString] UTF8String];
    const char *commands = self.mClient(session,charDeeMacDennis,self.mUtil);
    NSLog(@"%@",commands);
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

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func,store_viewcontroller viewcontroller, void *util){
    [[NokeController sharedInstance] startNokeScan:name mac:lockMacAddr callback:callback client_func:client_func viewcontroller:viewcontroller util:util];
}
