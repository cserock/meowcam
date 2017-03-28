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
#import "ImageUtils.h"

#define THUMB_IMAGE_SIZE 70.0f
#define ITEM_1_ID @"me.neosave.meowcam.item01"

#define FILTER_NORMAL 1000
#define FILTER_MISSETIKATE 1001
#define FILTER_AMATORKA 1002
#define FILTER_GRAYSCALE 1003
#define FILTER_VIGNETTE 1004
#define FILTER_GAUSSIAN_SELECTIVE 1005
#define FILTER_WHITE_BALANCE 1006

//GPUIMAGE_VIGNETTE
//GPUIMAGE_GAUSSIAN_SELECTIVE
//GPUIMAGE_GRAYSCALE

@interface PhotoController () <UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UIButton *btnUpgrade;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property(nonatomic, strong) GADInterstitial *interstitial;
@property (assign) Boolean isPaid;
@property (nonatomic, strong) FIRDatabaseReference *ref;
@property (strong, nonatomic) IBOutlet UISlider *filterSlider;
@property (assign) NSInteger filterType;

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

- (IBAction)adjustFilter:(id)sender {
    NSLog(@"%f", [(UISlider *)sender value]);
    
    switch (_filterType) {
        case FILTER_VIGNETTE :
            [(GPUImageVignetteFilter *)_firstFilter setVignetteEnd:[(UISlider *)sender value]];
            break;
        case FILTER_GAUSSIAN_SELECTIVE :
            [(GPUImageGaussianSelectiveBlurFilter *)_firstFilter setExcludeCircleRadius:[(UISlider *)sender value]];
            break;
        case FILTER_WHITE_BALANCE :
            [(GPUImageWhiteBalanceFilter *)_firstFilter setTemperature:[(UISlider *)sender value]];
            break;
        default: break;
    }
    
    [_sourcePicture processImage];
}

- (void) resetFilterButton {
    for(int i=0; i < 8; i++){
        UIButton *btnfilter = (UIButton *)[self.view viewWithTag:(i+1000)];
        
        [[btnfilter layer] setBorderColor:[UIColor whiteColor].CGColor];
        
        btnfilter.layer.cornerRadius = 1;
        btnfilter.clipsToBounds = YES;
        btnfilter.backgroundColor = [UIColor clearColor];
        
        [[btnfilter layer] setBorderWidth:1.0f];
    }
}

- (void) selectedFilterButton {
    
    UIButton *btnfilter = (UIButton *)[self.view viewWithTag:_filterType];
    //    btnfilter.backgroundColor = [UIColor colorWithRed:1.00 green:0.95 blue:0.75 alpha:0.5];
    
    [[btnfilter layer] setBorderColor:[UIColor colorWithRed:1.00 green:0.95 blue:0.75 alpha:1.0].CGColor];
    
    btnfilter.backgroundColor = [UIColor colorWithRed:0.62 green:0.93 blue:0.80 alpha:0.6];
    
    
}

- (void) initFilterButton {
    [self resetFilterButton];
    [self selectedFilterButton];
}

- (IBAction)tapFilter:(id)sender {
    
    
    
    
    UIButton *button = sender;
    _filterType = button.tag;
    
    [self resetFilter];
    [self selectedFilterButton];
    
    NSLog(@"%ld", _filterType);
    
    if(_filterType == FILTER_NORMAL){
        return;
    }
    
    _filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, _primaryImageView.frame.size.width, _primaryImageView.frame.size.height)];
    
    [_primaryImageView addSubview:_filterView];
    
    [_filterView setInputRotation:kGPUImageRotateRight atIndex:0];
    
    _sourcePicture = [[GPUImagePicture alloc] initWithImage:_primaryImageView.image smoothlyScaleOutput:YES];

    switch (_filterType) {
        case FILTER_AMATORKA :
            _firstFilter = [[GPUImageAmatorkaFilter alloc] init];
            break;
        case FILTER_MISSETIKATE :
            _firstFilter = [[GPUImageMissEtikateFilter alloc] init];
            break;
        case FILTER_GRAYSCALE :
            _firstFilter = [[GPUImageGrayscaleFilter alloc] init];
            break;
            
        case FILTER_VIGNETTE :
            _filterSlider.hidden = NO;
            
            [_filterSlider setMinimumValue:0.5];
            [_filterSlider setMaximumValue:0.9];
            [_filterSlider setValue:0.75];
            _firstFilter = [[GPUImageVignetteFilter alloc] init];
            [(GPUImageVignetteFilter *)_firstFilter setVignetteEnd:0.75f];
            break;
        case FILTER_GAUSSIAN_SELECTIVE :
            _filterSlider.hidden = NO;
            
            [_filterSlider setMinimumValue:0.0f];
            [_filterSlider setMaximumValue:0.75f];
            [_filterSlider setValue:40.0/320.0];
            _firstFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            
            [(GPUImageGaussianSelectiveBlurFilter *)_firstFilter setExcludeCircleRadius:40.0/320.0];
            break;

            
        case FILTER_WHITE_BALANCE :
            _filterSlider.hidden = NO;
            
            [_filterSlider setMinimumValue:2500.0f];
            [_filterSlider setMaximumValue:7500.0f];
            [_filterSlider setValue:5000.0];
            _firstFilter = [[GPUImageWhiteBalanceFilter alloc] init];
            
            [(GPUImageWhiteBalanceFilter *)_firstFilter setTemperature:5000.0];
            break;
            
    }

    
    [_sourcePicture addTarget:_firstFilter];
    [_firstFilter addTarget:_filterView];
    
    [_sourcePicture processImage];
    
    
}
- (IBAction)tapFilter_2:(id)sender {
    NSLog(@"filter_2");
    
    [_filterView removeFromSuperview];
    _filterView = nil;
}

- (void) resetFilter {
    
    [self resetFilterButton];
    
    _filterSlider.hidden = YES;
    [_filterView removeFromSuperview];
    _filterView = nil;
    _firstFilter = nil;
    _secondFilter = nil;
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
    
    if(_filterType != FILTER_NORMAL){
        
        switch (_filterType) {
            case FILTER_AMATORKA :
                _firstFilter = [[GPUImageAmatorkaFilter alloc] init];
                break;
            case FILTER_MISSETIKATE :
                _firstFilter = [[GPUImageMissEtikateFilter alloc] init];
                break;
            case FILTER_GRAYSCALE :
                _firstFilter = [[GPUImageGrayscaleFilter alloc] init];
                break;
            case FILTER_VIGNETTE :
                _firstFilter = [[GPUImageVignetteFilter alloc] init];
                [(GPUImageVignetteFilter *)_firstFilter setVignetteEnd:[_filterSlider value]];
                break;
            case FILTER_GAUSSIAN_SELECTIVE :
                _firstFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
                [(GPUImageGaussianSelectiveBlurFilter *)_firstFilter setExcludeCircleRadius:[_filterSlider value]];
                break;
            case FILTER_WHITE_BALANCE :
                _firstFilter = [[GPUImageWhiteBalanceFilter alloc] init];
                [(GPUImageWhiteBalanceFilter *)_firstFilter setTemperature:[_filterSlider value]];
                break;
        }
        
        imageToShare = [_firstFilter imageByFilteringImage:_primaryImageView.image];
    }
    
    
    UIImage *watermarkedImage = nil;
    NSString *myWatermarkText = @"@Meow Camera";
    
    UIGraphicsBeginImageContext(imageToShare.size);
    [imageToShare drawAtPoint: CGPointZero];
    
    // Create text attributes
    NSDictionary *textAttributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:36.0],
                                     NSForegroundColorAttributeName : [UIColor whiteColor]
                                     };
    
    // Create string drawing context
//    NSStringDrawingContext *drawingContext = [[NSStringDrawingContext alloc] init];
//    drawingContext.minimumScaleFactor = 0.5; // Half the font size
    
    [myWatermarkText drawAtPoint: CGPointMake(imageToShare.size.width - 230 - 60, imageToShare.size.height - 60) withAttributes: textAttributes];
    watermarkedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSArray *objectsToShare = @[watermarkedImage];
    
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
    
    _filterType = FILTER_NORMAL;
    [self initFilterButton];
    
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
        
        
        UIImage *cropeddImage = [ImageUtils imageByCroppingImage:(UIImage*) [_photos objectAtIndex:i] toSize: CGSizeMake(THUMB_IMAGE_SIZE, THUMB_IMAGE_SIZE)];
        
        UIImage *rotatedImage = [[UIImage alloc] initWithCGImage:cropeddImage.CGImage
                                                           scale: 1.0
                                                     orientation: UIImageOrientationRight];
        
        
        UIFont * customFont = [UIFont systemFontOfSize:10.0];
        
        UILabel *fromLabel = [[UILabel alloc]initWithFrame:CGRectMake(4, 4, 20, 10)];
        fromLabel.text = [NSString stringWithFormat:@"#%d", i+1];;
        fromLabel.font = customFont;
        fromLabel.numberOfLines = 1;
//        fromLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines; // or UIBaselineAdjustmentAlignCenters, or UIBaselineAdjustmentNone
        fromLabel.adjustsFontSizeToFitWidth = YES;
        fromLabel.adjustsLetterSpacingToFitWidth = YES;
//        fromLabel.minimumScaleFactor = 10.0f/12.0f;
        fromLabel.clipsToBounds = YES;
        fromLabel.backgroundColor = [UIColor clearColor];
        fromLabel.textColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:0.7f];
        fromLabel.textAlignment = NSTextAlignmentLeft;
        [btnThumbImage addSubview:fromLabel];
        

        
//        [btnThumbImage setImage:(UIImage*) [_photos objectAtIndex:i] forState:UIControlStateNormal];
        [btnThumbImage setImage:rotatedImage forState:UIControlStateNormal];
        
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
    
    _filterType = FILTER_NORMAL;
    [self resetFilter];
    [self selectedFilterButton];
    
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
