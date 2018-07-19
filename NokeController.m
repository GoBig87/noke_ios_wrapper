#import <LocalAuthentication/LocalAuthentication.h>
#import "NokeController.h"

@interface NokeController ()

@end

@implementation NokeController
{
    NSString* longitude;
    NSString* latitude;
}

@synthesize strongRefArray = _strongRefArray;

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

    [[NokeCallback sharedInstance] setCallBacks:callback client_func:client_func util:util];
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
    NSString *callbackStr = @"Bluetooth Enabled";
    const char *callbackChar = [callbackStr UTF8String];

}

-(void) submitTokenToBackend:(NSString*)session mac:(NSString*)mac compblock:(myCompletion)compblock{

    NSString *rsp = [[NokeCallback sharedInstance] sendTokenToMyServer:session mac:mac];
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
        [[NokeCallback sharedInstance] sendCallBack:callbackStr];
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
    [[NokeCallback sharedInstance] sendCallBack:callbackStr];
    [[nokeSDK sharedInstance] connectToNokeDevice:noke];
    //Is called when a noke device is discovered.
}

-(void) didConnect:(nokeDevice*) noke
{
    NSString *callbackStr = @"Lock Connected";
    [[NokeCallback sharedInstance] sendCallBack:callbackStr];
    NSLog(@"Lock Connected");
    NSString *mac = noke.mac;
    NSString *session = [noke getSessionAsString];
    NSLog(@"%@",mac);
    NSLog(@"%@",session);
    [[NokeCallback sharedInstance] sendTokenToMyServer:session mac:mac];

//    [self submitTokenToBackend:session mac:mac compblock:^(NSString* commands) {
//        if(commands != nil){
//            NSLog(@"Noke Token Req:No response from server.");
//        }
//        if(![commands isEqualToString:@"Access Denied"]){
//            [noke addDataToArray:[commands dataUsingEncoding:NSUTF8StringEncoding]];
//            [noke writeDataArray];
//        }else{
//            NSLog(@"Error getting noke commands.  Access Denied");
//        }
//    }];
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

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func,store_viewcontroller viewcontroller, void *util, void *utilSendMessage){
    [[NokeController sharedInstance] startNokeScan:name mac:lockMacAddr callback:callback client_func:client_func viewcontroller:viewcontroller util:util utilSendMessage:utilSendMessage];
}
