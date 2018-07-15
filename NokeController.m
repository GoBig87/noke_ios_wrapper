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
    NSLog(@"Debug-Noke-0");
    [nokeSDK sharedInstance].delegate = self;
    NSLog(@"Debug-Noke-1");
    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];
    NSString* NSname = [NSString stringWithUTF8String:name];
    NSLog(@"Debug-Noke-2");
    nokeDevice *noke = [[nokeDevice alloc] initWithName:NSname Mac:NSlockMacAddr];
    //Hard coding this in nokeClient
    //[nokeClient setToken:'my token here'];
    [[nokeSDK sharedInstance] insertNokeDevice:noke];
    //Start scanning
    NSLog(@"Debug-Noke-3");
    //Scanning must start after bluetooth is enabled!!
    //[[nokeSDK sharedInstance] startScanForNokeDevices];
}

#pragma mark - nokeSDK
 -(void) isBluetoothEnabled:(bool)enabled
{
    NSLog(@"Bluetooth loop hit.");
    if(enabled){
        [[nokeSDK sharedInstance] startScanForNokeDevices];
        NSLog(@"Bluetooth enabled");
    }else{
        NSLog(@"Bluetooth disabled");
    }
    //Called when bluetooth is enabled or disabled
}

-(void) didDiscoverNokeDevice:(nokeDevice*)noke
{
    NSLog(@"Lock Discovered");
    //Is called when a noke device is discovered.
}

-(void) didConnect:(nokeDevice*) noke
{
    NSLog(@"Lock Discovered");
    //Called when a noke device has successfully connected to the app
}

-(void) didDisconnect:(nokeDevice*) noke
{
    NSLog(@"Lock Disconnected");
    //Called after a noke device has been disconnected
}

-(void) didReceiveData:(NSData*)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    const char *chars = [string UTF8String];
    NSLog(string);
    NSLog(@"Data ready");
    //Called when the lock sends back data that needs to be passed to the server
}
@end

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func,store_viewcontroller viewcontroller, void *util){
    [[NokeController sharedInstance] startNokeScan:name mac:lockMacAddr callback:callback client_func:client_func viewcontroller:viewcontroller util:util];
}
