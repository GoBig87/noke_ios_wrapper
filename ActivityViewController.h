//
//  ActivityViewController.h
//  ios-enterprise
//
//  Created by Spencer Apsley on 4/29/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *activityTableView;

@property (weak, nonatomic) IBOutlet UIView *activityTabBar;
@property NSMutableArray* activityList;
+ (ActivityViewController*) sharedInstance;
@end
