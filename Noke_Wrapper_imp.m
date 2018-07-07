#import <Foundation/Foundation.h>
#import <NokeMobileLibrary/NokeMobileLibrary>-Swift.h
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>
//@import <NokeMobileLibrary>.swift
#include "Noke_Wrapper_imp.h"

@implementation NokeTokenReq

- (void)  unlockNoke:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util; {

    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];

    [[NokeDeviceManager sharedInstance] setDelegate:self];
    //Set api key
    NSString* myApiKey = @'';
    [NokeDeviceManager setAPIKey:myApiKey];
    //Set upload url
    NSString* uploadUrl = @'"https://coreapi-sandbox.appspot.com/upload/"';
    [NokeDeviceManager changeDefaultUploadUrl:uploadUrl];
    //Set up lock
    NSString name = @'Lock Name';
    NokeDevice noke = [[NokeDevice alloc] init:name mac:NSlockMacAddr];
    //Add lock
    [NokeDeviceManager addNoke:noke];
    //Check for bluetooth status, if on start scanning
    [bluetoothManagerDidUpdateState state:NokeManagerBluetoothState callback_func:callbackfunc client_func:client_func util:util];
    //
}

- (void) bluetoothManagerDidUpdateState:(int)state noke:(NokeDevice)noke lockMacAddr:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{
    if let state = state {
        switch (state) {
        case .unknown:
            NSString unknown = @'Unknown State'
            const char* unknownChar = [unknown UTF8String];
            callbackfunc(unknownChar,util)
            break
        case .resetting:
            NSString reset = @'Resesting'
            const char* resetChar = [reset UTF8String];
            callbackfunc(resetChar,util)
            break
        case .unsupported:
            NSString unsupported = @'Unsupported'
            const char* unsupportedChar = [unsupported UTF8String];
            callbackfunc(unsupportedChar,util)
            break
        case .unauthorized:
            NSString unauthorized = @'Unauthorized'
            const char* unauthorizedChar = [unauthorized UTF8String];
            callbackfunc(unauthorizedChar,util)
            break
        case .poweredOff:
            NSString poweredOff = @'Power Off'
            const char* poweredOffChar = [poweredOff UTF8String];
            callbackfunc(poweredOffChar,util)
            break
        case .poweredOn:
            NSString poweredOn = @'Power On'
            const char* poweredOnChar = [poweredOn UTF8String];
            callbackfunc(poweredOnChar,util)
            [NokeDeviceManager sharedInstance].startScanForNokeDevices();
            NSLog(@"NOKE MANAGER ON");
            [nokeDeviceDidUpdateState state:NokeDeviceConnectionState noke:noke ]
            //statusLabel.text = "Scanning for Noke Devices"
            break
        default:
            NSString defaultStr = @'Defualt'
            const char* defaultChar = [defaultStr UTF8String];
            callbackfunc(defaultChar,util)
            NSLog(@"Defualt");
            break
    }
}
- (void) nokeDeviceDidUpdateState:(int)state noke:(NokeDevice)noke lockMacAddr:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{
        char* token;
        bool looping = true;
        while looping{
            switch (state) {
            case .nokeDeviceConnectionStateDiscovered:
                NSLog(@'Noke Discovered')
                NSString nokeDiscovered = @'Noke Discovered'
                const char* nokeDiscoveredChar = [nokeDiscovered UTF8String];
                callbackfunc(nokeDiscoveredChar,util)
                [NokeDeviceManager sharedInstance].stopScan()
                [NokeDeviceManager sharedInstance].connectToNokeDevice(noke)
                break
            case .nokeDeviceConnectionStateConnected:
                NSLog(@'Connected, returning session')
                NSString nokeConnected = @'Connected'
                const char* nokeConnectedChar = [nokeConnected UTF8String];
                callbackfunc(nokeConnectedChar,util)
                const char* nokeChar  = [noke.session UTF8String];
                token = client_func(nokeChar,session_data)
                NSString *commandString = [NSString stringWithUTF8String:token];
                noke.sendCommands(commandString)
                break
            case .nokeDeviceConnectionStateSyncing:
                NSLog(@'Synching')
                NSString nokeSynching = @'Synching'
                const char* nokeSynchingChar = [nokeSynching UTF8String];
            case .nokeDeviceConnectionStateUnlocked:
                NSLog(@'Unlocked')
                NSString nokeSynching = @'Unlocked'
                const char* nokeSynchingChar = [nokeSynching UTF8String];
                looping = false
                break
            case .nokeDeviceConnectionStateDisconnected:
                NSLog(@'Disconnected')
                NSString nokeDisconnected = @'Disconnected'
                const char* nokeDisconnectedChar = [nokeDisconnected UTF8String];
                looping = false;
                break
            default:
                NSLog(@'Unknown State')
                NSString nokeUnknownState = @'Unknown State'
                const char* nokeUnknownStateChar = [nokeUnknownState UTF8String];
                break
            }
        }
    }
}

@end
void request_Unlock(char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util){
    NokeTokenReq* nokeTokenRequest = [[NokeTokenReq alloc] init];
    [NokeTokenReq unlockNoke:lockMacAddr callback:callback client_func:client_func util:util];
}