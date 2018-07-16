//
//  nokeDevice.m
//  ios-sdk
//
//  Created by Spencer Apsley on 3/9/16.
//  Copyright © 2016 Noke LLC. All rights reserved.
//

#import "nokeDevice.h"
#import "TI_aes_128.h"


@interface nokeDevice ()
@property CBService *nokeService;
@property CBCharacteristic *rxCharacteristic;
@property CBCharacteristic *txCharacteristic;
@property CBCharacteristic *stateCharacteristic;

@end

@implementation nokeDevice
@synthesize peripheral = _peripheral;
@synthesize delegate = _delegate;

@synthesize name = _name;
@synthesize mac = _mac;
@synthesize uuid = _uuid;
@synthesize serial = _serial;
@synthesize lastSeen = _lastSeen;
@synthesize version = _version;
@synthesize versionString = _versionString;

@synthesize nokeService = _nokeService;
@synthesize rxCharacteristic = _rxCharacteristic;
@synthesize txCharacteristic = _txCharacteristic;
@synthesize stateCharacteristic = _stateCharacteristic;

@synthesize packetCount = _packetCount;
@synthesize dataPackets = _dataPackets;
@synthesize uploadPackets = _uploadPackets;
@synthesize uploadPacketsWithSession = _uploadPacketsWithSession;

@synthesize isSetup = _isSetup;
@synthesize isOwned = _isOwned;
@synthesize accessStatus = _accessStatus;
@synthesize sync    = _sync;
@synthesize unlockMethod = _unlockMethod;
@synthesize hasLogs = _hasLogs;

@synthesize outOfRange = _outOfRange;

//NOKE UUIDS
+ (CBUUID *) nokeServiceUUID
{
    return [CBUUID UUIDWithString:@"1bc50001-0200-d29e-e511-446c609db825"];
}

+ (CBUUID *) txCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"1bc50002-0200-d29e-e511-446c609db825"];
}

+ (CBUUID *) rxCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"1bc50003-0200-d29e-e511-446c609db825"];
}

+ (CBUUID *) stateCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"1bc50004-0200-d29e-e511-446c609db825"];
}

+ (CBUUID *) deviceInformationServiceUUID
{
    return [CBUUID UUIDWithString:@"180A"];
}

+ (CBUUID *) hardwareRevisionStringUUID
{
    return [CBUUID UUIDWithString:@"2A27"];
}

//FIRMWARE UUIDS
+ (CBUUID *) firmwareUartServiceUUID
{
    return [CBUUID UUIDWithString:@"00001530-1212-efde-1523-785feabcd123"];
}

+ (CBUUID *) firmwareTxCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"00001531-1212-efde-1523-785feabcd123"];
}

+ (CBUUID *) firmwareRxCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"00001532-1212-efde-1523-785feabcd123"];
}

+ (CBUUID *) firmwareStateCharacteristicUUID
{
    return [CBUUID UUIDWithString:@"00001533-1212-efde-1523-785feabcd123"];
}

- (nokeDevice *) initWithPeripheral:(CBPeripheral *)peripheral delegate:(id<nokeDeviceDelegate>)delegate
{
    if (self = [super init])
    {
        unsigned char newcombinedkey[] = {0x83, 0xF8, 0x81, 0x7E, 0x8A, 0xA7, 0xF8, 0xAE, 0x60, 0x3E, 0x78, 0xF2, 0xA7, 0xBE, 0x40, 0xDC};
        
        for (int x = 0; x < 16; x++)
        {
            combinedkey[x]= newcombinedkey[x];
        }
        
        unsigned char newrandomkey[] = {0,1,2,3};
        
        for (int x=0; x<3; x++)
        {
            randomkey[x] = newrandomkey[x];
        }       
        
        _peripheral = peripheral;
        _peripheral.delegate = self;
        _delegate = delegate;
    }
    return self;
}

- (nokeDevice *) initWithName:(NSString *)name Mac:(NSString *)mac
{
    _name = name;
    _mac = mac;    
    
    return self;
}

-(void)addSessionToPackets:(NSString*)longitude Latitude:(NSString*)latitude
{
    
    if(_uploadPacketsWithSession == nil)
    {
        _uploadPacketsWithSession = [[NSMutableArray alloc] init];
    }
    
    NSArray* responses = [NSArray arrayWithArray:[self uploadPackets]];
    
    NSDictionary* sessionPacket = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [self getSessionAsString],@"session",
                                   responses, @"responses",
                                   [self mac], @"mac",
                                   longitude, @"longitude",
                                   latitude, @"latitude",
                                   nil];
    
    [_uploadPacketsWithSession addObject:sessionPacket];
    [[self uploadPackets] removeAllObjects];
    
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if(self)
    {
        _name = [coder decodeObjectForKey:@"name"];
        _mac = [coder decodeObjectForKey:@"mac"];
        _uuid = [coder decodeObjectForKey:@"uuid"];
        _version = [coder decodeIntForKey:@"version"];
        _serial = [coder decodeObjectForKey:@"serial"];
        
        _preSessionKey = [coder decodeObjectForKey:@"presessionkey"];
        _offlineUnlockCmd = [coder decodeObjectForKey:@"offlineunlockcmd"];

        _dataPackets = [coder decodeObjectForKey:@"datapackets"];
        _uploadPackets = [coder decodeObjectForKey:@"uploadpackets"];
        
        _isSetup = [coder decodeBoolForKey:@"issetup"];
        _isOwned = [coder decodeBoolForKey:@"isowned"];
        //_accessStatus = [coder decodeIntForKey:@"accessstatus"];
        //_unlockMethod = [coder decodeIntForKey:@"unlockmethod"];
        _hasLogs = [coder decodeBoolForKey:@"haslogs"];
        _versionString = [coder decodeObjectForKey:@"versionstring"];
    }
    
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    //[coder encodeObject:_peripheral forKey:@"peripheral"];
    //[coder encodeObject:_delegate forKey:@"delegate"];
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeObject:_mac forKey:@"mac"];
    [coder encodeObject:_serial forKey:@"serial"];
    [coder encodeObject:_uuid forKey:@"uuid"];
    [coder encodeInteger:_lastSeen forKey:@"lastseen"];
    [coder encodeObject:_versionString forKey:@"versionstring"];
    

    [coder encodeInteger:_packetCount forKey:@"packetcount"];
    [coder encodeObject:_dataPackets forKey:@"datapackets"];
    [coder encodeObject:_uploadPackets forKey:@"uploadpackets"];
    [coder encodeBool:_isSetup forKey:@"issetup"];
    [coder encodeInt:_accessStatus forKey:@"accessstatus"];
    [coder encodeBool:_isOwned forKey:@"isowned"];
    [coder encodeInt:_unlockMethod forKey:@"unlockmethod"];

    [coder encodeObject:_preSessionKey forKey:@"presessionkey"];
    [coder encodeObject:_offlineUnlockCmd forKey:@"offlineunlockcmd"];
    [coder encodeBool:_hasLogs forKey:@"haslogs"];
    [coder encodeInt:_version forKey:@"version"];
}

- (void) didConnect
{
    _peripheral.delegate = self;
    [_peripheral discoverServices:@[self.class.nokeServiceUUID, self.class.deviceInformationServiceUUID]];
}

- (void) setStatus:(unsigned char [])data
{
    for (int x=0; x<20; x++) {
        status[x] = data[x];
    }
}

- (void) setBroadcastData:(unsigned char [])data
{
    if(data != nil)
    {
        for (int x=0; x<5; x++)
        {
            broadcastdata[x] = data[x];
        }
    }
}

- (unsigned char*)getBroadcastData
{
    return getBroadcastData;
}

- (unsigned char*)getStatus
{
    return status;
}


- (void) writeString:(NSString *) string
{
    NSData * data = [NSData dataWithBytes:string.UTF8String length:string.length];
    if ((self.txCharacteristic.properties &
         CBCharacteristicPropertyWriteWithoutResponse) != 0)
    {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else
    {
        NSLog(@"No write property on TX characteristic, %lu.", (unsigned long)self.txCharacteristic.properties);
    }    
}

- (void) addDataToArray:(NSData *)data
{
    if(_dataPackets == nil)
    {
        _dataPackets = [[NSMutableArray alloc] init];
    }
    
    [_dataPackets addObject:data];
}

- (void) addStringToUploadArray:(NSString *)strData
{
    if(_uploadPackets == nil)
    {
        _uploadPackets = [[NSMutableArray alloc] init];
    }
    
    [_uploadPackets addObject:strData];
}

- (void) clearUploadArray
{
    if(_uploadPackets != nil)
    {
        [_uploadPackets removeAllObjects];
    }
}

- (void) clearUploadWithSessionArray
{
    if(_uploadPacketsWithSession != nil)
    {
        [_uploadPacketsWithSession removeAllObjects];
    }
}



- (void) writeDataArray
{
    if((self.txCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0)
    {
        NSData* cmdData = _dataPackets[0];
        
        
        
        [self.peripheral writeValue:cmdData forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else
    {
        NSLog(@"No write property on TX characteristic, %lu", (unsigned long)self.txCharacteristic.properties);
    }
}



- (void) writeRawData:(NSData *) data
{
    if((self.txCharacteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0)
    {
        [self.peripheral writeValue:data forCharacteristic:self.txCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
    else
    {
        NSLog(@"No write property on TX characteristic, %lu", (unsigned long)self.txCharacteristic.properties);
    }
}

- (void) readStateCharacteristic
{
    if(_version == 1)
    {
        NSLog(@"Reading state characteristic!");
        if ((self.stateCharacteristic.properties))
        {
            [self.peripheral readValueForCharacteristic:self.stateCharacteristic];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if(error)
    {
        NSLog(@"Error discovering services: %@", error);
        return;
    }
    
    for (CBService *s in [peripheral services])
    {
        if([s.UUID isEqual:self.class.nokeServiceUUID])
        {
            self.nokeService = s;
            
            [self.peripheral discoverCharacteristics:@[self.class.txCharacteristicUUID, self.class.rxCharacteristicUUID, self.class.stateCharacteristicUUID] forService:self.nokeService];
        }
        else if([s.UUID isEqual:self.class.deviceInformationServiceUUID])
        {
            [self.peripheral discoverCharacteristics:@[self.class.hardwareRevisionStringUUID] forService:s];
        }
    }
}


- (void) peripheral:(CBPeripheral *)periperhal didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error
{
    if(error)
    {
        NSLog(@"Error discovering characteristics: %@", error);
        return;
    }
    
    for (CBCharacteristic *c in [service characteristics])
    {
        if([c.UUID isEqual:self.class.rxCharacteristicUUID])
        {
            self.rxCharacteristic = c;            
            [self.peripheral setNotifyValue:YES forCharacteristic:self.rxCharacteristic];
        }
        else if([c.UUID isEqual:self.class.txCharacteristicUUID])
        {
            self.txCharacteristic = c;
        }
        else if([c.UUID isEqual:self.class.stateCharacteristicUUID])
        {
            self.stateCharacteristic = c;
            [self readStateCharacteristic];
        }
        else if([c.UUID isEqual:self.class.hardwareRevisionStringUUID])
        {
            [self.peripheral readValueForCharacteristic:c];
        }
        else if([c.UUID isEqual:self.class.firmwareRxCharacteristicUUID])
        {
            self.rxCharacteristic = c;
            [self.peripheral setNotifyValue:YES forCharacteristic:self.rxCharacteristic];
            
        }
        else if([c.UUID isEqual:self.class.firmwareTxCharacteristicUUID])
        {
            self.txCharacteristic = c;
            [self.delegate didConnect:self.mac];           
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        NSLog(@"Error receiving notification for characteristic %@: %@", characteristic, error);
        return;
    }
    
    if (characteristic == self.rxCharacteristic)
    {
        NSData *data = [characteristic value];
        unsigned char *bytePtr = (unsigned char *)[data bytes];
        [self RxDataFromLock:bytePtr];
        [self.delegate didReceiveData:data Mac:[self mac]];
        
    }
    else if (characteristic == self.stateCharacteristic)
    {
        NSData *data = [characteristic value];
        [self setStatus:(unsigned char*)[data bytes]];
        [self.delegate didConnect:self.mac];
        //[self.delegate didReceiveData:data];
        
    }
    else if ([characteristic.UUID isEqual:self.class.hardwareRevisionStringUUID])
    {
        NSString *hwRevision = @"";
        NSData *data = [characteristic value];
        unsigned char *bytePtr = (unsigned char *)[data bytes];
        ///const uint8_t *bytes = characteristic.value.bytes;
        for (int i = 0; i <characteristic.value.length; i++)
        {
            NSLog(@"%x", bytePtr[i]);
            hwRevision = [hwRevision stringByAppendingFormat:@"0x%02x, ", bytePtr[i]];
        }
        
        [self.delegate didReadHardwareRevisionString:[hwRevision substringToIndex:hwRevision.length-2]];
    }
}

- (int) RxDataFromLock:(unsigned char [])data
{
    
    switch (data[0]) {
        case SERVER_Dest:
            NSLog(@"Server Packet Received");
            return 0;
            break;
        case APP_Dest:
        {
            NSLog(@"App Packet Receieved");
            NSLog(@"PACKET COUNT: %lu",(unsigned long)[_dataPackets count]);
            if([_dataPackets count] >= 1)
            {
                [_dataPackets removeObjectAtIndex:0];
                
                if([_dataPackets count] >= 1)
                {
                    [self writeDataArray];
                }
            }
            break;
        }
        case INVALID_ResponseType:
            NSLog(@"Invalid Packet Received");
            return 0xff;
            
        default:
            return 0xff;
            break;
    }
    
    switch (data[1]) {
        case SUCCESS_ResultType:
            NSLog(@"SUCCESS Result");
            
            break;
        case INVALIDKEY_ResultType:
            NSLog(@"Invalid Key Result");
            break;
        case INVALIDCMD_ResultType:
            NSLog(@"Invalid Cmd Result");
            break;
        case INVALIDPERMISSION_ResultType:
            NSLog(@"Invalid Permission (wrong key) Result");
            break;
        case LOCKED_ResultType:
            NSLog(@"Locked Result");
            self.connectionStatus = NLConnectionStatusDisconnected;
            break;
        case INVALIDDATA_ResultType:
            NSLog(@"Invalid Data Result");
            break;
        case INVALID_ResultType:
            NSLog(@"INVALID Result");
            break;
        default:
            NSLog(@"UNABLE TO RECOGNIZE RESULT");
            break;
    }
    
    return 0;
    
}

-(NSString *)getSessionAsString
{
    unsigned char* bytes = [self getStatus];
    NSMutableString *hex = [NSMutableString string];
    for (int i=0; i<20; i++)
    {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    NSString *immutableHex = [NSString stringWithString:hex];
    
    return immutableHex;    
}

-(NSString *)getBroadcastDataAsString
{
    unsigned char* bytes = [self getBroadcastData];
    NSMutableString *hex = [NSMutableString string];
    for (int i=0; i<5; i++)
    {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    NSString *immutableHex = [NSString stringWithString:hex];
    
    return immutableHex;
}

-(void)offlineUnlock
{
    if([_preSessionKey length] > 0 && [_offlineUnlockCmd length] > 0)
    {
        
        unsigned char * keyBytes = (unsigned char *)malloc((int)[_preSessionKey length] / 2 + 1);
        bzero(keyBytes, [_preSessionKey length] / 2 + 1);
        for (int i = 0; i < [_preSessionKey length] - 1; i += 2)
        {
            unsigned int anInt;
            NSString * hexCharStr = [_preSessionKey substringWithRange:NSMakeRange(i, 2)];
            NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
            [scanner scanHexInt:&anInt];
            keyBytes[i / 2] = (char)anInt;
        }
        
        unsigned char * cmdBytes = (unsigned char *)malloc((int)[_offlineUnlockCmd length] / 2 + 1);
        bzero(cmdBytes, [_offlineUnlockCmd length] / 2 + 1);
        for (int i = 0; i < [_offlineUnlockCmd length] - 1; i += 2)
        {
            unsigned int anInt;
            NSString * hexCharStr = [_offlineUnlockCmd substringWithRange:NSMakeRange(i, 2)];
            NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
            [scanner scanHexInt:&anInt];
            cmdBytes[i / 2] = (char)anInt;
        }
        
        NSDate *currentDateTime = [NSDate date];
        long timestamp = [currentDateTime timeIntervalSince1970];
        unsigned char timeBytes[4];
        timeBytes[0] = (timestamp >> 24) & 0xFF;
        timeBytes[1] = (timestamp >> 16) & 0xFF;
        timeBytes[2] = (timestamp >> 8)  & 0xFF;
        timeBytes[3] = timestamp & 0xFF;
        
        NSData* data;
        data = [NSData dataWithBytes:[self createOfflineUnlock:self.mac Session:status PreSessionKey:keyBytes UnlockCmd:cmdBytes TimeStamp:timeBytes] length:20];
        [self addDataToArray:data];
        [self writeDataArray];
    }
    else
    {
        
    }
}

unsigned char* combinedKey;
unsigned char* commandPacket;
unsigned char* buffer;

-(unsigned char*) createOfflineCombinedKey:(NSString*)mac Session:(unsigned char[]) session BaseKey:(unsigned char[]) basekey
{
    for (int x=0; x<16; x++)
    {
        int total = basekey[x] + session[x];
        basekey[x] = total;
    }
    
    [self copyArray:combinedKey dataIn:basekey Size:16];
    return combinedKey;
}

-(unsigned char*)createOfflineUnlock:(NSString *)mac Session:(unsigned char[]) session PreSessionKey:(unsigned char[])pressionkey UnlockCmd:(unsigned char[])unlockcmd TimeStamp:(unsigned char[])timestamp
{
    unsigned char key[16];
    unsigned char newCommandPacket[20];
    
    [self copyArray:key dataIn:[self createOfflineCombinedKey:mac Session:session BaseKey:pressionkey] Size:16];
    
    for (int x = 0; x<4; x++)
    {
        newCommandPacket[x] = unlockcmd[x];
    }
    
    unsigned char cmddata[16];
    
    for (int x=0; x<16; x++)
    {
        cmddata[x] = unlockcmd[x+4];
    }
    
    cmddata[2] = timestamp[3];
    cmddata[3] = timestamp[2];
    cmddata[4] = timestamp[1];
    cmddata[5] = timestamp[0];
    
    unsigned char checksum = 0;
    
    for(int x=0;x<15;x++)
    {
        checksum += cmddata[x];
    }
    
    cmddata[15]=checksum;
    
    [self copyArray:newCommandPacket OutStart:4 DataIn:[self encryptPacket:key Data:cmddata] InStart:0 Size:16];
    [self copyArray:commandPacket dataIn:newCommandPacket Size:20];
    return commandPacket;
}

-(void) copyArray:(unsigned char[])dataOut dataIn:(unsigned char[])dataIn Size:(int) size
{
    for (int x = 0; x < size; x++)
        dataOut[x] = dataIn[x];
}

-(void) copyArray:(unsigned char[])dataOut OutStart:(int) outStartByte DataIn:(unsigned char[])dataIn InStart:(int) inStartByte Size:(int) size
{
    for (int x = 0; x < size; x++)
    {
        dataOut[x+outStartByte] = dataIn[x+inStartByte];
    }
}

-(unsigned char*)encryptPacket:(unsigned char [])combinedKey Data:(unsigned char [])data
{
    
    unsigned char tmpKey[16];
    [self copyArray:tmpKey dataIn:combinedKey Size:16];
    aes_enc_dec(data, tmpKey, (unsigned char)1);
    [self copyArray:buffer dataIn:data Size:16];
    return buffer;
}


-(NSString*)getSoftwareVersion
{
    return [self.versionString substringFromIndex:3];
}


-(NSComparisonResult)compareRssiLevel:(nokeDevice *)otherObject{    
    
    int rssi1 = [self.rssiLevel intValue] * -1;
    NSNumber *nsRSSI1 = [NSNumber numberWithInt:rssi1];
    int rssi2 = [otherObject.rssiLevel intValue] * -1;
    NSNumber *nsRSSI2 = [NSNumber numberWithInt:rssi2];
    
    return [nsRSSI1 compare:nsRSSI2];
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    //THIS CAN BE MODIFIED IF YOU DON'T WANT TO CONNECT AT HIGHER RANGES.  -127 IS MAX RANGE.
    NSNumber* threshold = [[NSNumber alloc] initWithInt:-127];
    
    if(RSSI > threshold)
    {
        [self.peripheral discoverServices:nil];
    }
    else
    {
        [self.delegate shouldDisconnect:self.mac];
    }
        
}


@end
