#import <Foundation/Foundation.h>
#import "NokeMobileLibrary/NokeMobileLibrary-Swift.h"
#import <Foundation/NSError.h>
#import <Foundation/NSString.h>

#include "Noke_Wrapper_imp.h"

@implementation retToken

- (void) retrieveTokenObjC:(char*)lockMacAddr user_func:(tokenfunc)user_func user_data:(void*)user_data {

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
    [bluetoothManagerDidUpdateState state:NokeManagerBluetoothState];
    //
}

- (void) bluetoothManagerDidUpdateState:(int)state {
    if let state = state {
        switch (state) {
        case .unknown:
            break
        case .resetting:
            break
        case .unsupported:
            break
        case .unauthorized:
            break
        case .poweredOff:
            NSLog(@"Power Off");
            break
        case .poweredOn:
            [NokeDeviceManager sharedInstance].startScanForNokeDevices();
            NSLog(@"NOKE MANAGER ON");
            //statusLabel.text = "Scanning for Noke Devices"
            break
        default:
            NSLog(@"Defualt");
            break
    }
}
- (void) nokeDeviceDidUpdateState:(int)state noke:(NokeDevice)noke session_callback:(tokenfunc)session_callback session_data:(void*)session_data {
        switch (state) {
        case .nokeDeviceConnectionStateDiscovered:
            NSLog(@'Noke Discovered')
            //statusLabel.text = String.init(format:"%@ discovered", noke.name)
            [NokeDeviceManager sharedInstance].stopScan()
            [NokeDeviceManager sharedInstance].connectToNokeDevice(noke)
            break
        case .nokeDeviceConnectionStateConnected:
            //statusLabel.text = String.init(format:"%@ connected", noke.name)
            //print(noke.session!)
            //self.lockNameLabel.text = noke.name
            NSLog(@'Connected, returning session')
            const char* nokeChar  = [noke.session UTF8String];
            session_callback(nokeChar,session_data)
            break
        case .nokeDeviceConnectionStateSyncing:
            statusLabel.text = String.init(format: "%@ syncing", noke.name)
        case .nokeDeviceConnectionStateUnlocked:
            statusLabel.text = String.init(format:"%@ unlocked. Battery %d", noke.name, noke.battery)
            makeButtonColor(UIColor(red:0.05, green:0.62, blue:0.10, alpha:1.0))
            break
        case .nokeDeviceConnectionStateDisconnected:
            statusLabel.text = String.init(format:"%@ disconnected. Lock state: %d", noke.name, (noke.lockState?.rawValue)!)
            NokeDeviceManager.shared().cacheUploadQueue()
            makeButtonColor(UIColor.darkGray)
            lockNameLabel.text = "No Lock Connected"
            NokeDeviceManager.shared().startScanForNokeDevices()
            currentNoke = nil
            break
        default:
            statusLabel.text = String.init(format:"%@ unrecognized state", noke.name)
            break
        }
    }
}
    NSLog(@"DEBUG_STRIPE1");
    NSString *myPublishableKey = [NSString stringWithUTF8String:myKey];
    STPAPIClient *apiClient = [[STPAPIClient alloc] initWithPublishableKey:myPublishableKey];
    NSLog(@"DEBUG_STRIPE2");
    [apiClient createTokenWithCard:cardParams completion:^(STPToken *token,NSError *error) {
        NSLog(@"DEBUG_STRIPE3");
        if (token == nil || error != nil) {
            NSLog(@"ERROR1");
            const char* errorChar = [error.localizedDescription UTF8String];
            user_func(errorChar,user_data);
            NSLog(@"ERROR2");
            NSLog(@"%@",error.localizedDescription);
        } else {
            NSLog(@"%@",token.tokenId);
            const char* tokenChar = [token.tokenId UTF8String];
            NSLog(@"Success2");
            user_func(tokenChar,user_data);
            NSLog(@"Success3");
            NSLog(@"%@",token.tokenId);
        }
    }];
}

@end

void retrieveToken(char* myKey, char* cardNumber, int expMonth, int expYear, char* cvc,tokenfunc user_func, void *user_data){

    retToken* retrieveToken = [[retToken alloc] init];
    [retrieveToken retrieveTokenObjC:myKey andcardNumber:cardNumber andexpMonth:expMonth andexpYear:expYear andcvc:cvc anduser_func:user_func anduser_data:user_data];
}