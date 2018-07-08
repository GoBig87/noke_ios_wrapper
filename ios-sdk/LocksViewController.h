//
//  LocksViewController.h
//  ios-enterprise
//
//  Created by Spencer Apsley on 4/29/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "nokeDevice.h"
#import "nokeSDK.h"
#import "nokeClient.h"
#import "Reachability.h"

@interface LocksViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, nokeSDKDelegate, nokeClientDelegate, CLLocationManagerDelegate>
{
    BOOL isLoggedIn;
    NSString* username;
    NSString* useremail;
    NSString* userpassword;
    int installerFlag;
    NSString* companyname;
    NSMutableArray *connectedLocks;
    
}
@property (weak, nonatomic) IBOutlet UITableView *locksTableView;
@property (weak, nonatomic) IBOutlet UIView *lockTabBar;

@property UIRefreshControl *refreshControl;
@property (nonatomic) Reachability *hostReachability;
+ (LocksViewController*) sharedInstance;
-(void)setIsLoggedIn:(BOOL)loggedin;
-(void)setUserData:(NSString*)name Email:(NSString*)email Flag:(int)flag CompanyName:(NSString*)company;
-(NSString*)getUsername;
-(NSString*)getEmail;
-(NSString*)getPassword;
-(NSString*)getCompany;
-(void)setPassword:(NSString*)password;
-(int)getInstallerFlag;
-(void)checkLogin;

@property (weak, nonatomic) IBOutlet UIImageView *imageLock;
@property (weak, nonatomic) IBOutlet UILabel *searchingLabel;

@end
