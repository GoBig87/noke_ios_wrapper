//
//  LockDetailsViewController.h
//  ios-enterprise-lite
//
//  Created by Spencer Apsley on 7/22/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "nokeDevice.h"
#import "nokeClient.h"

@interface LockDetailsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, nokeClientDelegate>
@property (weak, nonatomic) IBOutlet UITableView *lockDetailsTable;
@property(nonatomic) nokeDevice* noke;
+ (LockDetailsViewController*) sharedInstance;


@end
