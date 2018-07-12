//
//  LocksViewController.m
//  ios-enterprise
//
//  Created by Spencer Apsley on 4/29/16.
//  Copyright © 2016 Noke. All rights reserved.
//
#import "NokeViewController.h"
#include "nokeSDK.h"
#import "nokeClient.h"
#import <LocalAuthentication/LocalAuthentication.h>


@interface NokeViewController ()

@end

@implementation NokeViewController

@synthesize mCallback = _callback;
@synthesize mUtil = _util;
@synthesize mClient = _client;


static NokeViewController *nokeViewController;

+ (NokeViewController*) sharedInstance
{
    if(nokeViewController == nil)
    {
        nokeViewController = [[NokeViewController alloc] init];
    }
    return nokeViewController;
}
-(void) startNokeScan:(char*)name mac:(char*)lockMacAddr callback:(callbackfunc)callback client_func:(clientfunc)client_func util:(void*)util{
    _callback = callback;
    _util = util;
    _client = client_func;

    NSString* NSlockMacAddr = [NSString stringWithUTF8String:lockMacAddr];
    NSString* NSname = [NSString stringWithUTF8String:name];

    NokeDevice *noke = [[NokeViewController alloc] initWithName:NSname Mac:NSlockMacAddr];
    //Hard coding this in nokeClient
    //[nokeClient setToken:'my token here'];
    [[NokeDeviceManager sharedNokeSDK] insertNokeDevice:noke];
    //Start scanning
    [[nokeSDK sharedInstance] startScanForNokeDevices];
}

-(NSString*) requestCommandStr:(NSString*)session Mac:(NSString*)mac{
    NSString *NSsession = [session UTF8String];
    NSString *NSmac     = [mac UTF8String];
    const char* response = self.client_func(NSsession,NSmac,self.util);
    NSString *NSresponse = NSString stringWithUTF8String:response];
    return NSresponse
}

#pragma mark - Reachability
- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *reachability = [notification object];
    [self logReachability: reachability];
}

- (void)logReachability:(Reachability *)reachability {
    NSString *whichReachabilityString = nil;

    if (reachability == self.hostReachability)
    {
        whichReachabilityString = @"Noke Pro";
    }

    NSString *howReachableString = nil;

    switch (reachability.currentReachabilityStatus)
    {
        case NotReachable: {
            howReachableString = @"not reachable";
            break;
        }
        case ReachableViaWWAN: {
            howReachableString = @"reachable by cellular data";
            break;
        }
        case ReachableViaWiFi: {
            howReachableString = @"reachable by Wi-Fi";
            break;
        }
    }

    NSLog(@"%@ %@", whichReachabilityString, howReachableString);
}

#pragma mark - CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *currentLocation = [locations lastObject];

    if(currentLocation != nil)
    {
        longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        latitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
}

-(void)getCurrentLocation
{
// pass
}
#pragma mark - nokeSDKDelegate
-(void)isBluetoothEnabled:(bool)enabled
{
    //CHECKS IF BLUETOOTH IS OFF OR ON
    NSLog(@"BLUETOOTH IS ON: %d", enabled);
}
//TODO this function sends session to server
-(void)didDiscoverNokeDevice:(nokeDevice *)noke RSSI:(NSNumber *)RSSI
{
    //ONLY ADD LOCKS TO LIST
    if(noke.deviceType != NLDeviceTypeFob)
    {
        for(int i = 0; i < [connectedLocks count]; i++)
        {
            //UPDATES LOCK INFO IF LOCK IS ALREADY IN LIST

            nokeDevice* tmpNoke = [connectedLocks objectAtIndex:i];
            if([tmpNoke.mac isEqualToString:noke.mac])
            {
                tmpNoke.lastSeen = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);

                unsigned char *broadcastBytes = [noke getBroadcastData];
                unsigned char statusByte = broadcastBytes[2];
                int status = [[NSNumber numberWithUnsignedChar:statusByte] intValue];
                int setupflag = (status) & 0x01;
                int logflag = (status >> 1) &0x01;

                if(setupflag == 1)
                {
                    noke.isSetup = true;
                }
                else
                {
                    noke.isSetup = false;
                }

                if(logflag == 1)
                {
                    noke.hasLogs = true;
                    [[nokeSDK sharedInstance] connectToNokeDevice:noke];
                }

                return;
            }
        }

        noke.lastSeen = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
        noke.connectionStatus = NLConnectionStatusDisconnected;

        //CHECK BROADCAST DATA
        unsigned char *broadcastBytes = [noke getBroadcastData];
        unsigned char statusByte = broadcastBytes[2];
        int status = [[NSNumber numberWithUnsignedChar:statusByte] intValue];
        int logflag = (status >> 1) &0x01;
        if(logflag == 1)
        {
            noke.hasLogs = true;
        }

        [connectedLocks insertObject:noke atIndex:0];

        //GETS LOCK INFO AFTER DISCOVERING
        //FIN-TODO add function for sending data to my server here
        [nokeClient findLock:noke.mac Noke:noke Delegate:self];

        NSIndexPath* index = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
        [_locksTableView reloadData];
        [_locksTableView  reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationFade];

    }
    else
    {
        //FOUND FOB
    }
}

-(void)didConnect:(nokeDevice *)noke
{
    NSLog(@"CONNECTED TO DEVICE");
    NSString *update = @"CONNECTED TO DEVICE";
    const char* updateChar = [update UTF8String];
    self.callback(updateChar,self.util);
    NSLog(@"CURRENT REACHABILITY STATUS: %ld", (long)self.hostReachability.currentReachabilityStatus);
    dispatch_async(dispatch_get_main_queue(), ^{
        noke.isConnected = true;
        noke.connectionStatus = NLConnectionStatusCheckingPermission;
    });

    if([self isSupportedFirmware:noke])
    {
        [self performSelector:@selector(afterDataWaitReceive:) withObject:noke afterDelay:0.1];
    }
}

-(void)didDisconnect:(nokeDevice *)noke
{
    NSLog(@"DID DISCONNECT!");
    [[nokeSDK sharedInstance] stopScan];
    noke.isConnected = false;

    for(int i=0; i<[connectedLocks count]; i++)
    {
        nokeDevice* tmpNoke = [connectedLocks objectAtIndex:i];

        if([tmpNoke.mac isEqualToString:noke.mac])
        {
            [connectedLocks removeObjectAtIndex:i];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{

        [_locksTableView reloadData];
    });

    [self performSelector:@selector(removeLockFromTable:) withObject:noke afterDelay:1.0];

    [nokeClient uploadData:self];
    [[nokeSDK sharedInstance] retrieveKnownPeripherals];
}

-(void)didReceiveData:(NSData *)data Noke:(nokeDevice *)noke
{
    NSLog(@"DID RECEIVE DATA: %@", data);

    unsigned char* dataArray = (unsigned char*) [data bytes];

    if(dataArray[0] == SERVER_Dest)
    {
        //RECEIVED A SERVER PACKET. CONVERT TO A STRING AND ADD TO "UPLOAD QUEUE"
        NSMutableString *hex = [NSMutableString string];
        for (int i=0; i<20; i++)
        {
            [hex appendFormat:@"%02x", dataArray[i]];
        }
        NSString *immutableHex = [NSString stringWithString:hex];
        NSLog(@"Received SERVER packet: %@", immutableHex);

        [[nokeSDK sharedInstance] addDataPacketToQueue:immutableHex Session:[noke getSessionAsString] Mac:[noke mac] Longitude:longitude Latitude:latitude];
    }
    else if(dataArray[0] == APP_Dest)
    {
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(afterDataWaitReceive:) object:noke];

        NSMutableString *hex = [NSMutableString string];
        for (int i=0; i<20; i++)
        {
            [hex appendFormat:@"%02x", dataArray[i]];
        }
        NSString *immutableHex = [NSString stringWithString:hex];

        NSLog(@"Received APP packet: %@", immutableHex);

        if(dataArray[1] == SUCCESS_ResultType){
            if([[noke dataPackets] count] == 0){
                noke.connectionStatus = NLConnectionStatusUnlocked;
                dispatch_async(dispatch_get_main_queue(), ^{
                [noke addSessionToPackets:longitude Latitude:latitude];
                [nokeClient uploadData:self]; //USED FOR INTERNAL TESTING
                NSIndexPath* index = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
                [_locksTableView  reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationNone];
                //[_locksTableView reloadData];
                });
            }
        }
    }
}

#pragma mark - nokeClientDelegate
-(void)didReceiveResponse:(NSDictionary *)data
{
    //Received response
}
//TODO this section send data to bluetooth lock to unlock
-(void)didReceiveNokeResponse:(NSString *)data Noke:(nokeDevice *)noke
{
    if(data != nil)
    {


//        if([result isEqualToString:@"failure"])
//        {
//            NSString* message = [data objectForKey:@"message"];
//            int errorCode = [[data valueForKey:@"errorCode"] intValue];
//
//            if(errorCode == ERROR_TOKEN)
//            {
//                //HANDLE AN EXPIRED TOKEN.  EITHER REQUIRE THE USER TO RE-LOGIN OR AUTOMATICALLY RE-LOGIN FOR THEM
//            }
//            else if(errorCode == ERROR_LOCK_NOT_FOUND || [message isEqualToString:@"Lock not setup"])
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Setup Lock", nil) message:NSLocalizedString(@"Please name your lock", nil) preferredStyle:UIAlertControllerStyleAlert];
//                    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
//                     {
//                         NSString* identifier = [[noke.peripheral.name substringFromIndex:15] substringToIndex:4];
//                         textField.placeholder = NSLocalizedString(@"Lock Name", nil);
//                         //textField.text = @"";
//                     }];
//
//                    UIAlertAction *okAction = [UIAlertAction
//                                               actionWithTitle:NSLocalizedString(@"OK", nil)
//                                               style:UIAlertActionStyleDefault
//                                               handler:^(UIAlertAction *action)
//                                               {
//                                                   UITextField *name = alertController.textFields.firstObject;
//
//                                                   NSIndexPath* path = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
//                                                   [self updateStatusText:NSLocalizedString(@"Setup", nil) Path:path];
//                                                   noke.name = name.text;
//                                                   noke.connectionStatus = NLConnectionStatusSetup;
//                                                   [_locksTableView reloadData];
//
//                                                   [nokeClient setupLock:noke Name:name.text Delegate:self];
//
//                                               }];
//                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
//                                                   {
//
//                                                       [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
//                                                       noke.connectionStatus = NLConnectionStatusDisconnected;
//
//                                                   }];
//
//                    [alertController addAction:okAction];
//                    [alertController addAction:cancelAction];
//
//                    [self presentViewController:alertController animated:TRUE completion:nil];
//
//
//                });
//            }
//            else if(errorCode == ERROR_NO_ACTIVE_SCHEDULE || errorCode == ERROR_PERMISSION_DENIED)
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                        UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You do not have access to this lock.  Please contact your administrator", nil) preferredStyle:UIAlertControllerStyleAlert];
//
//                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
//                        [failedController addAction:okAction];
//
//                        [self presentViewController:failedController animated:TRUE completion:nil];
//                    });
//
//                [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
//                noke.connectionStatus = NLConnectionStatusDisconnected;
//                noke.unlockMethod = NLUnlockMethodTwoStep;
//                [_locksTableView reloadData];
//            }
//            else
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Something went wrong.  Please contact your administrator", nil) preferredStyle:UIAlertControllerStyleAlert];
//
//                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
//                        [failedController addAction:okAction];
//
//                    [self presentViewController:failedController animated:TRUE completion:nil];
//
//                    [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
//                    noke.connectionStatus = NLConnectionStatusDisconnected;
//                    noke.unlockMethod = NLUnlockMethodTwoStep;
//                    [_locksTableView reloadData];
//                });
//            }
//        }
        ///FIN-TODO send noke command string to lock here

        ///NSDictionary* objData = [data objectForKey:@"data"];
        ///NSArray* commands = data;///[objData objectForKey:@"commands"];
        if([noke dataPackets] != nil)
        {
            [[noke dataPackets] removeAllObjects];
        }

//        for(int i = 0; i < [commands count]; i++)
//       {
        NSString* hexString = data

        char * myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
        bzero(myBuffer, [hexString length] / 2 + 1);
        for (int i = 0; i < [hexString length] - 1; i += 2)
        {
            unsigned int anInt;
            NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
            NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
            [scanner scanHexInt:&anInt];
            myBuffer[i / 2] = (char)anInt;
        }

        NSData* cmdData = [NSData dataWithBytes:myBuffer length:20];
        [noke addDataToArray:cmdData]; //Adds the cmd to data array then writeData Array send its to the lock
//       }

        if([[noke dataPackets] count] > 0)
        {
            if([[noke dataPackets] count] > 1)
            {
                dispatch_async(dispatch_get_main_queue(), ^{

                    NSIndexPath* path = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
                    [self updateStatusText:NSLocalizedString(@"Syncing", nil) Path:path];

                });
            }

            [noke writeDataArray]; // Sends data to lock here
            [self performSelector:@selector(checkDataQueue:) withObject:noke afterDelay:3.0];
            [self performSelector:@selector(uploadDataTimeout:) withObject:noke afterDelay:10.0];
        }

    }
    else
    {
          NSLog(@"Error, data response is nil");
//        //IF WE DON'T RECEIVE A RESPONSE FROM THE SERVER, UNLOCK OFFLINE (IF THEY HAVE OFFLINE PERMISSION)
//        if([noke.preSessionKey length] > 0 && [noke.offlineUnlockCmd length] > 0)
//        {
//            [noke offlineUnlock];
//        }
//        else
//        {
//            //IF THEY DON'T HAVE OFFLINE ACCESS, DISPLAY A MESSAGE
//            dispatch_async(dispatch_get_main_queue(), ^{
//                UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You do not have offline access to this lock. Please check your internet connection.", nil) preferredStyle:UIAlertControllerStyleAlert];
//
//                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
//                [failedController addAction:okAction];
//
//                [self presentViewController:failedController animated:TRUE completion:nil];
//            });
//        }
    }
}
///TODO this section returns and parses server response
-(void)didReceiveFindLockResponse:(NSDictionary *)data Noke:(nokeDevice *)noke
{
    NSString* result = [data objectForKey:@"result"];

    if([result isEqualToString:@"success"])
    {
        NSDictionary* response = [data objectForKey:@"data"];
        if(response != nil)
        {

            NSString* name = [response objectForKey:@"name"];
            NSString* serial = [response objectForKey:@"serial"];

            NSArray* groups = [response objectForKey:@"groups"];

            noke.accessStatus = NLAccessStatusNone;

            for(int x = 0; x < [groups count]; x++)
            {
                NSDictionary* group = [groups objectAtIndex:x];
                if([[group objectForKey:@"status"] isEqualToString:@"live"])
                {
                    noke.accessStatus = NLAccessStatusLive;
                    noke.isOwned = true;
                }
            }


            if(![noke.name isEqualToString:name] || [noke.serial isEqualToString:@""])
            {
                if(![name isEqualToString:@""])
                {
                    noke.name = name;
                }
                noke.serial = serial;
            }

            dispatch_async(dispatch_get_main_queue(), ^{

                //[_locksTableView reloadData];

                NSIndexPath* index = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
                [_locksTableView  reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationNone];

            });
        }
        else
        {
            NSDictionary* response = [data objectForKey:@"response"];

            NSString* name = [response objectForKey:@"name"];
            NSString* serial = [response objectForKey:@"serial"];

            NSArray* groups = [response objectForKey:@"groups"];
            noke.accessStatus = NLAccessStatusNone;

            for(int x = 0; x < [groups count]; x++)
            {
                NSDictionary* group = [groups objectAtIndex:x];

                NSLog(@"GROUP STATUS: %@", [group objectForKey:@"status"]);

                if([[group objectForKey:@"status"] isEqualToString:@"live"])
                {
                    noke.accessStatus = NLAccessStatusLive;
                    noke.isOwned = true;
                }
            }


            if(![noke.name isEqualToString:name] || [noke.serial isEqualToString:@""])
            {
                if(![name isEqualToString:@""])
                {
                    noke.name = name;
                }
                noke.serial = serial;
            }

            });

        }
    }
}
#pragma mark Getters and Setters
-(void)setIsLoggedIn:(BOOL)loggedin
{
    isLoggedIn = loggedin;
}

-(void)setUserData:(NSString *)name Email:(NSString *)email Flag:(int)flag CompanyName:(NSString *)company
{
    username = name;
    useremail = email;
    installerFlag = flag;
    companyname = company;
}

-(NSString *)getEmail
{
    return useremail;
}

-(NSString *)getCompany
{
    return companyname;
}

-(NSString *)getUsername
{
    return username;
}

-(void)setPassword:(NSString*)password
{
    userpassword = password;
}

-(NSString *)getPassword
{
    return userpassword;
}

-(int)getInstallerFlag
{
    return installerFlag;
}

#pragma mark Timer Methods
-(void) refreshToken
{
    if(self.hostReachability.currentReachabilityStatus != 0)
    {
        [nokeClient refreshToken];
    }

}

-(void) checkUploadData
{
    NSDate *currentDateTime = [NSDate date];
    long timestamp = [currentDateTime timeIntervalSince1970];

    long timeDiff = timestamp - [nokeSDK sharedInstance].lastReceivedTime;

    if(timeDiff >= 10)
    {
        if([[[nokeSDK sharedInstance] globalUploadDataQueue] count] > 0)
        {
            [nokeClient uploadData:self];
        }
    }
}

-(void)checkDataQueue:(nokeDevice*)noke
{
    if([[noke dataPackets] count] > 0)
    {
        [[noke dataPackets] removeObjectAtIndex:0];

        if([[noke dataPackets] count] > 0)
        {
            [noke writeDataArray];
        }
    }
}

-(void)uploadDataTimeout:(nokeDevice*)noke
{
    [noke addSessionToPackets:longitude Latitude:latitude];
    if(self.hostReachability.currentReachabilityStatus != 0)
    {
        if([[noke uploadPacketsWithSession] count] > 0)
        {
            //[nokeClient uploadData:noke Longitude:longitude Latitude:latitude Delegate:self];
        }
    }
}

-(void)refreshLockList
{
    for(int i = 0; i < [connectedLocks count]; i++)
    {
        nokeDevice* tmpNoke = [connectedLocks objectAtIndex:i];
        long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);

        long timediff = currentTime - tmpNoke.lastSeen;

        if(timediff >= 5 && !tmpNoke.isConnected)
        {
            [connectedLocks removeObjectAtIndex:i];
            [_locksTableView reloadData];
        }
    }
}


-(void)afterDataWaitReceive:(nokeDevice *)noke
{
    NSIndexPath* path = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
    [self updateStatusText:@"Verifying" Path:path];

    int reachability = self.hostReachability.currentReachabilityStatus;

    if(!noke.hasLogs || noke.unlockMethod == NLUnlockMethodOneStep)
    {
        if(reachability == 0)
        {
            if([noke.preSessionKey length] > 0 && [noke.offlineUnlockCmd length] > 0)
            {
                [noke offlineUnlock];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You do not have offline access to this lock.  Please check your internet connection.", nil) preferredStyle:UIAlertControllerStyleAlert];

                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                    [failedController addAction:okAction];

                    [self presentViewController:failedController animated:TRUE completion:nil];
                });
            }
        }
        else
        {
            [nokeClient unlock:noke Delegate:self];
        }
    }
    else
    {
        noke.hasLogs = false;
        [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
        //[_locksTableView reloadData];
    }
}

-(void)startDisconnectTimer:(nokeDevice *)noke
{
    /**
     disconnectTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(disconnectNoke:) userInfo:noke repeats:NO];
     [disconnectTimer fire];
     **/
    [self performSelector:@selector(disconnectNoke:) withObject:noke afterDelay:3.0];
}

-(void)stopDisconnectTimer:(nokeDevice *)noke
{
    /**
     if(disconnectTimer != nil)
     {
     [disconnectTimer invalidate];
     }
     **/
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnectNoke:) object:noke];
}

-(void)disconnectNoke:(nokeDevice *)noke
{
    [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
}

-(BOOL)isSupportedFirmware:(nokeDevice*)noke
{
    int majorversion = [[[[noke getSoftwareVersion] substringFromIndex:0] substringToIndex:1] intValue];
    //NSLog(@"MAJOR VERSION: %d", majorversion);

    int minorversion = [[[noke getSoftwareVersion] substringFromIndex:2] intValue];
    //NSLog(@"MINOR VERSION: %d", minorversion);


    if(majorversion >= 2 && minorversion >= 3)
    {
        return true;
    }
    else
    {
        return false;
    }
}

@end

void StartUnlock(char* name, char* lockMacAddr,callbackfunc callback, clientfunc client_func, void *util){
    [[NokeViewController* sharedInstance] startNokeScan:name mac:lockMacAddr callback:callback client_func:client_func util:util];
}