//
//  nokeClient.h
//  ios-sdk
//
//  Created by Spencer Apsley on 3/15/16.
//  Copyright © 2016 Noke LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "nokeDevice.h"

#define MAIN_URL @"https://v1.api.nokepro.com/"
//#define MAIN_URL @"https://v1.api.dev.nokepro.com/"

//ENDPOINTS
#define LOGIN @"applogin/"
#define GETGROUPSBYUSER @"getgroupsbyuser/"
#define UNLOCK @"unlock/"
#define SETUP @"setuplock/"
#define UPLOADDATARESPONSE @"uploaddataresponse/"

//ERRORS
#define ERROR_SUCCESS                   0
#define ERROR_MEMBER_NOT_IN_GROUP       1
#define ERROR_ACTIVITY_NOT_RECORDED     2
#define ERROR_INVALID_INPUT             3
#define ERROR_PRIVILEGES_REVOKED        4
#define ERROR_COMP_PRIVILEGES_REVOKED   5
#define ERROR_10_LOGIN_ATTEMPTS         6
#define ERROR_INCORRECT_PASSWORD        7
#define ERROR_INVALID_CREDENTIALS       8
#define ERROR_TOKEN                     9
#define ERROR_INTERNAL_SERVER           10
#define ERROR_PERMISSION_DENIED         11
#define ERROR_LOCK_NOT_FOUND            12
#define ERROR_NO_ACTIVITY_FOUND         13
#define ERROR_USERNAME_ALREADY_EXISTS   14
#define ERROR_NO_USERS_IN_GROUP         15
#define ERROR_NO_PADLOCKS_IN_GROUP      16
#define ERROR_NO_SCHEDULES_SET          17
#define ERROR_ITEM_DELETED              18
#define ERROR_MEMBER_IN_GROUP           19
#define ERROR_GROUP_NOT_FOUND           20
#define ERROR_ACTIVITY_RECORDING        21
#define ERROR_CHECKING_PERMISSIONS      22
#define ERROR_NO_CHANGES_MADE           23
#define ERROR_ARCHIVE_NOT_FOUND         24
#define ERROR_EMAIL_NOT_FOUND           25
#define ERROR_INCORRECT_APP_KEY         26
#define ERROR_NO_QUICK_CLICKS           27
#define ERROR_ITEM_NOT_FOUND            28
#define ERROR_FOB_NOT_FOUND             29
#define ERROR_JSON_FORMAT               30
#define ERROR_SESSION_LENGTH            31
#define ERROR_LOCK_NOT_SETUP            32
#define ERROR_NO_ACTIVE_SCHEDULE        33
#define ERROR_PARSE_SESSION             34
#define ERROR_MAC_LENGTH                35
#define ERROR_NAME_LENGTH               36
#define ERROR_NOT_A_LOCK                37
#define ERROR_NOT_A_FOB                 38
#define ERROR_UNKNOWN_SESSION           39
#define ERROR_FOB_NOT_SETUP             40
#define ERROR_FOB_SETUP                 42
#define ERROR_LOCK_SETUP                43
#define ERROR_TIME_SYNC                 50


@protocol nokeClientDelegate
- (void) didReceiveResponse:(NSDictionary*) data;
- (void) didReceiveNokeResponse:(NSString*)data Noke:(nokeDevice*)noke;
@optional
-(void)resetPasswordResponse:(NSDictionary*)data;
-(void) didReceiveFindLockResponse:(NSDictionary*)data Noke:(nokeDevice*)noke;

@end

@interface nokeClient : NSObject

+ (void) request:(int)command URL:(NSString*) strUrl Data:(NSMutableData *)JsonData Noke:(nokeDevice*)noke Delegate:(id) delegate;
+ (void) login:(NSString*) userName Password:(NSString*)password CompanyDomain:(NSString*)companyDomain Delegate:(id) delegate;
+ (void) setupLock:(nokeDevice*)noke Name:(NSString*)name Delegate:(id) delegate;
+ (void) uploadData:(id) delegate;
+ (void) unlock:(nokeDevice*)noke Delegate:(id) delegate;
+ (void) getGroupsByUsers:(id) delegate;
+ (void) getGroupsByUsersCallback:(NSDictionary*)jsonDict;
+ (void) refreshToken;
+ (void) getActivity;
+ (void) sync:(nokeDevice*)noke Delegate:(id) delegate;
+ (void) getFobBySelf:(id) delegate;
+ (void) getLockDetails: (NSString*)mac Delegate:(id)delegate;
+ (void) resetPassword:(NSString*) company Password:(NSString*) username Delegate:(id)delegate;
+ (void) findLock:(NSString*)mac Noke:(nokeDevice*) noke Delegate: (id) delegate;
+ (void) setToken:(NSString*)token;


//USED TO GET THE DEVICE TYPE
+ (NSString *) platformString;

@end
