//
//  FobsViewController.h
//  ios-api-library
//
//  Created by Spencer Apsley on 10/28/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "nokeDevice.h"
#import "nokeSDK.h"
#import "nokeClient.h"
#import "Reachability.h"
#import <UIKit/UIKit.h>

@interface FobsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, nokeSDKDelegate, nokeClientDelegate, CLLocationManagerDelegate>
{
    BOOL isLoggedIn;
    NSString* username;
    NSString* useremail;
    NSString* userpassword;
    int installerFlag;
    NSMutableArray *connectedFobs;
    
}

@property (weak, nonatomic) IBOutlet UITableView *fobsTableView;

@property UIRefreshControl *refreshControl;
@property (nonatomic) Reachability *hostReachability;
+ (FobsViewController*) sharedInstance;
-(void)setIsLoggedIn:(BOOL)loggedin;
-(void)setUserData:(NSString*)name Email:(NSString*)email Flag:(int)flag;
-(void)checkLogin;
-(void)handleRefresh;

@property (weak, nonatomic) IBOutlet UIImageView *imageLock;
@property (weak, nonatomic) IBOutlet UILabel *searchingLabel;


@end
