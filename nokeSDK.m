//
//  nokeSDK.m
//  ios-sdk
//
//  Created by Spencer Apsley on 3/9/16.
//  Copyright © 2016 Noke LLC. All rights reserved.
//

#import "nokeSDK.h"
#import "nokeDevice.h"

@implementation nokeSDK
{
    CBCentralManager *cm;
}

@synthesize nokeDevices = _nokeDevices;
@synthesize nokeGroups = _nokeGroups;
@synthesize currentNokeDevice = _currentNokeDevice;
@synthesize globalUploadDataQueue = _globalUploadDataQueue;
@synthesize bluetoothState = _bluetoothState;
@synthesize lastReceivedTime = _lastReceivedTime;

static nokeSDK *sharedNokeSDK;

+ (nokeSDK*) sharedInstance
{
    if (sharedNokeSDK == nil)
    {
        NSDate *currentDateTime = [NSDate date];
        long timestamp = [currentDateTime timeIntervalSince1970];
        
        sharedNokeSDK = [[nokeSDK alloc] initWithDelegate:nil];
        sharedNokeSDK.globalUploadDataQueue = [[NSMutableArray alloc] init];
        sharedNokeSDK.lastReceivedTime = timestamp;
    }
    return sharedNokeSDK;
}

- (nokeSDK*) initWithDelegate:(id<nokeSDKDelegate>) delegate
{
    if (self = [super init])
    {
        _delegate = delegate;
        self.nokeGroups = [[NSMutableArray alloc] init];
        
        //TODO enable 'bluetooth-central' background mode for State restoration of CBCentralManager
        //dispatch_queue_t centralQueue = dispatch_queue_create("central", DISPATCH_QUEUE_SERIAL);
        cm = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:@{CBCentralManagerOptionRestoreIdentifierKey:@"nokeCentralManagerIdentifier"}];
    }
    return self;
}

-(CBCentralManager*)getCentralManager
{
    return cm;
}

-(void)resetCMDelegate
{
    cm.delegate = self;
}

-(void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary<NSString *,id> *)dict
{
    NSLog(@"RESTORING CENTRAL MANAGER STATE");
}

-(void) retrieveKnownPeripherals
{
    NSLog(@"ret-kp-0");
    NSMutableArray *uuidArray = [[NSMutableArray alloc] init];
    for(int i = 0; i<[_nokeDevices count]; i++)
    {
        nokeDevice* noke = [_nokeDevices objectAtIndex:i];
        NSString *uuidstring = noke.uuid;
        NSLog(@"%@",uuidstring);
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:noke.uuid];
        if(uuid != nil)
        {
            NSLog(@"ret-kp-0.0.1");
            [uuidArray addObject:uuid];
        }
    }
    NSLog(@"ret-kp-0.1");
    NSArray *peripherals = [cm retrievePeripheralsWithIdentifiers:uuidArray];
    NSLog(@"ret-kp-1");
    //USED FOR ONE-STEP UNLOCKING FROM THE BACKGROUND
    for(CBPeripheral *periph in peripherals)
    {
        NSLog(@"ret-kp-2");
        nokeDevice* noke = [self nokeWithUUID:periph.identifier.UUIDString];
        noke.peripheral = periph;
        NSLog(@"ret-kp-3");
        if(noke.unlockMethod == NLUnlockMethodOneStep)
        {
            NSLog(@"ret-kp-4");
            if(noke.outOfRange)
            {
                NSLog(@"ret-kp-5");
                [self performSelector:@selector(delayConnect:) withObject:noke afterDelay:10.0];
            }
            else
            {
                NSLog(@"ret-kp-6");
                [self connectToNokeDevice:noke];
            }
        }
    }
}

-(void)delayConnect:(nokeDevice*)noke
{
    noke.outOfRange = false;
    [self connectToNokeDevice:noke];
}

-(void) retrieveUuidArrPeripherals:(NSMutableArray *)uuidArray
{
    NSArray *peripherals = [cm retrievePeripheralsWithIdentifiers:uuidArray];
    
    for(CBPeripheral *periph in peripherals)
    {
        nokeDevice* noke = [[nokeSDK sharedInstance] nokeWithUUID:periph.identifier.UUIDString];
        noke.peripheral = periph;
        
        [self connectToNokeDevice:noke];
    }
}


- (void) addDataPacketToQueue:(NSString*)response Session:(NSString*)session Mac:(NSString*)mac Longitude:(NSString*)longitude Latitude:(NSString*)latitude
{
    NSDate *currentDateTime = [NSDate date];
    long timestamp = [currentDateTime timeIntervalSince1970];
    NSString* timeString = [NSString stringWithFormat:@"%lu", timestamp];
    _lastReceivedTime = timestamp;
    
    
    //THIS CHECKS THE UPLOAD OBJECTS FOR A SESSION THAT MATCHES AND ENSURES THAT ALL DATA PACKETS WITH THE SAME SESSION ARE BUNDLED TOGETHER.
    for (int i = 0; i < [_globalUploadDataQueue count]; i++)
    {
        NSDictionary* dataObject = [_globalUploadDataQueue objectAtIndex:i];
        NSString* dataSession = [dataObject objectForKey:@"session"];
        if([session isEqualToString:dataSession])
        {
            NSMutableArray* responses = [dataObject objectForKey:@"responses"];
            [responses addObject:response];            
            
            NSString* oldtimestamp = [dataObject objectForKey:@"receivedTime"];
            oldtimestamp = [NSString stringWithFormat:@"%lu", timestamp];
            //CACHES DATA FOR UPLOADING IF OFFLINE
            [sharedNokeSDK cacheUploadQueue];
            return;
        }
    }
    
    NSMutableArray* responses = [[NSMutableArray alloc] initWithObjects:response, nil];
    
    NSDictionary* sessionPacket = [NSDictionary dictionaryWithObjectsAndKeys:
                                   session,@"session",
                                   responses, @"responses",
                                   mac, @"mac",
                                   longitude, @"longitude",
                                   latitude, @"latitude",
                                   timeString, @"receivedTime",
                                   nil];
    [_globalUploadDataQueue addObject:sessionPacket];
    //CACHES DATA FOR UPLOADING IF OFFLINE
    [sharedNokeSDK cacheUploadQueue];
}

- (void) startScanForNokeDevices
{
    NSDictionary* scanOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    NSArray* serviceArray = [NSArray arrayWithObjects:nokeDevice.nokeServiceUUID, nokeDevice.firmwareUartServiceUUID, nil];
    
    //Make sure we start scan from scratch
    [cm stopScan];
    [cm scanForPeripheralsWithServices:serviceArray options:scanOptions];
}

-(void) startScanForFirmwareDevices
{
    NSDictionary* scanOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    NSArray* serviceArray = [NSArray arrayWithObjects:nokeDevice.firmwareUartServiceUUID, nil];
    
    
    //Make sure we start scan from scratch
    [cm stopScan];
    [cm scanForPeripheralsWithServices:serviceArray options:scanOptions];
}

- (void) stopScan
{
    [cm stopScan];
}

- (void) connectToNokeDevice:(nokeDevice *)noke
{
    NSLog(@"connectToNokeDevice-1");
    if(noke != nil)
    {
        NSLog(@"connectToNokeDevice-2");
        [self insertNokeDevice:noke];
        NSLog(@"connectToNokeDevice-3");
        NSDictionary* connectOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool: YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey];
        NSLog(@"connectToNokeDevice-4");
        [cm connectPeripheral:[noke peripheral] options:connectOptions];
    }
    NSLog(@"connectToNokeDevice-5");
}

- (void) disconnectNokeDevice:(nokeDevice *)noke
{
    if (noke.peripheral)
    {
        [cm cancelPeripheralConnection:[noke peripheral]];
    }
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    if([central state] == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"Bluetooth Enabled");
        [_delegate isBluetoothEnabled:YES];
        [self retrieveKnownPeripherals];
        _bluetoothState = YES;
        NSLog(@"Finished Bluetooth Enabled");
        //[self startScanForNokeDevices];
    }
    else
    {
        [_delegate isBluetoothEnabled:NO];
        _bluetoothState = NO;
    }
}

-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    unsigned char *broadcastData = (unsigned char*)[[advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey] bytes];
    //////////USE BROADCAST OR PERIPHERAL NAME/////////////
    NSString* broadcastName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    if(broadcastName == nil || broadcastName == NULL || [broadcastName length] != PERIPHERAL_NAME_LENGTH){
        broadcastName = peripheral.name;
        NSLog(@"DEBUG-CM-0");
    }
    
    NSString* newMac;
    if(broadcastName != nil)
    {
        //THIS CHECKS FOR THE OLD FIRMWARE TO PREVENT CRASHING
        if([broadcastName containsString:@"FOB"])
        {
            NSString* mac = [[broadcastName substringFromIndex:6] substringToIndex:11];
            NSMutableString *macWithColons = [NSMutableString stringWithString:mac];
            [macWithColons insertString:@":" atIndex:2];
            [macWithColons insertString:@":" atIndex:5];
            [macWithColons insertString:@":" atIndex:8];
            [macWithColons insertString:@":" atIndex:11];
            [macWithColons insertString:@":" atIndex:14];
            newMac = macWithColons;
        }
        else if([broadcastName length] == PERIPHERAL_NAME_LENGTH && [broadcastName containsString:@"NOKE"])
        {
            NSString* mac = [[broadcastName substringFromIndex:7] substringToIndex:12];
            NSMutableString *macWithColons = [NSMutableString stringWithString:mac];
            [macWithColons insertString:@":" atIndex:2];
            [macWithColons insertString:@":" atIndex:5];
            [macWithColons insertString:@":" atIndex:8];
            [macWithColons insertString:@":" atIndex:11];
            [macWithColons insertString:@":" atIndex:14];
            newMac = macWithColons;
        }
        else
        {
            newMac = @"??:??:??:??:??:??";
        }
    }
    NSLog(@"%@",newMac);
    nokeDevice *noke = [self nokeWithMac:newMac];
    if(noke != nil)
    {
        NSLog(@"DEBUG-CM-1");
        if(noke.isOwned)
        {
        noke.peripheral = peripheral;
        noke.delegate = sharedNokeSDK;
        noke.uuid = peripheral.identifier.UUIDString;
        [noke setBroadcastData:broadcastData];

        if(broadcastData != nil && broadcastData != NULL)
        {
            NSLog(@"DEBUG-CM-2");
            [noke setBroadcastData:broadcastData];
            NSLog(@"DEBUG-CM-3");
            unsigned char *broadcastBytes = [noke getBroadcastData];
            unsigned char statusByte = broadcastBytes[2];
            int status = [[NSNumber numberWithUnsignedChar:statusByte] intValue];
            int setupflag = (status) & 0x01;
            
            if(setupflag == 1)
            {
                noke.isSetup = true;
            }
            else
            {
                noke.isSetup = false;
            }
            
            unsigned char majorVersion = broadcastData[3];
            unsigned char minorVersion = broadcastData[4];
            NSString* hardwareVersion = [[broadcastName substringFromIndex:4] substringToIndex:2];
            NSLog(@"DEBUG-CM-4");
            noke.versionString = [NSString stringWithFormat:@"%@-%d.%d", hardwareVersion, (int)majorVersion, (int)minorVersion];
            noke.version = 1;
        }
        else
        {
            if([broadcastName containsString:@"FOB"])
            {
                noke.versionString = @"1F-1.0";
            }
            else
            {
                noke.versionString = @"1P-1.0";
            }
            noke.version = 0;
        }
        
        [self insertNokeDevice:noke];
        
        }
        NSLog(@"didDiscoverNokeDevice-2");
        [self.delegate didDiscoverNokeDevice:noke RSSI:RSSI];

        
    }
    else
    {
        nokeDevice *noke = [[nokeDevice alloc] initWithName:peripheral.name Mac:newMac];
        noke.peripheral = peripheral;
        noke.delegate = sharedNokeSDK;
        
        NSString* broadcastName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        if(broadcastName == nil || broadcastName == NULL || [broadcastName length] != PERIPHERAL_NAME_LENGTH){
            broadcastName = peripheral.name;
        }
        if([broadcastName containsString:@"NOKE2F"] || [broadcastName containsString:@"FOB"])
        {
            noke.deviceType = NLDeviceTypeFob;
        }
        else
        {
            noke.deviceType = NLDeviceTypePadlock;
        }
        
        
        if(broadcastData != nil && broadcastData != NULL)
        {
            [noke setBroadcastData:broadcastData];
        
            unsigned char *broadcastBytes = [noke getBroadcastData];
            unsigned char statusByte = broadcastBytes[2];
            int status = [[NSNumber numberWithUnsignedChar:statusByte] intValue];
            int setupflag = (status) & 0x01;
        
            if(setupflag == 1)
            {
                noke.isSetup = true;
            }
            else
            {
                noke.isSetup = false;
            }
            
            unsigned char majorVersion = broadcastData[3];
            unsigned char minorVersion = broadcastData[4];
            NSString* hardwareVersion = [[broadcastName substringFromIndex:4] substringToIndex:2];
            
            noke.versionString = [NSString stringWithFormat:@"%@-%d.%d", hardwareVersion, (int)majorVersion, (int)minorVersion];
            noke.version = 1;
        }
        else
        {
            if([broadcastName containsString:@"FOB"])
            {
                noke.versionString = @"1F-1.0";
            }
            else
            {
                noke.versionString = @"1P-1.0";
            }
            noke.version = 0;
        }
        
        noke.isOwned = false;
        
        [self insertNokeDevice:noke];
        NSLog(@"didDiscoverNokeDevice-1");
        [self.delegate didDiscoverNokeDevice:noke RSSI:RSSI];
    }
}
    

    
-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{    
    nokeDevice *noke = [self nokeWithPeripheral:peripheral];
    
    noke.delegate = sharedNokeSDK;
    noke.peripheral.delegate = noke.self;
    
    if(noke.unlockMethod == NLUnlockMethodOneStep)
    {
        [peripheral readRSSI];
    }
    else
    {
        [noke.peripheral discoverServices:nil];
    }
    
    if(!noke)
    {
        return;
    }
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{   
    nokeDevice *noke = [self nokeWithPeripheral:peripheral];
    [self.delegate didDisconnect:noke];
}


- (void) didReceiveData:(NSData*)data Mac:(NSString *)mac
{
    nokeDevice* noke = [self nokeWithMac:mac];
    [_delegate didReceiveData:data Noke:noke];
}


-(void) insertNokeDevice:(nokeDevice *)noke
{
    if([self nokeDevices] == nil)
    {
        self.nokeDevices = [[NSMutableArray alloc]init];
    }
    
    nokeDevice* tmpNoke = [self nokeWithMac:noke.mac];
    
    if(tmpNoke == nil)
    {
        [self.nokeDevices addObject:noke];
        [self saveNokeDevices];
    }
}



-(nokeDevice*) nokeWithUUID:(NSString *)uuid
{
    for (nokeDevice* noke in _nokeDevices)
    {
        if ([noke.uuid isEqualToString:uuid])
        {
            return noke;
        }
    }
    return nil;
}

-(nokeDevice*) nokeWithMac:(NSString *)mac
{
    for (nokeDevice* noke in _nokeDevices)
    {
        if([noke.mac isEqualToString:mac])
        {
            return noke;
        }
    }
    return nil;
}

-(nokeDevice*) nokeWithPeripheral:(CBPeripheral*) peripheral
{
    for (nokeDevice* noke in _nokeDevices)
    {
        if ([noke.peripheral isEqual:peripheral])
        {
            return noke;
        }
    }
    return nil;
}

-(void)removeLockFromArray:(nokeDevice*)noke
{
    [_nokeDevices removeObject:noke];
}


-(void)removeAllLocks
{
    for(int i = 0; i < [_nokeDevices count]; i++)
    {
        nokeDevice* noke = [_nokeDevices objectAtIndex:i];
        if(noke.deviceType != NLDeviceTypeFob)
        {
            [self.nokeDevices removeObject:noke];
            i--;
        }
    }
}

-(void)removeAllFobs
{
    for(int i = 0; i < [_nokeDevices count]; i++)
    {
        nokeDevice* noke = [_nokeDevices objectAtIndex:i];
        if(noke.deviceType == NLDeviceTypeFob)
        {
            [self.nokeDevices removeObject:noke];
            i--;
        }
    }
}

-(void)didConnect:(NSString *)mac
{
    if(mac != nil)
    {
        nokeDevice* noke = [self nokeWithMac:mac];
        if(noke.unlockMethod == NLUnlockMethodOneStep)
        {
            NSLog(@"didDiscoverNokeDevice-3");
            [self.delegate didDiscoverNokeDevice:noke RSSI:noke.rssiLevel];
                
        }
            
        [_delegate didConnect:noke];
        //[noke offlineUnlock];        
    }
}

-(void)saveNokeDevices
{
    //ENCODES NOKE DEVICES FOR STORAGE IN USERDEFAULTS
    NSMutableArray* encodedNokeDevices = [[NSMutableArray alloc] init];
    
    for(int i = 0; i<[_nokeDevices count]; i++)
    {
        nokeDevice* noke = [_nokeDevices objectAtIndex:i];
        NSData* encodedNoke = [NSKeyedArchiver archivedDataWithRootObject:noke];
        [encodedNokeDevices addObject:encodedNoke];        
    }
    
    /**UNCOMMENT IF YOU WANT TO STORE THE LOCKS TO THE USER DEFAULTS
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString* keyName = [NSString stringWithFormat:@"nokeDevicesArray-%@", [[LocksViewController sharedInstance] getEmail]];
    [def setObject:encodedNokeDevices forKey:keyName];
     **/
}

-(NSArray*)getSavedNokeDevices
{
    
    NSMutableArray *savedNokeDevices = [[NSMutableArray alloc] init];
    
    /**UNCOMMENT IF USING LOCAL STORAGE TO STORE NOKE LOCKS
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString* keyName = [NSString stringWithFormat:@"nokeDevicesArray-%@", [[LocksViewController sharedInstance] getEmail]];
    NSArray* encodedNokeDevices = [def objectForKey:keyName];
    
    for(int i=0; i < [encodedNokeDevices count]; i++)
    {
        NSData* encodedNoke = [encodedNokeDevices objectAtIndex:i];
        [savedNokeDevices addObject:(nokeDevice*) [NSKeyedUnarchiver unarchiveObjectWithData:encodedNoke]];
    }
     **/
    
    return savedNokeDevices;
}

-(void)cacheUploadQueue
{
    //STORES DATA FROM UPLOAD QUEUE IN LOCAL STORAGE FOR UPLOADING WHEN ONLINE
    /**
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setObject:[sharedNokeSDK globalUploadDataQueue] forKey:@"cachedQueue"];
    NSLog(@"CACHED UPLOAD QUEUE. COUNT: %lu",(unsigned long)[[sharedNokeSDK globalUploadDataQueue] count]);
     **/
}

-(void)retrieveUploadQueue
{
    //RETRIVES CACHED DATA FOR UPLOADING
    /**
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSArray* cachedUploadQueue = [def objectForKey:@"cachedQueue"];
    
    for(int i=0; i < [cachedUploadQueue count]; i++)
    {
        NSDictionary* upload = [cachedUploadQueue objectAtIndex:i];
        [[sharedNokeSDK globalUploadDataQueue] addObject:upload];
    }    
    
    NSLog(@"RETRIEVED UPLOAD QUEUE. COUNT: %lu", (unsigned long)[[sharedNokeSDK globalUploadDataQueue] count]);
    **/
    
}

-(void)shouldDisconnect:(NSString *)mac
{
    nokeDevice* noke = [self nokeWithMac:mac];
    
    if(noke != nil)
    {
        noke.outOfRange = true;
        [self disconnectNokeDevice:noke];        
    }
}


@end
