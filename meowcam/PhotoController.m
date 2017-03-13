//
//  PhotoController.m
//  meowcam
//
//  Created by 1100003 on 2017. 2. 27..
//  Copyright © 2017년 neosave. All rights reserved.
//

#import "PhotoController.h"
@import Firebase;
@import GoogleMobileAds;
#import "InAppPurchase.h"

#define THUMB_IMAGE_SIZE 70.0f
#define ITEM_1_ID @"me.neosave.meowcam.item01"

@interface PhotoController () <UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UIButton *btnUpgrade;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property(nonatomic, strong) GADInterstitial *interstitial;
@property (assign) Boolean isPaid;
@property (nonatomic, strong) FIRDatabaseReference *ref;

@end

@implementation PhotoController

- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial =
    [[GADInterstitial alloc] initWithAdUnitID:@"ca-app-pub-8184020611985232/4357469109"];
    interstitial.delegate = self;
    
    GADRequest *request = [GADRequest request];
    // Request test ads on devices you specify. Your test device ID is printed to the console when
    // an ad request is made.
    request.testDevices = @[ kGADSimulatorID, @"3640560a43cefa8528943c9bcd3307c785234636" ];
    
    [interstitial loadRequest:[GADRequest request]];
    return interstitial;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitial = [self createAndLoadInterstitial];
    
    NSLog(@"interstitialDidDismissScreen");
    [self showAlertForUpgrade];
}


- (void) showAlertForUpgrade {
    UIAlertController * alert =   [UIAlertController
                                   alertControllerWithTitle:NSLocalizedString(@"Upgrade",nil)
                                   message:NSLocalizedString(@"Please buy upgrade pack and use without Ads.",nil)
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* later = [UIAlertAction
                            actionWithTitle:NSLocalizedString(@"Later",nil)
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action)
                            {
                                [alert dismissViewControllerAnimated:YES completion:nil];
                            }];
    
    UIAlertAction* confirm = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Buy",nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                  [self upgrade:nil];
                              }];
    
    [alert addAction:later];
    [alert addAction:confirm];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) showAlertForComplete {
    UIAlertController * alert =   [UIAlertController
                                   alertControllerWithTitle:NSLocalizedString(@"Complete",nil)
                                   message:NSLocalizedString(@"Selected photo sent.",nil)
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* confirm = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Confirm",nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                  
                                  if (self.interstitial.isReady) {
                                      
                                      if(!_isPaid){
                                          NSLog(@"Show Ad");
                                          [self.interstitial presentFromRootViewController:self];
                                      }
                                      
                                  } else {
                                      NSLog(@"Ad wasn't ready");
                                  }
                                  
                              }];
    
    [alert addAction:confirm];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:@"InAppPurchasedNotification" object:nil];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _isPaid = [defaults boolForKey:ITEM_1_ID];
    
    if(_isPaid){
       _btnUpgrade.hidden = YES;
    }
}
- (IBAction)upgrade:(id)sender {
    NSLog(@"upgrade");
    if ([SKPaymentQueue canMakePayments]) {
        [_spinner startAnimating];
        
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent parameters:@{
                                                                           kFIRParameterContentType:@"photo",
                                                                           kFIRParameterItemID:@"upgrade"
                                                                           }];
        
        [[InAppPurchase sharedManager] paymentRequestWithProductIdentifiers:[[NSArray alloc]initWithObjects:ITEM_1_ID, nil]];
    } else {
        [self alertPaymentError];
    }
}

- (void) alertPaymentError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Payment Error",nil)
                                                    message:NSLocalizedString(@"You are not authorized to purchase from AppStore.",nil)
                                                   delegate:self
                                          cancelButtonTitle:@"Done" otherButtonTitles:nil];
    [alert show];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_spinner stopAnimating];
//    [_photos removeAllObjects];
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
    NSLog(@"productIdentifier : %@", productIdentifier);
    NSLog(@"transactionIdentifier : %@", transactionIdentifier);
    
    if([mode isEqualToString:@"error"]){
        return;
    }
    
    if([productIdentifier isEqualToString:ITEM_1_ID]){
        
        // update purchase info
        _ref = [[FIRDatabase database] reference];
        NSDictionary *purchase = @{@"uid": uId,
                                   @"pid": productIdentifier,
                                   @"tid": transactionIdentifier,
                                   @"date": transactionDate};
        
        NSDictionary *updates = @{[@"/purchases/" stringByAppendingString:transactionIdentifier]: purchase};
        [_ref updateChildValues:updates];
        
        if([mode isEqualToString:@"buy"]){
            
            // init paid
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            _isPaid = [defaults boolForKey:ITEM_1_ID];
            _btnUpgrade.hidden = YES;
        }
    }
}

- (IBAction)selectPhoto:(id)sender {
    
    NSLog(@"select photo");
    
    UIImage *imageToShare = _primaryImageView.image;
    NSArray *objectsToShare = @[imageToShare];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    
    NSArray *excludeActivities = @[
                                   UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeCopyToPasteboard,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToVimeo
                                   ];
    
    activityVC.excludedActivityTypes = excludeActivities;
   
    
    //if iPhone
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:activityVC animated:YES completion:nil];
    }
    //if iPad
    else {
        // Change Rect to position Popover
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:activityVC];
        [popup presentPopoverFromRect:CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/4, 0, 0)inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    
//    [self presentViewController:activityVC animated:YES completion:nil];
    
    activityVC.completionWithItemsHandler = ^(NSString *activityType,
                                   BOOL completed,
                                   NSArray *returnedItems,
                                   NSError *error){
        // react to the completion
        if (completed) {
            
            // user shared an item
            NSLog(@"We used activity type%@", activityType);
            
            [self showAlertForComplete];
            
        } else {
            
            // user cancelled
            NSLog(@"We didn't want to share anything after all.");
            
            if (self.interstitial.isReady) {
                
                if(!_isPaid){
                    NSLog(@"Show Ad");
                    [self.interstitial presentFromRootViewController:self];
                }
                
            } else {
                NSLog(@"Ad wasn't ready");
            }
        }
        
        if (error) {
            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
        }
        
        
    };
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // init paid
    _isPaid = [defaults boolForKey:ITEM_1_ID];
    if(_isPaid){
        _btnUpgrade.hidden = YES;
    } else {
        _interstitial = [self createAndLoadInterstitial];
    }
    
    NSUInteger photoCount = [_photos count];
    
    NSLog(@"photos count : %ld", photoCount);
    
    _primaryImageView.image = (UIImage*) [_photos objectAtIndex:0];
    
    float xPostion = 0.0f;
    
    for(int i=0; i < photoCount; i++){
        
        xPostion = i * (THUMB_IMAGE_SIZE + 6.0f);

        UIButton *btnThumbImage = [UIButton buttonWithType:UIButtonTypeCustom];
        btnThumbImage.frame = CGRectMake(xPostion, 0, THUMB_IMAGE_SIZE, THUMB_IMAGE_SIZE);
        
        [btnThumbImage setImage:(UIImage*) [_photos objectAtIndex:i] forState:UIControlStateNormal];
        btnThumbImage.tag = 100+i;
        [[btnThumbImage layer] setBorderColor:[UIColor colorWithRed:246.0f/255.0f green:49.0f/255.0f blue:140.0f/255.0f alpha:1.0f].CGColor];
        
        btnThumbImage.layer.cornerRadius = 6;
        btnThumbImage.clipsToBounds = YES;
        
        
        if(i == 0){
            [[btnThumbImage layer] setBorderWidth:3.0f];
        } else {
            [[btnThumbImage layer] setBorderWidth:0.0f];
        }
        
        [_photoScrollView addSubview: btnThumbImage];
    
        [btnThumbImage addTarget:self action:@selector(tapThumbImage:) forControlEvents: UIControlEventTouchUpInside];
        
    }
    [_photoScrollView setContentSize:CGSizeMake((THUMB_IMAGE_SIZE + 6.0f) * photoCount, THUMB_IMAGE_SIZE)];
    
    // indicator
    _spinner = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_spinner setColor:[UIColor grayColor]];
    _spinner.center = CGPointMake((self.navigationController.view.frame.size.width/2), (self.navigationController.view.frame.size.height/2));
    _spinner.hidesWhenStopped = YES;
    [self.navigationController.view addSubview:_spinner];
}

- (void)tapThumbImage:(id)sender
{
    NSUInteger photoCount = [_photos count];
    
    for(int i=0; i < photoCount; i++){
        UIButton *btnThumbImage = (UIButton *)[_photoScrollView viewWithTag:(i+100)];
        [[btnThumbImage layer] setBorderWidth:0.0f];
    }
    
    UIButton* button = (UIButton*)sender;
    [[button layer] setBorderWidth:3.0f];
    NSLog(@"%ld", button.tag);
    _primaryImageView.image = (UIImage*) [_photos objectAtIndex:(button.tag - 100)];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
