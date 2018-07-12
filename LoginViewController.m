//
//  LoginViewController.m
//  ios-enterprise
//
//  Created by Spencer Apsley on 4/28/16.
//  Copyright © 2016 Noke. All rights reserved.
//

#import "LoginViewController.h"
#import "nokeClient.h"
#import "LocksViewController.h"
@interface LoginViewController ()
@end

@implementation LoginViewController

static LoginViewController *loginViewController;


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _textCompany.delegate = self;
    _textUserName.delegate = self;
    _textPassword.delegate = self;
    
    [_btnLogin setBackgroundColor:[UIColor colorWithRed:0.25 green:0.52 blue:0.77 alpha:1.0]];
    [_btnLogin setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
 
    UIView *compPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    _textCompany.leftView = compPaddingView;
    _textCompany.leftViewMode = UITextFieldViewModeAlways;
    
    UIView * userPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    _textUserName.leftView = userPaddingView;
    _textUserName.leftViewMode = UITextFieldViewModeAlways;
    
    UIView * passwordPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    _textPassword.leftView = passwordPaddingView;
    _textPassword.leftViewMode = UITextFieldViewModeAlways;
    
    _labelForgotPassword.userInteractionEnabled = YES;
    UITapGestureRecognizer *forgotgesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapForgotPassword)];
    [_labelForgotPassword addGestureRecognizer:forgotgesture];
}


-(void)tapForgotPassword
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Forgot Password" message:@"Please enter your company and email below to reset your password" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.placeholder = @"Company";
        textField.textColor = [UIColor blackColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        
    }];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField){
        textField.placeholder = @"Email";
        textField.textColor = [UIColor blackColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;        
        
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * companyfield = textfields[0];
        UITextField * emailfield = textfields[1];
        
        NSString* company = companyfield.text;
        NSString* email = emailfield.text;
        
        [nokeClient resetPassword:company Password:email Delegate:self];
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == _textCompany)
    {
        [textField resignFirstResponder];
        [_textUserName becomeFirstResponder];
    }
    else if (textField == _textUserName)
    {
        [textField resignFirstResponder];
        [_textPassword becomeFirstResponder];
    }
    else if(textField == _textPassword)
    {
        [textField resignFirstResponder];
    }
    return YES;
}


-(void)viewDidAppear:(BOOL)animated
{
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (LoginViewController*) sharedInstance
{
    if(loginViewController == nil)
    {
        loginViewController = [[LoginViewController alloc] init];
        
    }
    return loginViewController;
}

- (IBAction)clickBtnLogin:(id)sender
{
    NSString* username = _textUserName.text;
    NSString* password = _textPassword.text;
    NSString* company = _textCompany.text;
    
    [nokeClient login:username Password:password CompanyDomain:company Delegate:self];
}

//RESET PASSWORD CALLBACK
-(void)resetPasswordResponse:(NSDictionary *)jsonDict
{
    NSString* result = [jsonDict objectForKey:@"result"];
    
    if([result isEqualToString:@"success"])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Reset Password", nil) message:NSLocalizedString(@"An email has been sent to you that contains instructions to reset your password.", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
            [failedController addAction:okAction];
            
            [self presentViewController:failedController animated:TRUE completion:nil];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"The company or email is incorrect.  Please try again.", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
            [failedController addAction:okAction];
            
            [self presentViewController:failedController animated:TRUE completion:nil];
        });
    }
}

//DATA RECEIVED CALLBACK
-(void)didReceiveResponse:(NSDictionary *)data
{
    if(data != nil)
    {
        NSString* result = [data objectForKey:@"result"];
        
        if([result isEqualToString:@"success"])
        {
            //Pull values out of the JSON objects
            NSDictionary* user = [data objectForKey:@"user"];
            NSString* name = [user objectForKey:@"name"];
            NSString* username = [user objectForKey:@"username"];
            NSString* flagString = [user objectForKey:@"installerFlag"];
            
            NSDictionary* company = [user objectForKey:@"company"];
            NSString* companyName = [company objectForKey:@"name"];
            int flag = [flagString intValue];
            
            [[[nokeSDK sharedInstance] nokeDevices] removeAllObjects];
            [[[nokeSDK sharedInstance] nokeGroups] removeAllObjects];
            
            //Sets user values so we can use them later
            [[LocksViewController sharedInstance] setUserData:name Email:username Flag:flag CompanyName:companyName];
            [[LocksViewController sharedInstance] setIsLoggedIn:true];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
        }
        else
        {
            int errorCode = [[data valueForKey:@"errorCode"] intValue];
            NSLog(@"ERROR CODE: %d", errorCode);
            
            if(errorCode == ERROR_INCORRECT_APP_KEY)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Incorrect Login", nil) message:NSLocalizedString(@"This user is already registered on a different device", nil) preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                    [failedController addAction:okAction];
                    
                    [self presentViewController:failedController animated:TRUE completion:nil];
                });
                
            }
            else if(errorCode == ERROR_PERMISSION_DENIED)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Incorrect Login", nil) message:NSLocalizedString(@"This user does not have permission to login to the app", nil) preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                    [failedController addAction:okAction];
                    
                    [self presentViewController:failedController animated:TRUE completion:nil];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Incorrect Login", nil) message:NSLocalizedString(@"The username or password is incorrect. Please try again", nil) preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                    [failedController addAction:okAction];
                    
                    [self presentViewController:failedController animated:TRUE completion:nil];
                });
            }
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *failedController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Unable to login. Please check your internet connection.", nil) preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:nil];
                [failedController addAction:okAction];
                
                [self presentViewController:failedController animated:TRUE completion:nil];
            });
    }
}

@end
