//
//  activityItem.h
//  ios-enterprise-lite
//
//  Created by Spencer Apsley on 5/20/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface activityItem : NSObject

@property int logid;
@property int lockid;
@property int userid;
@property int groupid;
@property NSString* eventKey;
@property NSString* lockname;
@property NSString* timestamp;
@property NSString* fullname;
@property NSString* longitude;
@property NSString* latitude;
@property NSString* activitytype;

- (activityItem *) initWithId:(int)activityid;
- (NSString*) getActivityString;
- (NSString*) getDateString;
- (NSString*) getTimeString;

@end
