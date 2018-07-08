//
//  LockDetailsViewController.m
//  ios-enterprise-lite
//
//  Created by Spencer Apsley on 7/22/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import "LockDetailsViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "nokeDevice.h"
#import "nokeSDK.h"
#import <LocalAuthentication/LocalAuthentication.h>


@interface LockDetailsViewController ()

@end

@implementation LockDetailsViewController

static LockDetailsViewController *lockDetailsViewController;
UIButton* btnOneStep;
UIButton* btnTwoStep;
UIButton* btnTouch;
BOOL mapAvailable;
UILabel* battery;
NSString* batteryDisplay;
NSString* serialDisplay;
float lon;
float lat;

+ (LockDetailsViewController*) sharedInstance
{
    if(lockDetailsViewController == nil)
    {
        lockDetailsViewController = [[LockDetailsViewController alloc] init];
        
    }
    return lockDetailsViewController;
}

- (void)viewDidLoad {
    
    
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]]; /*#2b3990*/
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [UIColor blackColor],
                                                                      NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:20.0f]
                                                                      }];
    
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0]];
    
    self.title = self.noke.name;
    
    /**
     self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"iconmenublue.png"] style:UIBarButtonItemStylePlain target:self.viewDeckController action:@selector(toggleLeftView)];
     
     
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icondotsblue.png"] style:UIBarButtonItemStylePlain target:self.viewDeckController action:@selector(toggleLeftView)];
     **/
    
    UIButton *dotsBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [dotsBtn setTintColor:[UIColor redColor]];
    [dotsBtn setImage:[UIImage imageNamed:@"ic_dots_blue.png"] forState:UIControlStateNormal];
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithCustomView:dotsBtn];
    [item setTintColor:[UIColor redColor]];
    //self.navigationItem.rightBarButtonItem = item;
    
    UIButton *menuBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [menuBtn setTintColor:[UIColor redColor]];
    [menuBtn setImage:[UIImage imageNamed:@"ic_menu_blue.png"] forState:UIControlStateNormal];
    //[menuBtn addTarget:self.viewDeckController action:@selector(toggleLeftView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* leftitem = [[UIBarButtonItem alloc] initWithCustomView:menuBtn];
    [leftitem setTintColor:[UIColor redColor]];
    //self.navigationItem.leftBarButtonItem = leftitem;
    
    //[self.viewDeckController setDelegate:self];
    [self.view setBackgroundColor:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]];
    
    _lockDetailsTable.dataSource = self;
    _lockDetailsTable.delegate = self;
    _lockDetailsTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    _lockDetailsTable.allowsSelection = false;
    
    [_lockDetailsTable setBackgroundColor:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]];
    
    
    //menuSettingsTitles = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Account", nil), NSLocalizedString(@"Quick-Click Code", nil), NSLocalizedString(@"Change Password",nil), NSLocalizedString(@"About", nil), NSLocalizedString(@"Support", nil), nil];
    
    batteryDisplay = @"";
    serialDisplay = @"";
    mapAvailable = false;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [nokeClient getLockDetails:self.noke.mac Delegate:self];
    //[self setUnlockMethodState];
}

-(void)setUnlockMethodState
{
    if(self.noke.unlockMethod == NLUnlockMethodOneStep)
    {
        
        [btnTwoStep setBackgroundColor:[UIColor whiteColor]];
        [btnTwoStep setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [btnTouch setBackgroundColor:[UIColor whiteColor]];
        [btnTouch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    else if(self.noke.unlockMethod == NLUnlockMethodTwoStep)
    {
        [btnTwoStep setBackgroundColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0]];
        [btnTwoStep setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [btnOneStep setBackgroundColor:[UIColor whiteColor]];
        [btnOneStep setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [btnTouch setBackgroundColor:[UIColor whiteColor]];
        [btnTouch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
    }
    else if(self.noke.unlockMethod == NLUnlockMethodTouch)
    {
        [btnTouch setBackgroundColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0]];
        [btnTouch setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [btnTwoStep setBackgroundColor:[UIColor whiteColor]];
        [btnTwoStep setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        [btnOneStep setBackgroundColor:[UIColor whiteColor]];
        [btnOneStep setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    
    if(row == 0)
    {
        return 118;
        //To add a fourth section, change everything to 4s and uncomment below...
        //return 157;
    }
    else if(row == 1)
    {
        return 118;
        //return 0;
    }
    else if(row == 2)
    {
        if(mapAvailable)
        {
            return 240;
        }
        else
        {
            return 0;
        }
        //return 0;
    }
    else if(row == 3)
    {
        return 118;
    }
    else if(row ==4)
    {
        //return 55;
        return 0;
    }
    else
    {
        return 55;
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 3;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"resueIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] init];
    }
    
    [cell setBackgroundColor:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1]];
    
    NSInteger row = [indexPath row];
    if(row == 0)
    {
        UIView* cardSubView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, _lockDetailsTable.frame.size.width-20, 103)];
        [cardSubView setBackgroundColor:[UIColor whiteColor]];
        
        cardSubView.layer.masksToBounds = NO;
        cardSubView.layer.shadowOffset = CGSizeMake(0, 2);
        cardSubView.layer.shadowRadius = 1;
        cardSubView.layer.shadowOpacity = 0.2;
        
        [cell addSubview:cardSubView];
        
        UILabel* batteryLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 8, cardSubView.frame.size.width/3, cardSubView.frame.size.height/3 -10)];
        batteryLabel.text = @"Battery Level:";
        [batteryLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        
        battery = [[UILabel alloc] initWithFrame:CGRectMake(cardSubView.frame.size.width/2, 8, cardSubView.frame.size.width/2 - 20, cardSubView.frame.size.height/3-10)];
        [battery setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        [battery setTextAlignment:NSTextAlignmentRight];
        battery.text = batteryDisplay;
    
        
        UILabel* serialLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, cardSubView.frame.size.height/3 + 2, cardSubView.frame.size.width/2, cardSubView.frame.size.height/3-10)];
        serialLabel.text = @"Serial Number:";
        [serialLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        
        UILabel* serial = [[UILabel alloc] initWithFrame:CGRectMake(cardSubView.frame.size.width/2, cardSubView.frame.size.height/3 + 2, cardSubView.frame.size.width/2 - 20, cardSubView.frame.size.height/3-10)];
        [serial setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        [serial setTextAlignment:NSTextAlignmentRight];
        serial.text = serialDisplay;
        [serial setAdjustsFontSizeToFitWidth:true];
        
        UILabel* macLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, cardSubView.frame.size.height/3 *2-5, cardSubView.frame.size.width/2, cardSubView.frame.size.height/3-10)];
        macLabel.text = @"Mac Address:";
        [macLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        
        UILabel* mac = [[UILabel alloc] initWithFrame:CGRectMake(cardSubView.frame.size.width/2, cardSubView.frame.size.height/3 *2-5, cardSubView.frame.size.width/2 - 20, cardSubView.frame.size.height/3-10)];
        [mac setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        [mac setTextAlignment:NSTextAlignmentRight];
        mac.text = self.noke.mac;
        [mac setAdjustsFontSizeToFitWidth:true];
        
        
        UILabel* versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, cardSubView.frame.size.height/4 * 3-5, cardSubView.frame.size.width/2, cardSubView.frame.size.height/4-10)];
        versionLabel.text = @"Version:";
        [versionLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        
        UILabel* version = [[UILabel alloc] initWithFrame:CGRectMake(cardSubView.frame.size.width/2, cardSubView.frame.size.height/4 * 3 -5, cardSubView.frame.size.width/2 - 20, cardSubView.frame.size.height/4-10)];
        [version setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        [version setTextAlignment:NSTextAlignmentRight];
        version.text = self.noke.versionString;
        
        
        [cardSubView addSubview:batteryLabel];
        [cardSubView addSubview:battery];
        [cardSubView addSubview:serialLabel];
        [cardSubView addSubview:serial];
        [cardSubView addSubview:macLabel];
        [cardSubView addSubview:mac];
        //[cardSubView addSubview:versionLabel];
        //[cardSubView addSubview:version];
    }
    else if(row == 1)
    {
        
        UIView* cardSubView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, _lockDetailsTable.frame.size.width - 30, 103)];
        [cardSubView setBackgroundColor:[UIColor whiteColor]];
        
        cardSubView.layer.masksToBounds = NO;
        cardSubView.layer.shadowOffset = CGSizeMake(0, 2);
        cardSubView.layer.shadowRadius = 1;
        cardSubView.layer.shadowOpacity = 0.2;
        
        [cell addSubview:cardSubView];
        
        UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, cardSubView.frame.size.width-20, cardSubView.frame.size.height/3 -10)];
        titleLabel.text = @"Unlocking Method";
        [titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:20]];
        
        [cardSubView addSubview:titleLabel];
        
        btnOneStep = [[UIButton alloc] initWithFrame:CGRectMake(20, cardSubView.frame.size.height/3 + 10, cardSubView.frame.size.width/3 -20, 40)];
        btnTwoStep = [[UIButton alloc] initWithFrame:CGRectMake(btnOneStep.frame.origin.x + btnOneStep.frame.size.width + 10, cardSubView.frame.size.height/3 + 10, cardSubView.frame.size.width/3 -20, 40)];
        btnTouch = [[UIButton alloc] initWithFrame:CGRectMake(btnTwoStep.frame.origin.x + btnTwoStep.frame.size.width + 10, cardSubView.frame.size.height/3 + 10, cardSubView.frame.size.width/3 -20, 40)];
        
        
        [btnOneStep setTitle:@"1-Step" forState:UIControlStateNormal];
        [btnOneStep.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        [[btnOneStep layer] setBorderWidth:1.0f];
        [[btnOneStep layer] setCornerRadius:10.0f];
        
        [btnOneStep addTarget:self action:@selector(clickUnlockMethod:) forControlEvents:UIControlEventTouchUpInside];
        
        if(self.noke.unlockMethod == NLUnlockMethodOneStep)
        {
            [btnOneStep setBackgroundColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0]];
            [btnOneStep setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [[btnOneStep layer] setBorderColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0].CGColor];
        }
        else
        {
            [btnOneStep setBackgroundColor: [UIColor whiteColor]];
            [btnOneStep setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [[btnOneStep layer] setBorderColor:[UIColor grayColor].CGColor];
        }
        
        [btnTwoStep setTitle:@"2-Step" forState:UIControlStateNormal];
        [btnTwoStep.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        [[btnTwoStep layer] setBorderWidth:1.0f];
        [[btnTwoStep layer] setBorderColor:[UIColor grayColor].CGColor];
        [[btnTwoStep layer] setCornerRadius:10.0f];
        [btnTwoStep addTarget:self action:@selector(clickUnlockMethod:) forControlEvents:UIControlEventTouchUpInside];
        
        if(self.noke.unlockMethod == NLUnlockMethodTwoStep)
        {
            [btnTwoStep setBackgroundColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0]];
            [btnTwoStep setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [[btnTwoStep layer] setBorderColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0].CGColor];
        }
        else
        {
            [btnTwoStep setBackgroundColor: [UIColor whiteColor]];
            [btnTwoStep setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [[btnTwoStep layer] setBorderColor:[UIColor grayColor].CGColor];
        }
        
        [btnTouch setTitle:@"Touch" forState:UIControlStateNormal];
        [btnTouch.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:20]];
        [[btnTouch layer] setBorderWidth:1.0f];
        [[btnTouch layer] setBorderColor:[UIColor grayColor].CGColor];
        [[btnTouch layer] setCornerRadius:10.0f];
        [btnTouch addTarget:self action:@selector(clickUnlockMethod:) forControlEvents:UIControlEventTouchUpInside];
        
        if(self.noke.unlockMethod == NLUnlockMethodTouch)
        {
            [btnTouch setBackgroundColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0]];
            [btnTouch setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [[btnTouch layer] setBorderColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0].CGColor];
        }
        else
        {
            [btnTouch setBackgroundColor: [UIColor whiteColor]];
            [btnTouch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [[btnTouch layer] setBorderColor:[UIColor grayColor].CGColor];
        }
        
        [cardSubView addSubview:btnOneStep];
        [cardSubView addSubview:btnTwoStep];
        
        if([self canAuthenticateByTouchId])
        {
            [cardSubView addSubview:btnTouch];
        }
    }
    else if(row == 2)
    {
         UIView* cardSubView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, _lockDetailsTable.frame.size.width-20, 230)];
         [cardSubView setBackgroundColor:[UIColor whiteColor]];
         
         cardSubView.layer.masksToBounds = NO;
         cardSubView.layer.shadowOffset = CGSizeMake(0, 2);
         cardSubView.layer.shadowRadius = 1;
         cardSubView.layer.shadowOpacity = 0.2;
         
        
         
         UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, cardSubView.frame.size.width - 30, 40)];
         titleLabel.text = @"Last Known Location";
         [titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:20]];
        
        
        
        
        if(mapAvailable)
        {
            [cell addSubview:cardSubView];
            [cardSubView addSubview:titleLabel];

        }
        
    }
    else if(row ==3)
    {
        
    }
    else if(row ==4)
    {
        /**
         UIView* cardSubView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, _tableSettings.frame.size.width-20, 45)];
         [cardSubView setBackgroundColor:[UIColor whiteColor]];
         
         cardSubView.layer.masksToBounds = NO;
         cardSubView.layer.shadowOffset = CGSizeMake(0, 2);
         cardSubView.layer.shadowRadius = 1;
         cardSubView.layer.shadowOpacity = 0.2;
         
         [cell addSubview:cardSubView];
         
         UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, cardSubView.frame.size.width/2, cardSubView.frame.size.height -10)];
         titleLabel.text = [menuSettingsTitles objectAtIndex:row];
         [titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:20]];
         
         [cardSubView addSubview:titleLabel];
         **/
    }
    
    return cell;
    
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (BOOL)canAuthenticateByTouchId
{
    if ([LAContext class]) {
        return [[[LAContext alloc] init] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    }
    return NO;
}

-(void)clickUnlockMethod:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSIndexPath* index = [NSIndexPath indexPathForRow:1 inSection:0];
    
    if([btn.currentTitle isEqualToString:@"1-Step"])
    {
        self.noke.unlockMethod = NLUnlockMethodOneStep;
        [_lockDetailsTable reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationNone];
        [[nokeSDK sharedInstance] saveNokeDevices];
        [[nokeSDK sharedInstance] retrieveKnownPeripherals];
    }
    else if([btn.currentTitle isEqualToString:@"2-Step"])
    {
        self.noke.unlockMethod = NLUnlockMethodTwoStep;
        [_lockDetailsTable reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationNone];
        [[nokeSDK sharedInstance] saveNokeDevices];
        [[nokeSDK sharedInstance] retrieveKnownPeripherals];
        [[nokeSDK sharedInstance] disconnectNokeDevice:self.noke];
    }
    else if([btn.currentTitle isEqualToString:@"Touch"])
    {
        self.noke.unlockMethod = NLUnlockMethodTouch;
        [_lockDetailsTable reloadRowsAtIndexPaths:[NSArray arrayWithObjects:index, nil] withRowAnimation:UITableViewRowAnimationNone];
        [[nokeSDK sharedInstance] saveNokeDevices];
        [[nokeSDK sharedInstance] retrieveKnownPeripherals];
        [[nokeSDK sharedInstance] disconnectNokeDevice:self.noke];
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (indexPath.row) {
        case 0:
        {
            //[self.navigationController pushViewController:[AboutViewController sharedInstance] animated:YES];
            
            break;
        }
        case 1:
        {
            
            break;
        }
        case 2:
        {
            
            
            break;
        }
        case 3:
        {
            
            break;
            
        }
            
            
        default:
            break;
    }
    
}

-(void)didReceiveResponse:(NSDictionary *)data
{
    NSString* longitude = [data objectForKey:@"longitude"];
    NSString* latitude = [data objectForKey:@"latitude"];
    batteryDisplay = [[data objectForKey:@"powerDisplay"] capitalizedString];
    serialDisplay = [data objectForKey:@"serial"];
    
    lon = [longitude floatValue];
    lat = [latitude floatValue];
    
    if(lon != 0 && lat != 0)
    {
        mapAvailable = true;
    }
    else
    {
        mapAvailable = false;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_lockDetailsTable reloadData];
    });
    
}

-(void)didReceiveNokeResponse:(NSDictionary *)data Noke:(nokeDevice *)noke
{
    //TODO IMPLEMENT METHOD
}

@end
