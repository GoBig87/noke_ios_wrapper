//
//  LocksViewController.m
//  ios-enterprise
//
//  Created by Spencer Apsley on 4/29/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import "LocksViewController.h"
#include "nokeSDK.h"
#import "nokeClient.h"
#import "LoginViewController.h"

#import "LockDetailsViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>


@interface LocksViewController ()

@end

@implementation LocksViewController
{
    CLLocationManager *locationManager;
    NSString* longitude;
    NSString* latitude;
    NSTimer* disconnectTimer;
}

static LocksViewController *locksViewController;
+ (LocksViewController*) sharedInstance
{
    if(locksViewController == nil)
    {
        locksViewController = [[LocksViewController alloc] init];
        
    }
    return locksViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];    
    
    self.hostReachability = [Reachability reachabilityWithHostName:@"www.nokepro.com"];
    [self.hostReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object: nil];
    [self logReachability:self.hostReachability];
    
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]]; /*#2b3990*/
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [UIColor blackColor],
                                                                      NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:20.0f]
                                                                      }];
    self.title = NSLocalizedString(@"Locks", nil);
    
    
    [self.view setBackgroundColor:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]];
    
    _locksTableView.delegate = self;
    _locksTableView.dataSource = self;
    _locksTableView.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    _locksTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_lockTabBar setBackgroundColor:[UIColor redColor]];
    
    connectedLocks = [[NSMutableArray alloc] init];
    locationManager = [[CLLocationManager alloc] init];
    
    //TIMERS
    //Checks if locks have disconnected/gone out of range and removes from the list
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(refreshLockList) userInfo:nil repeats:YES];
    //Refreshes login token as long as the app is open
    [NSTimer scheduledTimerWithTimeInterval:600.0f target:self selector:@selector(refreshToken) userInfo:nil repeats:YES];
    //Checks for any data from the lock that needs to be uploaded
    [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(checkUploadData) userInfo:nil repeats:YES];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    if(isLoggedIn)
    {
        [nokeSDK sharedInstance].delegate = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self getTableData];
        });
    }
    else
    {
        [self presentViewController:[LoginViewController sharedInstance] animated:NO completion:nil];
    }
    
    [_locksTableView reloadData];
}

-(void) getTableData
{
    if(self.hostReachability.currentReachabilityStatus == 0)
    {
        NSLog(@"OFFLINE MODE ENABLED");
        
        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
        NSString* keyName = [NSString stringWithFormat:@"nokeDevicesArray-%@", [[LocksViewController sharedInstance] getEmail]];
        NSArray* encodedNokeDevices = [def objectForKey:keyName];
        
        for(int i=0; i < [encodedNokeDevices count]; i++)
        {
            NSData* encodedNoke = [encodedNokeDevices objectAtIndex:i];
            nokeDevice* cachedNoke = (nokeDevice*) [NSKeyedUnarchiver unarchiveObjectWithData:encodedNoke];
            NSLog(@"CACHED NOKE: %@ IS OWNED: %d", cachedNoke.name, cachedNoke.isOwned);
            if(cachedNoke.isOwned)
            {
                [[nokeSDK sharedInstance] insertNokeDevice:cachedNoke];
            }
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_locksTableView reloadData];
        });
        
        
        [[nokeSDK sharedInstance] startScanForNokeDevices];
        
    }
    else
    {
        //[nokeClient getGroupsByUsers:self];
        [self getCurrentLocation];
        
    }
    
}

-(void)updateStatusText:(NSString*)status Path: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_locksTableView cellForRowAtIndexPath:indexPath];
    UILabel* statusLabel = (UILabel*)[cell viewWithTag:100];
    [statusLabel setText:status];
}

-(void)removeLockFromTable:(nokeDevice *)noke
{
    [[nokeSDK sharedInstance] startScanForNokeDevices];
}


-(void)checkLogin
{
    if(!isLoggedIn)
    {
        //[[nokeSDK sharedInstance] stopScan];
        [self presentViewController:[LoginViewController sharedInstance] animated:YES completion:nil];
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        if([connectedLocks count] < 1)
        {
            return 0;
        }
        else
        {
            BOOL allHaveLogs = true;
            
            for(int i = 0; i < [connectedLocks count]; i++)
            {
                nokeDevice* tmpNoke = [connectedLocks objectAtIndex:i];
                if(!tmpNoke.hasLogs  || tmpNoke.unlockMethod == NLUnlockMethodOneStep)
                {
                    allHaveLogs = false;
                }
            }
            
            if(allHaveLogs)
            {
                return 0;
            }
            else
            {
                return 44;
            }
        }
    }
    else
    {
        return 44;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _locksTableView.frame.size.width, 44)];
    sectionView.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    sectionView.tag=section;
    
    UILabel *viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10,_locksTableView.frame.size.width-20, 34)];
    viewLabel.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    viewLabel.textColor=[UIColor blackColor];
    viewLabel.font=[UIFont systemFontOfSize:25];
    
    if(section == 0)
    {
        viewLabel.text=@"Connected Locks";
    }
    else
    {
        viewLabel.text=@"All Locks";
    }
    
    [sectionView addSubview:viewLabel];
    return sectionView;
    
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section == 0)
    {
        return [connectedLocks count];
    }
    else
    {
        return [[[nokeSDK sharedInstance] nokeDevices] count];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //THERE ARE TWO SECTIONS CONNECTED LOCKS & ALL LOCKS
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    
    if(section == 0)
    {
        NSInteger index = [indexPath row];
        nokeDevice* noke = [connectedLocks objectAtIndex:index];
        if(noke.hasLogs && noke.unlockMethod != NLUnlockMethodOneStep)
        {
            //IF WE'RE JUST CONNECTING TO THE LOCK TO GET LOGS, WE HIDE THE LOCK
            return 0;
        }
        else
        {
            return 100;
        }
    }
    else
    {
        NSInteger index = [indexPath row];
        nokeDevice* noke = [[[nokeSDK sharedInstance] nokeDevices] objectAtIndex:index];
        
        if(noke.deviceType == NLDeviceTypeFob || !noke.isOwned)
        {
            //HIDE THE DEVICE IF IT'S A FOB
            return 0;
        }
        else
        {
            return 70;
        }
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    
    static NSString *cellIdentifier = @"resueIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] init];
    }
    
    if(section == 0)
    {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        nokeDevice* noke = [connectedLocks objectAtIndex:indexPath.row];
        
        //HIDE LOCK IF CONNECTING IN THE BACKGROUND
        if(noke.hasLogs && noke.unlockMethod != NLUnlockMethodOneStep)
        {
            cell.hidden = true;
        }
        else
        {
            cell.hidden = false;
        }
        
        [cell setBackgroundColor:[UIColor whiteColor]];
        
        UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, cell.frame.size.width - 40, 35)];
        nameLabel.text = [noke name];
        [nameLabel setFont:[UIFont systemFontOfSize:22]];
        [nameLabel setAdjustsFontSizeToFitWidth:true];
        [cell addSubview:nameLabel];
        
        UILabel* serialLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, cell.frame.size.height/2 + 10, cell.frame.size.width - 40, 35)];
        serialLabel.text = noke.serial;
        [serialLabel setFont:[UIFont systemFontOfSize:13]];
        [serialLabel setTextAlignment:NSTextAlignmentLeft];
        [cell addSubview:serialLabel];
        
        UILabel* statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, cell.frame.size.width - 40, 35)];
        statusLabel.text = @"Lock Status";
        [statusLabel setFont:[UIFont systemFontOfSize:13]];
        [cell addSubview:statusLabel];
        
        
        if(!noke.isSetup)
        {
            switch (noke.connectionStatus)
            {
                case NLConnectionStatusSetup:
                    statusLabel.text = @"Tap to Setup";
                    break;
                case NLConnectionStatusConnecting:
                    statusLabel.text = @"Connecting...";
                    break;
                default:
                    statusLabel.text = @"Tap to Setup";
                    break;
            }
        }
        else
        {
            if(noke.accessStatus == NLAccessStatusLive)
            {
                switch (noke.connectionStatus)
                {
                    case NLConnectionStatusConnecting:
                        statusLabel.text = @"Connecting...";
                        break;
                    case NLConnectionStatusCheckingPermission:
                        statusLabel.text = @"Verifying...";
                        break;
                    case NLConnectionStatusUnlocked:
                        statusLabel.text = @"Unlocked";
                        break;
                    default:
                        statusLabel.text = @"Tap to Unlock";
                        break;
                }
            }
            else
            {
                switch (noke.connectionStatus)
                {
                    case NLConnectionStatusConnecting:
                        statusLabel.text = @"Connecting...";
                        break;
                    case NLConnectionStatusSetup:
                        statusLabel.text = @"Tap to Setup";
                        break;
                    default:
                        statusLabel.text = @"No Access";
                        break;
                }
            }
        }
    }
    else
    {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        nokeDevice* noke;
        
        if([[[nokeSDK sharedInstance] nokeDevices] count] > 0)
        {
            noke = [[[nokeSDK sharedInstance] nokeDevices] objectAtIndex:indexPath.row];
        }
        [cell setBackgroundColor:[UIColor whiteColor]];
        
        UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, cell.frame.size.width - 40, 35)];
        nameLabel.text = [noke name];
        [nameLabel setFont:[UIFont systemFontOfSize:20]];
        [cell addSubview:nameLabel];
        
        UILabel* serialLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, cell.frame.size.height/2 + 10, cell.frame.size.width, 35)];
        serialLabel.text = noke.serial;
        [serialLabel setFont:[UIFont systemFontOfSize:11]];
        [serialLabel setTextAlignment:NSTextAlignmentLeft];
        [cell addSubview:serialLabel];
        
        
        if(noke.deviceType == NLDeviceTypeFob)
        {
            cell.hidden = YES;
        }
        
        if(!noke.isOwned)
        {
            cell.hidden = YES;
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    
    if(section == 0)
    {
        //CONNECT TO DEVICE TO UNLOCK
        nokeDevice* noke = [connectedLocks objectAtIndex:indexPath.row];
        [[nokeSDK sharedInstance] connectToNokeDevice:noke];
        noke.connectionStatus = NLConnectionStatusConnecting;
        NSIndexPath* index = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
        [_locksTableView  reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if(section == 1)
    {
        //SHOW LOCK DETAILS
        nokeDevice* noke = [[[nokeSDK sharedInstance] nokeDevices] objectAtIndex:indexPath.row];
        LockDetailsViewController* lvc = [[LockDetailsViewController alloc] init];
        lvc.noke = noke;
        
        [self.navigationController pushViewController:lvc animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    
    if(section == 1)
    {
        return true;
    }
    else
    {
        return true;
    }
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
    dispatch_async(dispatch_get_main_queue(), ^{
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager requestWhenInUseAuthorization];
    //[locationManager requestAlwaysAuthorization];
    [locationManager startMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
     });
}

#pragma mark - nokeSDKDelegate
-(void)isBluetoothEnabled:(bool)enabled
{
    //CHECKS IF BLUETOOTH IS OFF OR ON
    NSLog(@"BLUETOOTH IS ON: %d", enabled);
}

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

-(void)didReceiveNokeResponse:(NSDictionary *)data Noke:(nokeDevice *)noke
{
    if(data != nil)
    {
        NSLog(@"RESPONSE: %@", data);
        NSString*result = [data objectForKey:@"result"];
    
        if([result isEqualToString:@"failure"])
        {
            NSString* message = [data objectForKey:@"message"];
            int errorCode = [[data valueForKey:@"errorCode"] intValue];
        
            if(errorCode == ERROR_TOKEN)
            {
                //HANDLE AN EXPIRED TOKEN.  EITHER REQUIRE THE USER TO RE-LOGIN OR AUTOMATICALLY RE-LOGIN FOR THEM
            }
            else if(errorCode == ERROR_LOCK_NOT_FOUND || [message isEqualToString:@"Lock not setup"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Setup Lock", nil) message:NSLocalizedString(@"Please name your lock", nil) preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
                     {
                         NSString* identifier = [[noke.peripheral.name substringFromIndex:15] substringToIndex:4];
                         textField.placeholder = NSLocalizedString(@"Lock Name", nil);
                         //textField.text = @"";
                     }];
                    
                    UIAlertAction *okAction = [UIAlertAction
                                               actionWithTitle:NSLocalizedString(@"OK", nil)
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action)
                                               {
                                                   UITextField *name = alertController.textFields.firstObject;
                                                   
                                                   NSIndexPath* path = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
                                                   [self updateStatusText:NSLocalizedString(@"Setup", nil) Path:path];
                                                   noke.name = name.text;
                                                   noke.connectionStatus = NLConnectionStatusSetup;
                                                   [_locksTableView reloadData];
                                                   
                                                   [nokeClient setupLock:noke Name:name.text Delegate:self];
                                                   
                                               }];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
                                                   {
                                                       
                                                       [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
                                                       noke.connectionStatus = NLConnectionStatusDisconnected;
                                                       
                                                   }];
                    
                    [alertController addAction:okAction];
                    [alertController addAction:cancelAction];
                    
                    [self presentViewController:alertController animated:TRUE completion:nil];

            
                });
            }
            else if(errorCode == ERROR_NO_ACTIVE_SCHEDULE || errorCode == ERROR_PERMISSION_DENIED)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You do not have access to this lock.  Please contact your administrator", nil) preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                        [failedController addAction:okAction];
                        
                        [self presentViewController:failedController animated:TRUE completion:nil];
                    });
                    
                [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
                noke.connectionStatus = NLConnectionStatusDisconnected;
                noke.unlockMethod = NLUnlockMethodTwoStep;
                [_locksTableView reloadData];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Something went wrong.  Please contact your administrator", nil) preferredStyle:UIAlertControllerStyleAlert];
                        
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                        [failedController addAction:okAction];
                        
                    [self presentViewController:failedController animated:TRUE completion:nil];
                    
                    [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
                    noke.connectionStatus = NLConnectionStatusDisconnected;
                    noke.unlockMethod = NLUnlockMethodTwoStep;
                    [_locksTableView reloadData];
                });
            }
        }
        else
        {
            NSDictionary* objData = [data objectForKey:@"data"];
            NSArray* commands = [objData objectForKey:@"commands"];
            if([noke dataPackets] != nil)
            {
                [[noke dataPackets] removeAllObjects];
            }
            
            for(int i = 0; i < [commands count]; i++)
            {
                NSString* hexString = commands[i];
                
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
                [noke addDataToArray:cmdData];
            }
            
            if([[noke dataPackets] count] > 0)
            {
                if([[noke dataPackets] count] > 1)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSIndexPath* path = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
                        [self updateStatusText:NSLocalizedString(@"Syncing", nil) Path:path];
                        
                    });
                }
                
                [noke writeDataArray];
                [self performSelector:@selector(checkDataQueue:) withObject:noke afterDelay:3.0];
                [self performSelector:@selector(uploadDataTimeout:) withObject:noke afterDelay:10.0];
            }
        }
    }
    else
    {
        //IF WE DON'T RECEIVE A RESPONSE FROM THE SERVER, UNLOCK OFFLINE (IF THEY HAVE OFFLINE PERMISSION)
        if([noke.preSessionKey length] > 0 && [noke.offlineUnlockCmd length] > 0)
        {
            [noke offlineUnlock];
        }
        else
        {
            //IF THEY DON'T HAVE OFFLINE ACCESS, DISPLAY A MESSAGE
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You do not have offline access to this lock. Please check your internet connection.", nil) preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                [failedController addAction:okAction];
                
                [self presentViewController:failedController animated:TRUE completion:nil];
            });
        }
    }
}
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //[_locksTableView reloadData];
                
                NSIndexPath* index = [NSIndexPath indexPathForRow:[connectedLocks indexOfObject:noke] inSection:0];
                [_locksTableView  reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationNone];
                
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
