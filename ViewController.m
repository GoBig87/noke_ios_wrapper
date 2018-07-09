#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#import <UIKit/UIKit.h>
#import "NokeMobileLibrary.framework/Headers/NokeMobileLibrary-Swift.h"
#import "ViewController.h"

@implementation ViewController

@synthesize callback = _callback;
@synthesize util = _util;
@synthesize client = _client;

- (ViewController *) init:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util;
{
    _callback = callback;
    _util = util;
    _client = client_func;

    return self;
}

- (void) startUnlock:(char*)lockMacAddr; {

    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];

    NSString* apiKey = @"debug";
    [[NokeDeviceManager shared] setAPIKey:apiKey];

    NSString* uploadUrl = @"https://coreapi-sandbox.appspot.com/upload/";
    [[NokeDeviceManager shared] changeDefaultUploadUrl:uploadUrl];

    NSString* lockName = @"lock Name";
    NokeDevice *noke = [[NokeDevice alloc]initWithName:lockName mac:NSlockMacAddr];

    [[NokeDeviceManager shared] addNoke:noke];
}

- (void) bluetoothManagerDidUpdateStateWithState:(NokeManagerBluetoothState)state{
    NSString *status;
    const char* statusChar;
    switch (state) {
        case NokeManagerBluetoothStateUnknown:
            status = @"Unknown State";
            statusChar = [status UTF8String];
            self.callback(statusChar,self.util);
            break;
        case NokeManagerBluetoothStateResetting:
            status = @"Resesting";
            statusChar = [status UTF8String];
            self.callback(statusChar,self.util);
            break;
        case NokeManagerBluetoothStateUnsupported:
            status = @"Unsupported";
            statusChar = [status UTF8String];
            self.callback(statusChar,self.util);
            break;
        case NokeManagerBluetoothStateUnauthorized:
            status = @"Unauthorized";
            statusChar = [status UTF8String];
            self.callback(statusChar,self.util);
            break;
        case NokeManagerBluetoothStatePoweredOff:
            status = @"Power Off";
            statusChar = [status UTF8String];
            self.callback(statusChar,self.util);
            break;
        case NokeManagerBluetoothStatePoweredOn:
            status = @"Power On";
            statusChar = [status UTF8String];
            self.callback(statusChar,self.util);
            [[NokeDeviceManager shared] startScanForNokeDevices];
            NSLog(@"NOKE MANAGER ON");
            break;
        default:
            status = @"Defualt";
            statusChar = [status UTF8String];
            self.callback(statusChar,self.util);
            NSLog(@"Defualt");
            break;
    }
}
- (void)nokeDeviceDidUpdateStateTo:(NokeDeviceConnectionState)state noke:(NokeDevice*)noke{
    const char* token;
    bool looping = true;
    NSString *status;
    NSString *commandString;
    const char* statusChar;
    const char* sessionChar  = [noke.session UTF8String];
    const char* macChar      = [noke.mac UTF8String];
    while (looping){
        switch (state) {
            case NokeDeviceConnectionStateNokeDeviceConnectionStateDiscovered:
                NSLog(@"Noke Discovered");
                status = @"Noke Discovered";
                statusChar = [status UTF8String];
                self.callback(statusChar,self.util);
                [[NokeDeviceManager shared] stopScan];
                [[NokeDeviceManager shared] connectToNokeDevice:noke];
                break;
            case NokeDeviceConnectionStateNokeDeviceConnectionStateConnecting:
                NSLog(@"Connecting");
                status = @"Connecting";
                statusChar = [status UTF8String];
                self.callback(statusChar,self.util);
                break;
            case NokeDeviceConnectionStateNokeDeviceConnectionStateConnected:
                status = @"Connected";
                statusChar = [status UTF8String];
                self.callback(statusChar,self.util);
                token = self.client(sessionChar,macChar,self.util);
                commandString= [NSString stringWithUTF8String:token];
                [noke sendCommands:commandString];
                break;
            case NokeDeviceConnectionStateNokeDeviceConnectionStateSyncing:
                NSLog(@"Synching");
                status = @"Synching";
                statusChar = [status UTF8String];
                self.callback(statusChar,self.util);
            case NokeDeviceConnectionStateNokeDeviceConnectionStateUnlocked:
                NSLog(@"Unlocked");
                status = @"Unlocked";
                statusChar = [status UTF8String];
                self.callback(statusChar,self.util);
                looping = false;
                break;
            case NokeDeviceConnectionStateNokeDeviceConnectionStateDisconnected:
                NSLog(@"Disconnected");
                status = @"Disconnected";
                statusChar = [status UTF8String];
                self.callback(statusChar,self.util);
                looping = false;
                break;
            default:
                NSLog(@"Unknown State");
                status = @"Unknown State";
                statusChar = [status UTF8String];
                v
                break;
        }
    }
}

- (void)nokeErrorDidOccurWithError:(NokeDeviceManagerError)error message:(NSString)message noke:(NokeDevice)noke{
    NSLog(@"Error State");
    NSString *status;
    status = @"Error State";
    statusChar = [status UTF8String];
    self.callback(statusChar,self.util);
}
@end

void StartUnlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util){
    ViewController* nokeviewcontroller = [[ViewController alloc] init:callback client_func:client_func util:util];
    [nokeviewcontroller unlockNoke:lockMacAddr];
}