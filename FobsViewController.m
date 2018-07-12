//
//  FobsViewController.m
//  ios-api-library
//
//  Created by Spencer Apsley on 10/28/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import "FobsViewController.h"
#include "nokeSDK.h"
#import "nokeClient.h"
#import "LoginViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface FobsViewController ()

@end

@implementation FobsViewController
{
    CLLocationManager *locationManager;
    NSString* longitude;
    NSString* latitude;
    NSTimer* disconnectTimer;
    nokeDevice* legacyNoke;
    Boolean bSetup;
}

static FobsViewController *fobsViewController;

+ (FobsViewController*) sharedInstance
{
    if(fobsViewController == nil)
    {
        fobsViewController = [[FobsViewController alloc] init];
        
    }
    return fobsViewController;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [_fobsTableView addSubview:_refreshControl];
    
    
    self.title = NSLocalizedString(@"Fobs", nil);
    bSetup = false;

    [self.view setBackgroundColor:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]];
    
    _fobsTableView.delegate = self;
    _fobsTableView.dataSource = self;
    _fobsTableView.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    _fobsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    connectedFobs = [[NSMutableArray alloc] init];
    
    //TIMERS
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(refreshFobList) userInfo:nil repeats:YES];
    
    [self getTableData];
}


-(void)viewWillAppear:(BOOL)animated
{
    [_fobsTableView reloadData];
}


- (void) viewDidAppear:(BOOL)animated
{
    [nokeSDK sharedInstance].delegate = self;
    [[nokeSDK sharedInstance] startScanForNokeDevices];
}

-(void) getTableData
{
    [nokeClient getFobBySelf:self];
}

-(void)handleRefresh
{
    [[nokeSDK sharedInstance] stopScan];
    [connectedFobs removeAllObjects];
    [nokeClient getFobBySelf:self];
}

-(void)updateStatusText:(NSString*)status Path: (NSIndexPath *)indexPath
{
    UITableViewCell *cell = [_fobsTableView cellForRowAtIndexPath:indexPath];
    UILabel* statusLabel = (UILabel*)[cell viewWithTag:100];
    [statusLabel setText:status];
}

-(void)removeLockFromTable:(nokeDevice *)noke
{
    [[nokeSDK sharedInstance] startScanForNokeDevices];
}


-(void)disconnectNoke:(nokeDevice *)noke
{
    [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
}

-(void)setIsLoggedIn:(BOOL)loggedin
{
    isLoggedIn = loggedin;
}

-(void)checkLogin
{
    if(!isLoggedIn)
    {
        [self presentViewController:[LoginViewController sharedInstance] animated:YES completion:nil];
    }
}

-(void)setUserData:(NSString *)name Email:(NSString *)email Flag:(int)flag
{
    username = name;
    useremail = email;
    installerFlag = flag;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        if([connectedFobs count] < 1)
        {
            return 0;
        }
        else
        {
            return 44;
        }
    }
    else
    {
        return 44;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _fobsTableView.frame.size.width, 44)];
    sectionView.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    sectionView.tag=section;
    
    UILabel *viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10,_fobsTableView.frame.size.width-20, 34)];
    viewLabel.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    viewLabel.textColor=[UIColor blackColor];
    viewLabel.font=[UIFont systemFontOfSize:25];
    
    if(section == 0)
    {
        viewLabel.text=@"Connected Fobs";
    }
    else
    {
        viewLabel.text=@"All Fobs";
    }
    
    [sectionView addSubview:viewLabel];
    return sectionView;
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

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(section == 0)
    {
        return [connectedFobs count];
    }
    else
    {
        return [[[nokeSDK sharedInstance] nokeDevices] count];
    }
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = [indexPath section];
    
    if(section == 0)
    {
        return 103;
    }
    else
    {
        NSInteger index = [indexPath row];
        nokeDevice* noke = [[[nokeSDK sharedInstance] nokeDevices] objectAtIndex:index];
        
        if(noke.deviceType == NLDeviceTypeFob)
        {
            return 70;
        }
        else
        {
            return 0;
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
        
        nokeDevice* noke = [connectedFobs objectAtIndex:indexPath.row];
        [cell setBackgroundColor:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]];
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
                        statusLabel.text = @"Tap to Sync";
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
        
        
        if(noke.deviceType != NLDeviceTypeFob)
        {
            cell.hidden = YES;
        }
        else
        {
            cell.hidden = NO;
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
        nokeDevice* noke = [connectedFobs objectAtIndex:indexPath.row];
        NSLog(@"VERSION #: %d", noke.version);        
        if([noke.versionString isEqualToString:@"2F-2.8"] || [noke.versionString isEqualToString:@"2F-2.7"])
        {
            [[nokeSDK sharedInstance] connectToNokeDevice:noke];
            noke.connectionStatus = NLConnectionStatusConnecting;
            [_fobsTableView reloadData];
        }
    }
    else if(section == 1)
    {
        //USED TO DRILL INTO FOBS PAGE
    }
}

#pragma mark nokeSDKDelegate
-(void)isBluetoothEnabled:(bool)enabled
{
    if(enabled)
    {
        _searchingLabel.text = NSLocalizedString(@"Searching for Locks...", nil);
        [[nokeSDK sharedInstance] startScanForNokeDevices];
    }
    else
    {
        _searchingLabel.text = NSLocalizedString(@"Please enable bluetooth to search for locks", nil);
    }
}

-(void)didDiscoverNokeDevice:(nokeDevice *)noke RSSI:(NSNumber *)RSSI
{
    //CHECKS IF FOB IS ALREADY IN LIST AND UPDATES INFORMATION ACCORDINGLY
    if(noke.deviceType == NLDeviceTypeFob)
    {
        for(int i = 0; i < [connectedFobs count]; i++)
        {
            nokeDevice* tmpNoke = [connectedFobs objectAtIndex:i];
            
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
        [connectedFobs insertObject:noke atIndex:0];
        
        NSIndexPath* index = [NSIndexPath indexPathForRow:[connectedFobs indexOfObject:noke] inSection:0];
        [_fobsTableView reloadData];
        [_fobsTableView  reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationFade];
    }

}


-(void)didConnect:(nokeDevice *)noke
{
    dispatch_async(dispatch_get_main_queue(), ^{
        noke.isConnected = true;
        noke.connectionStatus = NLConnectionStatusCheckingPermission;
        NSIndexPath* path = [NSIndexPath indexPathForRow:[connectedFobs indexOfObject:noke] inSection:0];
        [self updateStatusText:@"Syncing" Path:path];
    });
    

    if(!noke.hasLogs)
    {
      if(noke.deviceType == NLDeviceTypeFob)
      {
         [nokeClient sync:noke Delegate:self];
      }
      else
      {
         [nokeClient unlock:noke Delegate:self];
      }
    }
    else
    {
        noke.hasLogs = false;
    }
    
}

-(void)didDisconnect:(nokeDevice *)noke
{
    [[nokeSDK sharedInstance] stopScan];
    noke.isConnected = false;
    
    for(int i=0; i<[connectedFobs count]; i++)
    {
        nokeDevice* tmpNoke = [connectedFobs objectAtIndex:i];
        
        if([tmpNoke.mac isEqualToString:noke.mac])
        {
            [connectedFobs removeObjectAtIndex:i];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_fobsTableView reloadData];
    });
    
    [self performSelector:@selector(removeLockFromTable:) withObject:noke afterDelay:1.0];
    
    [nokeClient uploadData:self];
    [[nokeSDK sharedInstance] retrieveKnownPeripherals];
}

-(void)didReceiveData:(NSData *)data Noke:(nokeDevice *)noke
{
   //CALLED WHEN THE LOCK SENDS BACK DATA
   unsigned char* dataArray = (unsigned char*) [data bytes];
        
   [self stopDisconnectTimer: noke];
        
        if(dataArray[0] == SERVER_Dest)
        {
            NSMutableString *hex = [NSMutableString string];
            for (int i=0; i<20; i++)
            {
                [hex appendFormat:@"%02x", dataArray[i]];
            }
            NSString *immutableHex = [NSString stringWithString:hex];
            
            NSLog(@"Received SERVER packet");
            
            [[nokeSDK sharedInstance] addDataPacketToQueue:immutableHex Session:[noke getSessionAsString] Mac:[noke mac] Longitude:longitude Latitude:latitude];
            
            [self startDisconnectTimer:noke];
        }
        else if(dataArray[0] == APP_Dest)
        {
            NSLog(@"Received APP packet");
            
            if([[noke dataPackets] count] == 0)
            {
                noke.connectionStatus = NLConnectionStatusUnlocked;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    
                    [noke addSessionToPackets:longitude Latitude:latitude];
                    [nokeClient uploadData:self]; //USED FOR INTERNAL TESTING
                    [_fobsTableView reloadData];
                    
                    if(noke.deviceType == NLDeviceTypeFob)
                    {
                        if(!bSetup)
                        {
                            UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Sync Complete", nil) message: NSLocalizedString(@"Fob has been synced successfully", nil) preferredStyle:UIAlertControllerStyleAlert];
                            
                            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                            [failedController addAction:okAction];
                            
                            [self presentViewController:failedController animated:TRUE completion:nil];
                        }
                        else
                        {
                            bSetup = false;
                        }
                    }
                    
                });
                
            }
        }
}

#pragma mark nokeClientDelegate
-(void)didReceiveResponse:(NSDictionary *)data
{
    /**
     NSLog(@"LOGGED IN");
     isLoggedIn = YES;
     [self dismissViewControllerAnimated:YES completion:nil];
     [[nokeSDK sharedInstance] startScanForNokeDevices];
     **/
    
}

-(void) didReceiveLoginUnlockResponse:(NSDictionary *)data Noke:(nokeDevice *)noke
{
    NSString* result = [data objectForKey:@"result"];
    if([result isEqualToString:@"success"])
    {
        NSString* token = [data objectForKey:@"token"];
        [nokeClient setToken:token];
        [nokeClient sync:noke Delegate:self];
    }
    else
    {
        isLoggedIn = false;
        [self checkLogin];
    }
}


-(void)didReceiveNokeResponse:(NSDictionary *)data Noke:(nokeDevice *)noke
{
    if(data != nil)
    {
        NSLog(@"RESPONSE: %@", data);
        
        NSString*result = [data objectForKey:@"result"];
        
        if([result isEqualToString:@"failure"])
        {
            int errorCode = [[data valueForKey:@"errorCode"] intValue];
            if(errorCode == ERROR_TOKEN)
            {
                //HANDLE SYNC IF TOKEN HAS EXPIRED. HAVE THE USER RELOGIN OR RELOGIN AUTOMATICALLY
            }
            else if(errorCode == ERROR_FOB_NOT_FOUND)
            {
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Setup Fob", nil) message:NSLocalizedString(@"Please name your fob", nil) preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
                     {
                         textField.placeholder = NSLocalizedString(@"Fob Name", @"Fob Name");
                         textField.text = @"";
                     }];
                    
                    UIAlertAction *okAction = [UIAlertAction
                                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action)
                                               {
                                                   UITextField *name = alertController.textFields.firstObject;
                                                   
                                                   NSIndexPath* path = [NSIndexPath indexPathForRow:[connectedFobs indexOfObject:noke] inSection:0];
                                                   [self updateStatusText:@"Setup" Path:path];
                                                   noke.name = name.text;
                                                   noke.connectionStatus = NLConnectionStatusSetup;
                                                   [_fobsTableView reloadData];
                                    
                                                   
                                                   bSetup = true;
                                                   [nokeClient setupLock:noke Name:name.text Delegate:self];
                                                   
                                               }];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",) style:UIAlertActionStyleCancel handler:nil];
                    
                    [alertController addAction:okAction];
                    [alertController addAction:cancelAction];
                    
                    [self presentViewController:alertController animated:TRUE completion:nil];
                    
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You do not have access to this fob.  Please contact your administrator", nil) preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                        [failedController addAction:okAction];
                        
                        [self presentViewController:failedController animated:TRUE completion:nil];
                        
                        [[nokeSDK sharedInstance] disconnectNokeDevice:noke];
                        noke.connectionStatus = NLConnectionStatusDisconnected;
                        
                    });
                    
                });
            }
        }
        
        else
        {
            
            NSArray* commands = [data objectForKey:@"commands"];
            
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
                [noke writeDataArray];
                [self performSelector:@selector(checkDataQueue:) withObject:noke afterDelay:3.0];
                [self performSelector:@selector(uploadDataTimeout:) withObject:noke afterDelay:10.0];
            }
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Unable to reach server. Please check your internet connection.", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
            [failedController addAction:okAction];
            
            [self presentViewController:failedController animated:TRUE completion:nil];
        });
        
    }
}


#pragma mark Timer Methods
-(void)refreshFobList
{
    for(int i = 0; i < [connectedFobs count]; i++)
    {
        nokeDevice* tmpNoke = [connectedFobs objectAtIndex:i];
        long currentTime = (long)(NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
        
        long timediff = currentTime - tmpNoke.lastSeen;
        
        if(timediff >= 5 && !tmpNoke.isConnected)
        {
            [connectedFobs removeObjectAtIndex:i];
            [_fobsTableView reloadData];
        }
    }
}

-(void)startDisconnectTimer:(nokeDevice *)noke
{
    [self performSelector:@selector(disconnectNoke:) withObject:noke afterDelay:3.0];
}

-(void)stopDisconnectTimer:(nokeDevice *)noke
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnectNoke:) object:noke];
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
    if([[noke uploadPacketsWithSession] count] > 0)
    {
        //[nokeClient uploadData:noke Longitude:longitude Latitude:latitude Delegate:self];
    }
}


@end
