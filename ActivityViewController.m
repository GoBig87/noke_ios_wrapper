//
//  ActivityViewController.m
//  ios-enterprise
//
//  Created by Spencer Apsley on 4/29/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import "ActivityViewController.h"
#import "nokeClient.h"
#import "activityItem.h"


@interface ActivityViewController ()

@end

NSArray *sampleActivity;


@implementation ActivityViewController

static ActivityViewController *activityViewController;

+ (ActivityViewController*) sharedInstance
{
    if(activityViewController == nil)
    {
        activityViewController = [[ActivityViewController alloc] init];
        activityViewController.activityList = [[NSMutableArray alloc] init];
        
    }
    return activityViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]]; /*#2b3990*/
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName: [UIColor blackColor],
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:20.0f]
                                                                      }];
    
    [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.00 green:0.44 blue:0.80 alpha:1.0]];
    
    self.title = @"Activity";
    
    self.view.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    
    _activityTableView.backgroundColor = [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
    _activityTableView.dataSource = self;
    _activityTableView.delegate = self;
    _activityTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backItem];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [nokeClient getActivity];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //GET ACTIVITY ITEM
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.activityList count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 84;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    activityItem* activity = [self.activityList objectAtIndex:indexPath.row];
    
    static NSString *cellIdentifier = @"resueIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] init];
    }
    
    [cell setBackgroundColor:[UIColor whiteColor]];
    
    UILabel* nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 10, cell.frame.size.width - 60, 32)];
    nameLabel.text = [activity getActivityString];
    [nameLabel setFont:[UIFont systemFontOfSize:20]];
    
    [cell addSubview:nameLabel];
    
    
    UILabel* dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(30, 42, cell.frame.size.width/2, 32)];
    
    [dateLabel setText:[activity getDateString]];
    [dateLabel setFont:[UIFont systemFontOfSize:15]];
    
    UILabel* timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width/2, 42, cell.frame.size.width/2 - 30, 32)];
    
    [cell addSubview:dateLabel];
    [cell addSubview:timeLabel];
    
    [timeLabel setText:[activity getTimeString]];
    [timeLabel setFont:[UIFont systemFontOfSize:15]];
    
    [timeLabel setTextAlignment:NSTextAlignmentRight];
    return cell;
}
@end
