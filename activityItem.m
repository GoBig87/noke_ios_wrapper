//
//  activityItem.m
//  ios-enterprise-lite
//
//  Created by Spencer Apsley on 5/20/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import "activityItem.h"

@implementation activityItem

@synthesize logid = _logid;
@synthesize lockid = _lockid;
@synthesize lockname = _lockname;
@synthesize userid = _userid;
@synthesize groupid = _groupid;
@synthesize timestamp = _timestamp;
@synthesize fullname = _fullname;
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;
@synthesize activitytype = _activitytype;


- (activityItem *) initWithId:(int)activityid
{
    _logid = activityid;
    return self;
}


-(NSString*) getActivityString
{
    NSString* activityString = @"UNKNOWN ACTIVITY TYPE";
    _fullname = @"You";
    
    if([_activitytype isEqualToString:@"unlocked_lock"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ unlocked %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"locked_lock"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ locked %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"UNLATCHED"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ unlatched %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"LATCHED"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ latched %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"BUTTONPRESS OFFLINE"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ press button on %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"UNLOCKED OFFLINE"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ unlocked %@ offline", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"LOCKED OFFLINE"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ locked %@ offline", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"QC OPENED"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ used quick-click on %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"QC CLOSED"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ locked %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"Fob LOCKED"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ locked %@", nil), _fullname, _lockname];
    }
    else if([_activitytype isEqualToString:@"Fob UNLOCKED"])
    {
        activityString = [NSString stringWithFormat:NSLocalizedString(@"%@ unlocked %@ with fob", nil), _fullname, _lockname];
    }
    
    return activityString;
}


-(NSString*) getDateString
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [dateFormat dateFromString:_timestamp];
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"MMM dd, yyyy"];
    
    return [outputFormatter stringFromDate:date];
    
}

-(NSString*) getTimeString
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [dateFormat dateFromString:_timestamp];
    
    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    [outputFormatter setDateFormat:@"h:mm a"];
    
    return [outputFormatter stringFromDate:date];
}


@end
