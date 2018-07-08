#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "NokeMobileLibrary.framework/Headers/NokeMobileLibrary-Swift.h"
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
#include "Noke_Wrapper_imp.h"

@implementation NokeTokenReq

- (void) unlockNoke:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util; {

    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];

    NSString* apiKey = @"debug";
    [[NokeDeviceManager shared] setAPIKey:apiKey];

    NSString* uploadUrl = @"https://coreapi-sandbox.appspot.com/upload/";
    [[NokeDeviceManager shared] changeDefaultUploadUrl:uploadUrl];

    NSString* lockName = @"lock Name";
    NokeDevice *noke = [[NokeDevice alloc]init:lockName mac:NSlockMacAddr];

    [[NokeDeviceManager shared] addNoke:noke];
    NokeManagerBluetoothState state;
    [self bluetoothManagerDidUpdateState:state callback:callback client_func:client_func util:util];
}

- (void) bluetoothManagerDidUpdateState:(NokeManagerBluetoothState)state callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{
    switch (state) {
    case NokeManagerBluetoothStateUnknown:
        NSString* unknown = @"Unknown State";
        const char* unknownChar = [unknown UTF8String];
        callback(unknownChar,util);
        break;
    case NokeManagerBluetoothStateResetting:
        NSString* reset = @"Resesting";
        const char* resetChar = [reset UTF8String];
        callback(resetChar,util);
        break;
    case NokeManagerBluetoothStateUnsupported:
        NSString* unsupported = @"Unsupported";
        const char* unsupportedChar = [unsupported UTF8String];
        callback(unsupportedChar,util);
        break;
    case NokeManagerBluetoothStateUnauthorized:
        NSString* unauthorized = @"Unauthorized";
        const char* unauthorizedChar = [unauthorized UTF8String];
        callback(unauthorizedChar,util);
        break;
    case NokeManagerBluetoothStatePoweredOff:
        NSString* poweredOff = @"Power Off";
        const char* poweredOffChar = [poweredOff UTF8String];
        callback(poweredOffChar,util);
        break;
    case NokeManagerBluetoothStatePoweredOn:
        NSString* poweredOn = @"Power On";
        const char* poweredOnChar = [poweredOn UTF8String];
        callback(poweredOnChar,util);
        [[NokeDeviceManager sharedInstance] startScanForNokeDevices];
        NSLog(@"NOKE MANAGER ON");
        NokeDeviceConnectionState state;
        [self nokeDeviceDidUpdateState:state noke:noke];
        break;
    default:
        NSString* defaultStr = @"Defualt";
        const char* defaultChar = [defaultStr UTF8String];
        callback(defaultChar,util);
        NSLog(@"Defualt");
        break;
    }
}
- (void) nokeDeviceDidUpdateState:(int)state noke:(NokeDevice*)noke callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{
    char* token;
    bool looping = true;
    NSString *status;
    const char* statusChar;
    while looping{
        switch (state) {
        case NokeDeviceConnectionStateNokeDeviceConnectionStateDiscovered:
            NSLog(@"Noke Discovered");
            status = @"Noke Discovered";
            statusChar = [status UTF8String];
            callback(statusChar,util);
            [[NokeDeviceManager sharedInstance] stopScan];
            [[NokeDeviceManager sharedInstance] connectToNokeDevice:noke];
            break;
        case NokeDeviceConnectionStateNokeDeviceConnectionStateConnecting:
            NSLog(@"Connecting");
            status = @"Connecting";
            statusChar = [status UTF8String];
            callback(statusChar,util);
            break;
        case NokeDeviceConnectionStateNokeDeviceConnectionStateConnected:
            status = @"Connected";
            statusChar = [status UTF8String];
            callback(statusChar,util);
            const char* nokeChar  = [noke.session UTF8String];
            token = client_func(nokeChar,session_data);
            NSString *commandString = [NSString stringWithUTF8String:token];
            [noke sendCommands:commandString];
            break;
        case NokeDeviceConnectionStateNokeDeviceConnectionStateSyncing:
            NSLog(@"Synching");
            status = @"Synching";
            statusChar = [status UTF8String];
            callback(statusChar,util);
        case NokeDeviceConnectionStateNokeDeviceConnectionStateUnlocked:
            NSLog(@"Unlocked");
            status = @"Unlocked";
            statusChar = [status UTF8String];
            callback(statusChar,util);
            looping = false;
            break;
        case NokeDeviceConnectionStateNokeDeviceConnectionStateDisconnected:
            NSLog(@"Disconnected");
            status = @"Disconnected";
            statusChar = [status UTF8String];
            callback(statusChar,util);
            looping = false;
            break;
        default:
            NSLog(@"Unknown State");
            status = @"Unknown State";
            statusChar = [status UTF8String];
            callback(statusChar,util);
            break;
        }
    }

}

@end
void request_Unlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util){
    NokeTokenReq* nokeTokenRequest = [[NokeTokenReq alloc] init];
    [NokeTokenReq unlockNoke:lockMacAddr callback:callback client_func:client_func util:util];
}