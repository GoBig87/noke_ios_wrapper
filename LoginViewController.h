//
//  LoginViewController.h
//  ios-enterprise
//
//  Created by Spencer Apsley on 4/28/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@interface LoginViewController : UIViewController<UITextFieldDelegate>
+ (LoginViewController*) sharedInstance;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;
- (IBAction)clickBtnLogin:(id)sender;
@property (nonatomic) Reachability *hostReachability;
@property (weak, nonatomic) IBOutlet UITextField *textUserName;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
@property (weak, nonatomic) IBOutlet UITextField *textCompany;
@property (weak, nonatomic) IBOutlet UISwitch *switchRememberMe;
@property (weak, nonatomic) IBOutlet UILabel *labelRememberMe;
@property (weak, nonatomic) IBOutlet UIImageView *nokeLogo;
@property (weak, nonatomic) IBOutlet UILabel *labelForgotPassword;

@end
