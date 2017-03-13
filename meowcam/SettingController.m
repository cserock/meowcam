//
// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SettingController.h"
#import <MessageUI/MessageUI.h>
#include <sys/sysctl.h>
#import "InAppPurchase.h"

@import Firebase;

#define MENU_SUPPORT_BUY_UPGRADE 10
#define MENU_SUPPORT_RESTORE_UPGRADE 11
#define MENU_SUPPORT_FEEDBACK 20
#define MENU_SUPPORT_INVITE_FRIENDS 21
#define MENU_SUPPORT_REVIEWS 22

#define MENU_SOUND_AUTO_PLAY 30

#define ITEM_1_ID @"me.neosave.meowcam.item01"

@interface SettingController () <UIAlertViewDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *settingTableView;
@property (weak, nonatomic) IBOutlet UITableViewCell *buyCell;

@property (weak, nonatomic) IBOutlet UISwitch *afterListeningSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *afterCheckingSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *autoPlaySwitch;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (assign) Boolean isPaid;

@property (nonatomic, strong) FIRDatabaseReference *ref;

@end

@implementation SettingController


- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // hide buy cell
    if (indexPath.section == 0 && indexPath.row == 0) {
        // Show or hide cell
        if (!_isPaid) {
            return 44;
        } else {
            return 0;
        }
    }
    return 44;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:@"InAppPurchasedNotification" object:nil];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _isPaid = [defaults boolForKey:ITEM_1_ID];
    
    if(_isPaid){
         [self.tableView reloadData];
    }
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"viewWillDisappear");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_spinner stopAnimating];
}

- (void)productPurchased:(NSNotification *)notification {
    
    [_spinner stopAnimating];
    
    NSArray *data = notification.object;
    NSString *productIdentifier = [data objectAtIndex:0];
    NSString *mode = [data objectAtIndex:1];
    NSString *transactionIdentifier = [data objectAtIndex:2];
    NSString *transactionDate = [data objectAtIndex:3];
    NSString *uId = [FIRAuth auth].currentUser.uid;
    
    NSLog(@"mode : %@", mode);
    
    if([mode isEqualToString:@"error"]){
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _isPaid = [defaults boolForKey:ITEM_1_ID];
    
    if(_isPaid){
        [self.tableView reloadData];
    }
    
    
    if([productIdentifier isEqualToString:ITEM_1_ID]){
        NSLog(@"productIdentifier : %@", productIdentifier);
        NSLog(@"transactionIdentifier : %@", transactionIdentifier);
        
        // update purchase info
        _ref = [[FIRDatabase database] reference];
        NSDictionary *purchase = @{@"uid": uId,
                                   @"pid": productIdentifier,
                                   @"tid": transactionIdentifier,
                                   @"date": transactionDate};
        
        NSDictionary *updates = @{[@"/purchases/" stringByAppendingString:transactionIdentifier]: purchase};
        [_ref updateChildValues:updates];
        
        
        if([mode isEqualToString:@"restore"]){
        
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Payment",nil)
                                                            message:NSLocalizedString(@"Retore is completed.\nThank you.",nil)
                                                           delegate:self
                                                  cancelButtonTitle:@"Done" otherButtonTitles:nil];
            [alert show];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"SettingController viewDidLoad");
    _settingTableView.delegate = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // init paid
    _isPaid = [defaults boolForKey:ITEM_1_ID];
    
    
    [_autoPlaySwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    if([defaults boolForKey:@"noAutoPlay"]){
        [_autoPlaySwitch setOn:NO];
    } else {
        [_autoPlaySwitch setOn:YES];
    }
    
    // indicator
    _spinner = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_spinner setColor:[UIColor grayColor]];
    _spinner.center = CGPointMake((self.navigationController.view.frame.size.width/2), (self.navigationController.view.frame.size.height/2));
    _spinner.hidesWhenStopped = YES;
    [self.navigationController.view addSubview:_spinner];
}


- (void)switchChanged:(UISwitch *)sender
{
    
    NSInteger tag = [sender tag];
    BOOL state = [sender isOn];
    NSLog(@"tag : %ld / state : %d", (long)tag, state);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(tag == MENU_SOUND_AUTO_PLAY){
        [defaults setBool:!state forKey:@"noAutoPlay"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"noAutoPlay : %d", [defaults boolForKey:@"noAutoPlay"]);
    
}

-(void) inviteFriend {
    NSString *textToShare = NSLocalizedString(@"Download the Meow Camera",nil);

    NSURL *myWebsite = [NSURL URLWithString:@"https://itunes.apple.com/app/id1211559544?mt=8"];
    
    NSArray *objectsToShare = @[textToShare, myWebsite];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];
    
    activityVC.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void) alertPaymentError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Payment Error",nil)
                                                    message:NSLocalizedString(@"You are not authorized to purchase from AppStore.",nil)
                                                   delegate:self
                                          cancelButtonTitle:@"Done" otherButtonTitles:nil];
    [alert show];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    NSLog(@"%ld", (long)cell.tag);
    
    switch (cell.tag) {
        
        case MENU_SUPPORT_BUY_UPGRADE:
            
            if ([SKPaymentQueue canMakePayments]) {
                [_spinner startAnimating];
                
                [FIRAnalytics logEventWithName:kFIREventSelectContent parameters:@{
                                                                                   kFIRParameterContentType:@"settings",
                                                                                   kFIRParameterItemID:@"btn_buy"
                                                                                   }];
                
                [[InAppPurchase sharedManager] paymentRequestWithProductIdentifiers:[[NSArray alloc]initWithObjects:ITEM_1_ID, nil]];
            } else {
                [self alertPaymentError];
            }
            break;
        case MENU_SUPPORT_RESTORE_UPGRADE:
            
            if ([SKPaymentQueue canMakePayments]) {
                [_spinner startAnimating];
                
                [FIRAnalytics logEventWithName:kFIREventSelectContent parameters:@{
                                                                                   kFIRParameterContentType:@"settings",
                                                                                   kFIRParameterItemID:@"btn_restore"
                                                                                   }];
                
                [[InAppPurchase sharedManager] restoreProduct];
            } else {
                [self alertPaymentError];
            }
            break;
        case MENU_SUPPORT_FEEDBACK:
            [self feedback];
            [FIRAnalytics logEventWithName:kFIREventSelectContent parameters:@{
                                                                               kFIRParameterContentType:@"settings",
                                                                               kFIRParameterItemID:@"btn_feedback"
                                                                               }];
            break;
        case MENU_SUPPORT_INVITE_FRIENDS:
            [self inviteFriend];
            [FIRAnalytics logEventWithName:kFIREventSelectContent parameters:@{
                                                                               kFIRParameterContentType:@"settings",
                                                                               kFIRParameterItemID:@"btn_invite_friend"
                                                                               }];
            break;
        case MENU_SUPPORT_REVIEWS:
            [self goReview];
            [FIRAnalytics logEventWithName:kFIREventSelectContent parameters:@{
                                                                               kFIRParameterContentType:@"settings",
                                                                               kFIRParameterItemID:@"btn_go_review"
                                                                               }];

            break;
        default:
            break;
    }
}

- (void) feedback {
    
    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        
        UIDevice *device = [UIDevice currentDevice];
        
        NSString *deviceName = [self platform];
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        NSString *systemVersion = device.systemVersion;
        
        NSString *emailSubject = [NSString stringWithFormat:@"[%@] %@", [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"], NSLocalizedString(@"Support & Feedback",nil)];
        NSString *emailBody = [NSString stringWithFormat:@"\n\n------------\n%@\n- App Version : %@\n- Device : %@\n- OS : %@\n- UID : %@", NSLocalizedString(@"don't delete following information for supporting.",nil), appVersion, deviceName, systemVersion, [FIRAuth auth].currentUser.uid];
        
        [composeViewController setToRecipients:@[@"help@neosave.me"]];
        [composeViewController setSubject:emailSubject];
        [composeViewController setMessageBody:emailBody isHTML:NO];
        
        [self presentViewController:composeViewController animated:YES completion:nil];
    }
}


- (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    UIAlertView *alert;
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSent:
            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Feedback",nil)
                                                            message:NSLocalizedString(@"Thank you for your feedback.",nil)
                                                           delegate:self
                                                  cancelButtonTitle:@"Done" otherButtonTitles:nil];
            
            [alert show];
            
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            
            alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Feedback",nil)
                                                            message:NSLocalizedString(@"failed sending feeback",nil)
                                                           delegate:self
                                                  cancelButtonTitle:@"Done" otherButtonTitles:nil];
            
            [alert show];
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) goReview {
    UIAlertController * alert =   [UIAlertController
                                   alertControllerWithTitle:NSLocalizedString(@"Reviews",nil)
                                   message:NSLocalizedString(@"Please review this app in the Appstore.",nil)
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* later = [UIAlertAction
                            actionWithTitle:NSLocalizedString(@"Later",nil)
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action)
                            {
                                [alert dismissViewControllerAnimated:YES completion:nil];
                            }];
    
    UIAlertAction* confirm = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Review",nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                  NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1211559544&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"];
                                  [[UIApplication sharedApplication] openURL:url];
                                  
                              }];
    
    [alert addAction:later];
    [alert addAction:confirm];
    
    [self presentViewController:alert animated:YES completion:nil];
}
@end

