//
//  nokeClient.m
//  ios-sdk
//
//  Created by Spencer Apsley on 3/15/16.
//  Copyright © 2016 Noke LLC. All rights reserved.
//

#import "nokeClient.h"
#import "nokeDevice.h"
#import "activityItem.h"
#import "ActivityViewController.h"
#import "nokeSDK.h"
#import "NokeViewController.h"
#import "FobsViewController.h"
#include <sys/sysctl.h>
#include <sys/utsname.h>


static NSString* mToken = @"eyJhbGciOiJOT0tFX01PQklMRV9TQU5EQk9YIiwidHlwIjoiSldUIn0.eyJhbGciOiJOT0tFX01PQklMRV9TQU5EQk9YIiwiY29tcGFueV91dWlkIjoiYTQxYjc3YzctZGZlZi00YmFkLWExMDYtZjlmYTNhNWZkN2M0IiwiaXNzIjoibm9rZS5jb20ifQ.73a55fc5afbb61f9ea8b213c5759d9cfd9f5eed6";
static NSString* mKey;

static NSString* mUsername;
static NSString* mPassword;

static NSString* serverUrl = MAIN_URL;

typedef enum
{
    REQUEST_LOGIN = 0,
    REQUEST_SETUP,
    REQUEST_UPLOAD,
    REQUEST_UNLOCK,
    REQUEST_GETGROUPS,
    REQUEST_REFRESH,
    REQUEST_ACTIVITY,
    REQUEST_SYNC,
    REQUEST_GET_FOB_SELF,
    REQUEST_GET_LOCK_DETAILS,
    REQUEST_RESET_PASSWORD,
    REQUEST_GET_LOCK_NAME
} NCServerCommand;

@implementation nokeClient

//TODO This function handles send and receiving the server data (command string)
+ (void) request:(int)command URL:(NSString*) strUrl Data:(NSMutableData *)JsonData Noke:(nokeDevice*)noke Delegate:(id) delegate
{
    NSLog(@"URL: %@", strUrl);
    NSString *strData = [[NSString alloc]initWithData:JsonData encoding:NSUTF8StringEncoding];
    NSLog(@"JSON DATA: %@", strData);
    
    //GETS APP VERSION FOR HEADER
    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    //GETS BUILD NUMBER FOR HEADER
    NSString* build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:strUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    [request setHTTPMethod:@"POST"];
    if(mToken != nil)
    {
        [request addValue:[NSString stringWithFormat:@"Bearer %@", mToken] forHTTPHeaderField:@"Authorization"];
        
        //CUSTOM HEADER THAT IS USED TO SEND DATA ABOUT DEVICE, PLATFORM, APP VERSION, AND OS
        [request addValue:[NSString stringWithFormat:@"{\"platform\": \"iOS\", \"platformVersion\": \"%@\", \"device\": \"%@\", \"appVersion\": \"%@\", \"build\": %@}", [[UIDevice currentDevice] systemVersion], [self platformString], version, build] forHTTPHeaderField:@"deviceDetails"];
    }

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:JsonData completionHandler:^(NSData *data,NSURLResponse *response,NSError *error){
        //HANDLE RESPONSE HERE
        
    if(data != nil)
    {
        ///NSError *jsonError;
        ///NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        //NSLog(@"RESPONSE: %@", jsonDict);
        switch (command)
        {
            case REQUEST_LOGIN:
                NSString *msg = @"Requesting Login";
                [[NokeViewController sharedInstance] logCallback:msg];
                break;
            case REQUEST_SETUP:
                NSString *msg = @"Requesting Login";
                [[NokeViewController sharedInstance] logCallback:msg];
                [delegate didReceiveNokeResponse:data Noke:noke];
                break;
            case REQUEST_UPLOAD:
                NSString *msg = @"Requesting upload";
                [[NokeViewController sharedInstance] logCallback:msg];
                [self uploadDataCallback:jsonDict];
                break;
            case REQUEST_UNLOCK:
                NSString *msg = @"Requesting Unlock";
                [[NokeViewController sharedInstance] logCallback:msg];
                NSString *NSsession = [noke getSessionAsString];
                NSString *Data = [[NokeViewController sharedInstance] requestCommandStr:NSsession Mac:noke.mac];
                [delegate didReceiveNokeResponse:Data Noke:noke];
                break;
            case REQUEST_SYNC:
                NSString *msg = @"Requesting Sync";
                [[NokeViewController sharedInstance] logCallback:msg];
                NSString *NSsession = [noke getSessionAsString];
                NSString *Data = [[NokeViewController sharedInstance] requestCommandStr:NSsession Mac:noke.mac];
                [delegate didReceiveNokeResponse:Data Noke:noke];
                break;
            case REQUEST_GETGROUPS:
                [self getGroupsByUsersCallback:jsonDict];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[LocksViewController sharedInstance] refreshControl] endRefreshing];
                    [[LocksViewController sharedInstance].locksTableView reloadData];
                });
                break;
            case REQUEST_REFRESH:
                [self refreshTokenCallback:jsonDict];
                break;
            case REQUEST_ACTIVITY:
                [self getActivityCallback:jsonDict];
                break;
            case REQUEST_GET_FOB_SELF:
                [self getFobCallback:jsonDict];
                break;
            case REQUEST_GET_LOCK_DETAILS:
                [delegate didReceiveResponse:jsonDict];
                break;
            case REQUEST_RESET_PASSWORD:
                [delegate resetPasswordResponse:jsonDict];
                break;
            case REQUEST_GET_LOCK_NAME:
                [delegate didReceiveFindLockResponse:jsonDict Noke:noke];
                break;
            default:
                break;
        }
    }
    else
    {
        switch (command)
        {
            case REQUEST_LOGIN:
                [delegate didReceiveResponse:nil];
                break;
            case REQUEST_SETUP:
                break;
            case REQUEST_UPLOAD:
                break;
            case REQUEST_UNLOCK:
                [delegate didReceiveNokeResponse:nil Noke:noke];
                break;
            case REQUEST_GETGROUPS:
                break;
            case REQUEST_REFRESH:
                break;
        }
    }
    //}];
    
    [uploadTask resume];
}

+ (void) request:(int)command URL:(NSString*) strUrl Data:(NSMutableData *)JsonData Delegate:(id)delegate
{
    [self request:command URL:strUrl Data:JsonData Noke:nil Delegate:delegate];
}

+(void)setToken:(NSString*)token
{
    mToken = token;
}

+ (void) login:(NSString*) userName Password:(NSString*)password CompanyDomain:(NSString*)companyDomain Delegate:(id) delegate
{
    NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl, @"company/app/login/"];
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString* keyKey = [NSString stringWithFormat:@"%@%@key",companyDomain,userName];
    NSString* key = [def stringForKey:keyKey];
    
    //TIME IS USED TO CHECK THAT USER HAS NOT MODIFIED THE SYSTEM TIME ON THEIR DEVICE
    NSDate *currentDateTime = [NSDate date];
    long timestamp = [currentDateTime timeIntervalSince1970];
    NSString* timeString = [NSString stringWithFormat:@"%lu", timestamp];
    
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                              companyDomain, @"companyDomain",
                              userName, @"userName",
                              password, @"password",
                              key, @"key",
                              timeString, @"currentTime",
                              nil];
    
    if ([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];        
        [nokeClient request:REQUEST_LOGIN URL:url Data:tempJsonData Delegate:delegate];
    }
    
}

+ (void) loginCallback:(NSDictionary*)jsonDict
{
    NSString* result = [jsonDict objectForKey:@"result"];
    if([result isEqualToString:@"success"])
    {
        NSString* token = [jsonDict objectForKey:@"token"];
        mToken = token;
        
        NSString* key = [jsonDict objectForKey:@"key"];
        if(key != nil)
        {
            NSDictionary* data = [jsonDict objectForKey:@"data"];
            NSString* username = [data objectForKey:@"username"];
            NSString* companyname = [data objectForKey:@"companyName"];
            
            
            NSString* keyKey = [NSString stringWithFormat:@"%@%@key",companyname,username];
            
            //NSLog(@"KEYKEY IS: %@ KEY IS: %@", keyKey, key);
            
            mKey = key;
            NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
            [def setObject:key forKey:keyKey];
        }
        
        [nokeClient getGroupsByUsers:nil];
        
        if( [[[nokeSDK sharedInstance] globalUploadDataQueue] count] > 0)
        {
            [nokeClient uploadData:self];
        }
    }
}

+ (void) setupLock:(nokeDevice*)noke Name:(NSString*)name Delegate:(id) delegate
{
    NSString* url;
    
    if(noke.deviceType == NLDeviceTypeFob)
    {
        url = [NSString stringWithFormat:@"%@%@",serverUrl,@"fob/setup/"];
    }
    else
    {
        url = [NSString stringWithFormat:@"%@%@", serverUrl,@"lock/setup/"];
    }
    
    
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [noke getSessionAsString], @"session",
                              [noke mac],@"mac",
                              name,@"name",
                              nil];
    
    if ([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_SETUP URL:url Data:tempJsonData Noke:noke Delegate:delegate];
    }
}

+ (void) uploadData:(id) delegate
{
    
    if( [[[nokeSDK sharedInstance] globalUploadDataQueue] count] > 0)
    {
        NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl,@"lock/upload/"];
        
        NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [[nokeSDK sharedInstance] globalUploadDataQueue], @"data",
                                  nil];
        
        if ([NSJSONSerialization isValidJSONObject:jsonBody])
        {
            
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
            NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
            [nokeClient request:REQUEST_UPLOAD URL:url Data:tempJsonData Delegate:delegate];
        }
    }
}

+ (void) uploadDataCallback:(NSDictionary*)data
{
    if(data != nil)
    {
        //NSLog(@"UPLOAD DATA CALLBACK: %@", data);
        int errorCode = [[data objectForKey:@"errorCode"] intValue];
        switch (errorCode) {
            case ERROR_SUCCESS:
            {
                [[[nokeSDK sharedInstance] globalUploadDataQueue] removeAllObjects];
                break;
            }
            case ERROR_TOKEN:
            {
                //HANDLE EXPIRED AUTHENTICATION HERE
            }
            default:
                break;
        }
    }
    
    [[nokeSDK sharedInstance] cacheUploadQueue];
}

+ (void) unlock:(nokeDevice*)noke Delegate:(id) delegate
{
    NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl,@"lock/unlock/"];
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [noke getSessionAsString], @"session",
                              [noke mac], @"mac",
                              
                              nil];
    if ([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_UNLOCK URL:url Data:tempJsonData Noke:noke Delegate:delegate];
    }
    
}

+ (void) getGroupsByUsers:(id) delegate
{
    NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl,@"user/locks/"];
    //NSString* url = [NSString stringWithFormat:@"%@%@", serverUrl,@"lock/get/list/"];
    NSDictionary* jsonBody = [[NSDictionary alloc] init];
    
    if ([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_GETGROUPS URL:url Data:tempJsonData Delegate:delegate];
    }
}

+(void) getGroupsByUsersCallback:(NSDictionary*)data
{
    if(data != nil)
    {
        //NSLog(@"JSON LOCK DATA: %@", data);
        int errorCode = [[data objectForKey:@"errorCode"] intValue];
        
        switch (errorCode) {
            case ERROR_SUCCESS:
            {
                Boolean tablechanged = false;
                
                [[nokeSDK sharedInstance] cacheUploadQueue];
                //NSLog(@"GET LOCKS JSON: %@", data);
                //[[nokeSDK sharedInstance] removeAllLocks];
                //NSArray* savedNokeDevices = [[nokeSDK sharedInstance] getSavedNokeDevices];
                
                
                NSDictionary* jsonDict = [data objectForKey:@"data"];
                NSArray* locks = [jsonDict objectForKey:@"locks"];
                
                for (int x =0; x < [locks count]; x++)
                {
                    NSDictionary* tmpLock = [locks objectAtIndex:x];
                    nokeDevice* tmpNoke = [[nokeDevice alloc] initWithName:[tmpLock objectForKey:@"name"] Mac:[tmpLock objectForKey:@"macAddress"]];
                    tmpNoke.isSetup = true;
                    tmpNoke.isOwned = true;
                    tmpNoke.isConnected = false;
                    
                    NSString* keyType = [tmpLock objectForKey:@"accessType"];
                    
                    if([keyType isEqualToString:@"offline"])
                    {
                        tmpNoke.preSessionKey = [tmpLock objectForKey:@"key"];
                        tmpNoke.offlineUnlockCmd = [tmpLock objectForKey:@"command"];
                    }
                    else
                    {
                        tmpNoke.preSessionKey = @"";
                        tmpNoke.offlineUnlockCmd = @"";
                    }
                    
                    tmpNoke.serial = [tmpLock objectForKey:@"serial"];
                    tmpNoke.deviceType = NLDeviceTypePadlock;
                    tmpNoke.versionString = @"3P-2.4";
                    
                    int syncFlag = [[tmpLock objectForKey:@"sync"]intValue];
                    tmpNoke.sync = false;
                    if(syncFlag == 1)
                    {
                        tmpNoke.sync = true;
                    }
                    
                    
                    if([[nokeSDK sharedInstance] nokeWithMac:tmpNoke.mac] == nil)
                    {
                        tablechanged = true;
                        [[nokeSDK sharedInstance] insertNokeDevice:tmpNoke];
                    }
                    else
                    {
                        nokeDevice* oldnoke = [[nokeSDK sharedInstance] nokeWithMac:tmpNoke.mac];
                        oldnoke.preSessionKey = tmpNoke.preSessionKey;
                        oldnoke.offlineUnlockCmd = tmpNoke.offlineUnlockCmd;
                        oldnoke.name = tmpNoke.name;
                        oldnoke.unlockMethod = tmpNoke.unlockMethod;
                    }
                }
                
                //DELETE LOCKS
                NSMutableArray* deleteLocks = [[NSMutableArray alloc] init];
                for(int m=0; m < [[[nokeSDK sharedInstance] nokeDevices] count]; m++)
                {
                    Boolean bHasLock = false;
                    
                    nokeDevice* checkNoke = [[[nokeSDK sharedInstance] nokeDevices] objectAtIndex:m];
                    NSString* checkMac = checkNoke.mac;
                    
                    for(int n = 0; n < locks.count; n++){
                        NSDictionary* checkLock = [locks objectAtIndex:n];
                        NSString* mac = [checkLock objectForKey:@"macAddress"];
                        if ([mac isEqualToString:checkMac]) {
                            bHasLock = true;
                        }
                    }
                    
                    if(!bHasLock){
                        [deleteLocks addObject:checkNoke];
                    }
                }
                
                
                for(int o=0; o < [deleteLocks count]; o++){
                    tablechanged = true;
                    [[nokeSDK sharedInstance] removeLockFromArray:[deleteLocks objectAtIndex:o]];
                }
                //END OF DELETE LOCKS
                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if(tablechanged)
//                    {
//                        [[NokeViewController sharedInstance].locksTableView reloadData];
//                    }
//                });
                
                [[nokeSDK sharedInstance] startScanForNokeDevices];
                break;
            }
            case ERROR_TOKEN:
            {
                //HANDLE AUTHENTICATION
            }
            default:
                break;
        }
    }

}

+ (void) refreshToken
{
    NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl,@"company/refresh/"];
    
    NSDate *currentDateTime = [NSDate date];
    long timestamp = [currentDateTime timeIntervalSince1970];
    NSString* timeString = [NSString stringWithFormat:@"%lu", timestamp];
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:timeString,@"currentTime", nil];
    
    if ([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_REFRESH URL:url Data:tempJsonData Delegate:nil];
    }
}

+(void) refreshTokenCallback:(NSDictionary*)jsonDict
{
    NSString* token = [jsonDict objectForKey:@"token"];
    mToken = token;
}


+ (void) getActivity
{
    NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl,@"activity/"];
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [NSArray arrayWithObjects:@"unlocked_lock",@"locked_lock", nil], @"actions",
                              nil];
    
    if([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_ACTIVITY URL:url Data:tempJsonData Delegate:nil];
    }
}

+ (void) getActivityCallback:(NSDictionary*)jsonDict
{
    //NSLog(@"GET ACTIVITY: %@", jsonDict);
    NSDictionary* data = [jsonDict objectForKey:@"data"];
    NSArray* activity = [data objectForKey:@"activity"];
    //NSString* countString = [jsonDict objectForKey:@"count"];
    //int activityCount = [countString intValue];
    
    [[[ActivityViewController sharedInstance] activityList] removeAllObjects];
    
    if(activity != nil)
    {
        for (int i = 0; i < [activity count]; i++) {
            NSDictionary* tmpActivity = [activity objectAtIndex:i];
            
            NSString* strId = [tmpActivity objectForKey:@"id"];
            int groupid = [strId intValue];
            
            activityItem* newActivity = [[activityItem alloc] initWithId:groupid];
            
            newActivity.eventKey = [tmpActivity objectForKey:@"eventKey"];
            newActivity.activitytype = [tmpActivity objectForKey:@"action"];
            newActivity.fullname = [tmpActivity objectForKey:@"byWhoName"];
            
            newActivity.timestamp = [tmpActivity objectForKey:@"rangeDateStart"];
            NSDictionary* lock = [tmpActivity objectForKey:@"objectUpdated"];
            newActivity.lockname = [lock objectForKey:@"name"];
            
            NSError* jsonError;
            NSData* actionDetailsData = [[tmpActivity objectForKey:@"actionDetails"] dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *actionDetails = [NSJSONSerialization JSONObjectWithData:actionDetailsData options:NSJSONReadingMutableContainers error:&jsonError];
            
            NSDictionary *details = [actionDetails objectForKey:@"details"];
            newActivity.latitude = [details objectForKey:@"latitude"];
            newActivity.longitude = [details objectForKey:@"longitude"];
            
            //NSLog(@"EVENT ID: %@", [tmpActivity objectForKey:@"eventKey"]);
            BOOL eventExists = false;
            
            for (int j = 0; j < [[[ActivityViewController sharedInstance] activityList] count]; j++)
            {
                NSString* eventString = [[[[ActivityViewController sharedInstance] activityList] objectAtIndex:j] eventKey];
                if([newActivity.eventKey isEqualToString: eventString]){
                    eventExists = true;
                }
            }
            
            if(!eventExists)
            {
                [[[ActivityViewController sharedInstance] activityList] addObject:newActivity];
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[ActivityViewController sharedInstance].activityTableView reloadData];
        });
    }

    
}

+ (void) sync:(nokeDevice*)noke Delegate:(id) delegate
{
    NSString* url;
    
    if(noke.deviceType == NLDeviceTypeFob)
    {
        url = [NSString stringWithFormat:@"%@%@",serverUrl,@"fob/sync/"];
    }
    else
    {
        url = [NSString stringWithFormat:@"%@%@",serverUrl,@"lock/sync/"];
    }
    
    
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                              [noke getSessionAsString], @"session",
                              [noke mac], @"mac",
                              nil];
    
    if ([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_UNLOCK URL:url Data:tempJsonData Noke:noke Delegate:delegate];
    }
}

+ (void) getFobBySelf:(id) delegate
{
    NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl,@"user/fobs/"];
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:@"",@"", nil];
    
    if([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_GET_FOB_SELF URL:url Data:tempJsonData Delegate:delegate];
    }
}

+ (void) getFobCallback:(NSDictionary*)jsonDict
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[nokeSDK sharedInstance] removeAllFobs];
    });
    
    
    //NSLog(@"GET FOB: %@", jsonDict);
    NSDictionary* data = [jsonDict objectForKey:@"data"];
    NSArray* fobs = [data objectForKey:@"fobs"];
    NSString* countString = [data objectForKey:@"count"];
    int fobCount = [countString intValue];
    
    if(fobCount > 0)
    {
        for (int i = 0; i < [fobs count]; i++) {
            NSDictionary* tmpFob = [fobs objectAtIndex:i];
            nokeDevice* tmpNoke = [[nokeDevice alloc] initWithName:[tmpFob objectForKey:@"name"] Mac:[tmpFob objectForKey:@"macAddress"]];
            tmpNoke.isSetup = true;
            tmpNoke.isOwned = true;
            tmpNoke.isConnected = false;
            tmpNoke.unlockMethod = NLUnlockMethodTwoStep;
            
            int syncValue = [[tmpFob objectForKey:@"syncFlag"]intValue];
            BOOL sync = false;
            if(syncValue == 1)
            {
                sync = true;
            }
            tmpNoke.sync = sync;
            tmpNoke.serial = @"";
            tmpNoke.deviceType = NLDeviceTypeFob;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[nokeSDK sharedInstance] insertNokeDevice:tmpNoke];
                
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"REFRESH FOB TABLE");
            [[FobsViewController sharedInstance].fobsTableView reloadData];
        });
    }
    
    [[nokeSDK sharedInstance] startScanForNokeDevices];
}


+ (void) resetPassword:(NSString*) company Password:(NSString*) username Delegate:(id)delegate
{
    NSString* url = [NSString stringWithFormat:@"%@%@", serverUrl, @"user/password/forget/"];
    
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                              company, @"companyDomain",
                              username, @"userName",
                              nil];
    
    if ([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        NSString *strData = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        [nokeClient request:REQUEST_RESET_PASSWORD URL:url Data:tempJsonData Delegate:delegate];
    }
}

+ (void) getLockDetails: (NSString*)mac Delegate: (id) delegate
{
    NSString* url = [NSString stringWithFormat:@"%@%@",serverUrl,@"lock/details/"];
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:
                              mac, @"macAddress",
                              nil];
    
    if([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_GET_LOCK_DETAILS URL:url Data:tempJsonData Delegate:delegate];
    }
}

+ (void) findLock:(NSString*)mac Noke:(nokeDevice*) noke Delegate: (id) delegate
{
    //Doesn't matter, will make my own message in python
    NSString* url = [NSString stringWithFormat:@"%@%@", serverUrl,@"lock/find/"];
    NSDictionary* jsonBody = [[NSDictionary alloc] initWithObjectsAndKeys:mac, @"macAddress", nil];
    
    if([NSJSONSerialization isValidJSONObject:jsonBody])
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonBody options:NSJSONWritingPrettyPrinted error:&error];
        NSMutableData *tempJsonData = [NSMutableData dataWithData:jsonData];
        [nokeClient request:REQUEST_GET_LOCK_NAME URL:url Data:tempJsonData Noke:noke Delegate:delegate];
    }
}


+ (NSString *) platformString{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,2"])    return @"iPhone 4 CDMA";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 7";
    if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 7 Plus";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPod6,1"])      return @"iPod Touch 6G";
    if ([platform isEqualToString:@"iPod7,1"])      return @"iPod Touch 7G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (Cellular)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (Cellular)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (Cellular)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (Cellular)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (Cellular)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (Cellular)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (Cellular)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (Cellular)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return @"Unknown";
}









@end
