//
//  nokeSDK.h
//  ios-sdk
//
//  Created by Spencer Apsley on 3/9/16.
//  Copyright © 2016 Noke LLC. All rights reserved.
//

#import "nokeDevice.h"
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>


//Destinations
#define SERVER_Dest  0x50
#define APP_Dest     0x51
#define LOCK_Dest    0x52

#define PERIPHERAL_NAME_LENGTH 19

@protocol nokeSDKDelegate
- (void) isBluetoothEnabled:(bool) enabled;
- (void) didDiscoverNokeDevice:(nokeDevice*) noke RSSI:(NSNumber *)RSSI;
- (void) didConnect:(nokeDevice*) noke;
- (void) didDisconnect:(nokeDevice*) noke;
- (void) didReceiveData:(NSData*) data Noke:(nokeDevice*)noke;


@end


@interface nokeSDK : NSObject <CBCentralManagerDelegate, nokeDeviceDelegate>
@property id<nokeSDKDelegate> delegate;
@property (retain) NSMutableArray *nokeDevices;
@property (retain) NSMutableArray *nokeGroups;
@property (retain) NSMutableArray *globalUploadDataQueue;
@property long lastReceivedTime;
@property BOOL bluetoothState;


@property nokeDevice* currentNokeDevice;

- (void) insertNokeDevice:(nokeDevice*) noke;
- (void)resetCMDelegate;
- (nokeDevice*) nokeWithUUID:(NSString *) uuid;
- (nokeDevice*) nokeWithMac:(NSString *) mac;
- (nokeDevice*) nokeWithPeripheral:(CBPeripheral *) peripheral;


+ (nokeSDK*) sharedInstance;

- (void) startScanForNokeDevices;
- (void) startScanForFirmwareDevices;
- (void) stopScan;
-(CBCentralManager*)getCentralManager;
- (void) retrieveKnownPeripherals;
- (void) retrieveUuidArrPeripherals:(NSMutableArray *)uuidArray;
- (void) connectToNokeDevice:(nokeDevice*) noke;
- (void) disconnectNokeDevice:(nokeDevice*) noke;
- (void) addDataPacketToQueue:(NSString*)response Session:(NSString*)session Mac:(NSString*)mac Longitude:(NSString*)longitude Latitude:(NSString*)latitude;
- (void) saveNokeDevices;
- (NSArray*)getSavedNokeDevices;
-(void)removeAllLocks;
-(void)removeAllFobs;
-(void)cacheUploadQueue;
-(void)retrieveUploadQueue;
-(void)removeLockFromArray:(nokeDevice*)noke;

@end
