//
//  nokeDevice.h
//  ios-sdk
//
//  Created by Spencer Apsley on 3/9/16.
//  Copyright © 2016 Noke LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TI_aes_128.h"

//Destinations
#define SERVER_Dest  0x50
#define APP_Dest     0x51
#define LOCK_Dest    0x52

//LOCKAPPRESPONSE use by the app to confirm command succeeded
//RESULT TYPES
#define SUCCESS_ResultType 0x60
#define INVALIDKEY_ResultType 0x61
#define INVALIDCMD_ResultType 0x62
#define INVALIDPERMISSION_ResultType 0x63
#define LOCKED_ResultType 0x64
#define INVALIDDATA_ResultType 0x65
#define INVALID_ResultType 0xFF

//RESPONSE TYPES
#define SERVER_ResponseType 0x50
#define APP_ResponseType 0x51
#define INVALID_ResponseType 0xff

//Connection Status
typedef enum _NLConnectionStatus {
    NLConnectionStatusDisconnected = 0,
    NLConnectionStatusCheckingPermission = 1,
    NLConnectionStatusConnecting = 2,
    NLConnectionStatusConnected = 3,
    NLConnectionStatusUnlocked = 4,
    NLConnectionStatusSetup = 5,
    NLConnectionStatusSyncing = 6
} NLConnectionStatus;


//Unlock method
typedef enum _NLUnlockMethod
{
    NLUnlockMethodTwoStep = 0,
    NLUnlockMethodOneStep = 1,
    NLUnlockMethodTouch = 2
    
} NLUnlockMethod;


//Noke device type
typedef enum _NLDeviceType
{
    NLDeviceTypePadlock = 0,
    NLDeviceTypeFob = 1,
    NLDeviceTypeULock = 2,
    NLDeviceTypeSFIC = 3,
    
} NLDeviceType;


//Access Status is determined by group status
typedef enum _NLAccessStatus
{
    NLAccessStatusLive = 0,
    NLAccessStatusExpired = 1,
    NLAccessStatusOngoing = 2,
    NLAccessStatusNone = 3
} NLAccessStatus;


@protocol nokeDeviceDelegate
- (void) didReceiveData:(NSData *) data Mac:(NSString *)mac;
- (void) didConnect:(NSString *) mac;
- (void) shouldDisconnect:(NSString *) mac;
@optional
- (void) didReadHardwareRevisionString:(NSString *) string;
@end

@interface nokeDevice : NSObject <CBPeripheralDelegate>
{
    @public
    
    unsigned char combinedkey[16];
    unsigned char randomkey[4];
    unsigned char status[20];
    unsigned char offlinekey[16];
    unsigned char broadcastdata[5];
}


@property NSString* name;
@property NSString* mac;
@property NSString* uuid;
@property NSString* serial;
@property (nonatomic, retain) NSNumber *rssiLevel;
@property BOOL isOwned;
@property BOOL isSetup;
@property BOOL isConnected;
@property BOOL sync;
@property NLUnlockMethod unlockMethod;
@property BOOL hasLogs;
@property long lastSeen;

@property NSString* offlineUnlockCmd;
@property NSString* preSessionKey;

@property int deviceType;
@property int version;
@property NSString* versionString;
@property NLConnectionStatus connectionStatus;
@property NLAccessStatus accessStatus;


@property CBPeripheral *peripheral;
@property id<nokeDeviceDelegate> delegate;
@property int packetCount;
@property NSMutableArray *dataPackets;
@property NSMutableArray *uploadPackets;
@property NSMutableArray *uploadPacketsWithSession;

@property BOOL outOfRange;

+ (CBUUID *) nokeServiceUUID;
+ (CBUUID *) firmwareUartServiceUUID;

- (nokeDevice *) initWithPeripheral:(CBPeripheral*)peripheral delegate:(id<nokeDeviceDelegate>) delegate;
- (nokeDevice *) initWithName:(NSString*)name Mac:(NSString*)mac;

- (void) writeString:(NSString *) string;
- (void) writeRawData:(NSData *) data;
- (void) addDataToArray:(NSData*) data;
- (void) addStringToUploadArray:(NSString *)strData;
- (void) addSessionToPackets:(NSString*)longitude Latitude:(NSString*)latitude;
- (void) clearUploadArray;
- (void) clearUploadWithSessionArray;
- (void) writeDataArray;
- (void) readStateCharacteristic;
- (void) setStatus:(unsigned char[])data;
- (void) setBroadcastData:(unsigned char[])data;
- (unsigned char*) getStatus;
- (unsigned char*) getBroadcastData;
- (int) RxDataFromLock:(unsigned char[]) data;
- (NSString*)getSessionAsString;
- (NSString *)getBroadcastDataAsString;
- (NSString *)getSoftwareVersion;

-(unsigned char*)createOfflineUnlock:(NSString *)mac Session:(unsigned char[]) session PreSessionKey:(unsigned char[])pressionkey UnlockCmd:(unsigned char[])unlockcmd TimeStamp:(unsigned char[])timestamp;

- (void) didConnect;
- (void) offlineUnlock;

#define strNokeServiceUUID @"DF160001-30B1-49A5-8DC3-E9FDBDFEA489"
#define strRxCharacteristic @"DF160002-30B1-49A5-8DC3-E9FDBDFEA489"
#define strTxCharacteristic @"DF160003-30B1-49A5-8DC3-E9FDBDFEA489"
#define strStateCharacteristic @"DF160004-30B1-49A5-8DC3-E9FDBDFEA489"



@end
