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
    NokeDevice *noke = [NokeDevice alloc]init:lockName mac:NSlockMacAddr];

    [[NokeDeviceManager shared] addNoke:noke];
    NokeManagerBluetoothState state;
    [self bluetoothManagerDidUpdateState:state callback_func:callbackfunc client_func:client_func util:util];
}

- (void) bluetoothManagerDidUpdateState:(NokeManagerBluetoothState)state noke:(NokeDevice*)noke lockMacAddr:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{
    switch (state) {
    case NokeManagerBluetoothStateUnknown:
        NSString* unknown = @"Unknown State";
        const char* unknownChar = [unknown UTF8String];
        callbackfunc(unknownChar,util);
        break;
    case NokeManagerBluetoothStateResetting:
        NSString* reset = @"Resesting";
        const char* resetChar = [reset UTF8String];
        callbackfunc(resetChar,util);
        break;
    case NokeManagerBluetoothStateUnsupported:
        NSString* unsupported = @"Unsupported";
        const char* unsupportedChar = [unsupported UTF8String];
        callbackfunc(unsupportedChar,util);
        break;
    case NokeManagerBluetoothStateUnauthorized:
        NSString* unauthorized = @"Unauthorized";
        const char* unauthorizedChar = [unauthorized UTF8String];
        callbackfunc(unauthorizedChar,util);
        break;
    case NokeManagerBluetoothStatePoweredOff:
        NSString* poweredOff = @"Power Off";
        const char* poweredOffChar = [poweredOff UTF8String];
        callbackfunc(poweredOffChar,util);
        break;
    case NokeManagerBluetoothStatePoweredOn:
        NSString* poweredOn = @"Power On";
        const char* poweredOnChar = [poweredOn UTF8String];
        callbackfunc(poweredOnChar,util);
        [NokeDeviceManager sharedInstance].startScanForNokeDevices();
        NSLog(@"NOKE MANAGER ON");
        [nokeDeviceDidUpdateState state:NokeDeviceConnectionState noke:noke ];
        break;
    default:
        NSString* defaultStr = @"Defualt";
        const char* defaultChar = [defaultStr UTF8String];
        callbackfunc(defaultChar,util);
        NSLog(@"Defualt");
        break;
    }
}
- (void) nokeDeviceDidUpdateState:(int)state noke:(NokeDevice*)noke lockMacAddr:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{
    char* token;
    bool looping = true;
    while looping{
        switch (state) {
        case .nokeDeviceConnectionStateDiscovered:
            NSLog(@"Noke Discovered");
            NSString* nokeDiscovered = @"Noke Discovered";
            const char* nokeDiscoveredChar = [nokeDiscovered UTF8String];
            callbackfunc(nokeDiscoveredChar,util);
            [NokeDeviceManager sharedInstance].stopScan();
            [NokeDeviceManager sharedInstance].connectToNokeDevice(noke);
            break;
        case .nokeDeviceConnectionStateConnected:
            NSLog(@"Connected, returning session");
            NSString* nokeConnected = @"Connected";
            const char* nokeConnectedChar = [nokeConnected UTF8String];
            callbackfunc(nokeConnectedChar,util);
            const char* nokeChar  = [noke.session UTF8String];
            token = client_func(nokeChar,session_data);
            NSString *commandString = [NSString stringWithUTF8String:token];
            noke.sendCommands(commandString);
            break;
        case .nokeDeviceConnectionStateSyncing:
            NSLog(@"Synching");
            NSString* nokeSynching = @"Synching";
            const char* nokeSynchingChar = [nokeSynching UTF8String];
        case .nokeDeviceConnectionStateUnlocked:
            NSLog(@"Unlocked");
            NSString* nokeSynching = @"Unlocked";
            const char* nokeSynchingChar = [nokeSynching UTF8String];
            looping = false;
            break;
        case .nokeDeviceConnectionStateDisconnected:
            NSLog(@"Disconnected");
            NSString* nokeDisconnected = @"Disconnected";
            const char* nokeDisconnectedChar = [nokeDisconnected UTF8String];
            looping = false;
            break;
        default:
            NSLog(@"Unknown State");
            NSString* nokeUnknownState = @"Unknown State";
            const char* nokeUnknownStateChar = [nokeUnknownState UTF8String];
            break;
        }
    }

}

@end
void request_Unlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util){
    NokeTokenReq* nokeTokenRequest = [[NokeTokenReq alloc] init];
    [NokeTokenReq unlockNoke:lockMacAddr callback:callback client_func:client_func util:util];
}