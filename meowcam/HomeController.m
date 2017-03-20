//
//  HomeController.m
//  meowcam
//
//  Created by 1100003 on 2017. 2. 27..
//  Copyright © 2017년 neosave. All rights reserved.
//

#import "HomeController.h"
#import "PhotoController.h"
#import "HBFocusUtils.h"
#import "ImageUtils.h"
#import "GPUImageView.h"
#import "CameraFocusSquare.h"
@import Firebase;

#define DEFAULT_BURST_COUNT 10

#define IS_SAMPLE NO

@interface HomeController () <UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnTakePhoto;
@property (strong, nonatomic) IBOutlet GPUImageView *vImagePreview;
@property (strong, nonatomic) IBOutlet UITextField *txtSoundName;

@property (strong, nonatomic) IBOutlet UIButton *btnPlay;
@property (strong, nonatomic) IBOutlet UIButton *btnPrev;
@property (strong, nonatomic) IBOutlet UIButton *btnNext;

@property (nonatomic, strong) UIPickerView *songPickerView;

@property(nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (assign) int iFrameCount;
@property(nonatomic, retain) AVCaptureDeviceInput *input;
@property(nonatomic, retain) AVCaptureDevice *device;

@property (nonatomic, retain) NSMutableArray *photos;
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;
@property (nonatomic, retain) NSArray *meowSounds;
@property (nonatomic, retain) NSArray *meowSoundNames;
@property (nonatomic, assign) NSInteger nowSoundIndex;

@property (nonatomic, retain) CameraFocusSquare *focusSquare;
@property (nonatomic, retain) AVCaptureSession *session;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) FIRRemoteConfig *remoteConfig;
@property (assign) Boolean isUpdate;
@property (assign) Boolean noAutoPlay;

@property (assign) Boolean isCapturing;

@end

@implementation HomeController
NSString *const kIsUpdateConfigKey = @"is_update";

@synthesize audioPlayer;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"viewWillAppear");
    
    [self initCamera];
    
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    [_photos removeAllObjects];
    [_btnTakePhoto setEnabled:YES];
    
    AVCaptureDevice *camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    int flags = NSKeyValueObservingOptionNew;
    
    [camDevice addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    AVCaptureDevice *camDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [camDevice removeObserver:self forKeyPath:@"adjustingFocus"];
}


#pragma mark - focus observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString:@"adjustingFocus"] )
    {
        BOOL adjustingFocus = [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
        if (adjustingFocus)
        {
            //           포커스 맞추는 중
            NSLog(@"focusing");
        }
        else
        {
            //            포커스를 맞추고 있지 않는상태 (포커스가 맞춰진 상태)
            NSLog(@"focused");
            if (_focusSquare) {
                [_focusSquare.layer removeAllAnimations];
                [_focusSquare removeFromSuperview];
                _focusSquare = nil;
            }
        }
    }
}

- (void) becomeActive {
    NSLog(@"becomeActive");
    [self initCamera];
}

- (void) becomeDeactive {
    NSLog(@"becomeDective");
    [self stop];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // [START get_remote_config_instance]
    self.remoteConfig = [FIRRemoteConfig remoteConfig];
    // [END get_remote_config_instance]
    
    // Create Remote Config Setting to enable developer mode.
    // Fetching configs from the server is normally limited to 5 requests per hour.
    // Enabling developer mode allows many more requests to be made per hour, so developers
    // can test different config values during development.
    // [START enable_dev_mode]
    
    Boolean devMode = NO;
    
#ifdef DEBUG
    devMode = YES;
    NSLog(@"DEBUG devMode : %d", devMode);
#endif
    
    FIRRemoteConfigSettings *remoteConfigSettings = [[FIRRemoteConfigSettings alloc] initWithDeveloperModeEnabled:devMode];
    self.remoteConfig.configSettings = remoteConfigSettings;
    // [END enable_dev_mode]
    
    // Set default Remote Config values. In general you should have in-app defaults for all
    // values that you may configure using Remote Config later on. The idea is that you
    // use the in-app defaults and when you need to adjust those defaults, you set an updated
    // value in the App Manager console. The next time that your application fetches values
    // from the server, the new values you set in the Firebase console are cached. After you
    // activate these values, they are used in your app instead of the in-app defaults. You
    // can set default values using a plist file, as shown here, or you can set defaults
    // inline by using one of the other setDefaults methods.
    // [START set_default_values]
    [self.remoteConfig setDefaultsFromPlistFileName:@"RemoteConfigDefaults"];
    
    
    // init uid
    _uid = @"";
    
    [[FIRAuth auth]
     signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user, NSError *_Nullable error) {
         // ...
         _uid = user.uid;
         NSLog(@"signInAnonymouslyWithCompletion uid : @%@", user.uid);
         
         [self fetchConfig];
     }];

    [self checkCameraPermission];
    
    _meowSounds = [[NSArray alloc] initWithObjects: @"meow-01",
               @"meow-02",
               @"meow-03",
               @"meow-04",
               @"meow-05",
               @"meow-06",
                   @"meow-07",
                   @"meow-08",
                   @"meow-09",
                   @"meow-10",
                   @"meow-11",
                   @"meow-12",
                   @"meow-13",
                   @"meow-14",
                   @"meow-15",
                   @"meow-16",
                   @"meow-17",
                   @"meow-18",
                   @"meow-19",
                   @"meow-20",
                   @"meow-21",
                   @"meow-22",
                   @"meow-23",
                   @"meow-24",
                   @"meow-25",
                   @"meow-26",
                   @"meow-27",
                   @"meow-28",
                   @"meow-29",
               @"purr-01",
                   @"purr-02",
                   @"purr-03",
                   @"purr-04",
                   @"purr-05",
                   @"purr-06",
                   @"purr-07",
               @"song-01",
                   @"song-02",
               nil];
    
    _meowSoundNames = [[NSArray alloc] initWithObjects: NSLocalizedString(@"meow-01",nil),
                   NSLocalizedString(@"meow-02",nil),
                   NSLocalizedString(@"meow-03",nil),
                   NSLocalizedString(@"meow-04",nil),
                   NSLocalizedString(@"meow-05",nil),
                   NSLocalizedString(@"meow-06",nil),
                       NSLocalizedString(@"meow-07",nil),
                       NSLocalizedString(@"meow-08",nil),
                       NSLocalizedString(@"meow-09",nil),
                       NSLocalizedString(@"meow-10",nil),
                       NSLocalizedString(@"meow-11",nil),
                       NSLocalizedString(@"meow-12",nil),
                       NSLocalizedString(@"meow-13",nil),
                       NSLocalizedString(@"meow-14",nil),
                       NSLocalizedString(@"meow-15",nil),
                       NSLocalizedString(@"meow-16",nil),
                       NSLocalizedString(@"meow-17",nil),
                       NSLocalizedString(@"meow-18",nil),
                       NSLocalizedString(@"meow-19",nil),
                       NSLocalizedString(@"meow-20",nil),
                       NSLocalizedString(@"meow-21",nil),
                       NSLocalizedString(@"meow-22",nil),
                       NSLocalizedString(@"meow-23",nil),
                       NSLocalizedString(@"meow-24",nil),
                       NSLocalizedString(@"meow-25",nil),
                       NSLocalizedString(@"meow-26",nil),
                       NSLocalizedString(@"meow-27",nil),
                       NSLocalizedString(@"meow-28",nil),
                       NSLocalizedString(@"meow-29",nil),
                       
                   NSLocalizedString(@"purr-01",nil),
                       NSLocalizedString(@"purr-02",nil),
                       NSLocalizedString(@"purr-03",nil),
                       NSLocalizedString(@"purr-04",nil),
                       NSLocalizedString(@"purr-05",nil),
                       NSLocalizedString(@"purr-06",nil),
                       NSLocalizedString(@"purr-07",nil),
                   NSLocalizedString(@"song-01",nil),
                       NSLocalizedString(@"song-02",nil),
                   nil];
    
    _photos = [[NSMutableArray alloc]init];
    
    
    // Initialize picker view
    _songPickerView = [[UIPickerView alloc] init];
    
    _songPickerView.dataSource = self;
    _songPickerView.delegate = self;
    
    _txtSoundName.inputView = _songPickerView;
    
    UIToolbar *toolBar= [[UIToolbar alloc] initWithFrame:CGRectMake(0,0,320,44)];
    [toolBar setBarStyle:UIBarStyleBlackOpaque];
    [toolBar setTintColor:[UIColor whiteColor]];
    
    NSMutableArray *barItems = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pickerCancel:)];
    [barItems addObject:cancelBtn];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [barItems addObject:flexSpace];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pickerDone:)];
    [barItems addObject:doneBtn];
    
    [toolBar setItems:barItems animated:YES];
    
    
    _txtSoundName.inputAccessoryView = toolBar;
    
    
    
    
    UITapGestureRecognizer *shortTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToFocus:)];
    shortTap.numberOfTapsRequired=1;
    shortTap.numberOfTouchesRequired=1;
    [_vImagePreview addGestureRecognizer:shortTap];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    // Adding the swipe gesture on image view
    [_vImagePreview addGestureRecognizer:swipeLeft];
    [_vImagePreview addGestureRecognizer:swipeRight];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(becomeActive)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(becomeDeactive)
                                                name:UIApplicationDidEnterBackgroundNotification
                                         object:nil];
    
    
    // indicator
    _spinner = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_spinner setColor:[UIColor grayColor]];
    _spinner.center = CGPointMake((self.navigationController.view.frame.size.width/2), (self.navigationController.view.frame.size.height/2));
    _spinner.hidesWhenStopped = YES;
    [self.navigationController.view addSubview:_spinner];
    
    [_spinner startAnimating];
    
    
    
    // auto sound
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _noAutoPlay = [defaults boolForKey:@"noAutoPlay"];
    NSLog(@"noAutoPlay : %d", _noAutoPlay);
    
    _nowSoundIndex = [defaults integerForKey:@"lastSoundIndex"];
    NSLog(@"_nowSoundIndex : %ld", _nowSoundIndex);
    
    [_songPickerView selectRow:_nowSoundIndex inComponent:0 animated:YES];
    
    [self setSoundName:[_meowSoundNames objectAtIndex:_nowSoundIndex]];
    
    if(!_noAutoPlay){
        [self play:_nowSoundIndex];
    }
}

-(void)pickerDone:(id)sender
{
    NSLog(@"pickerDone");
    
    NSInteger row = [_songPickerView selectedRowInComponent:0];
    
    if ( [_txtSoundName isFirstResponder] ) {
        
        [self stop];
        [self play:row];
        
        [_txtSoundName resignFirstResponder];
    }
    
    
}


-(void)pickerCancel:(id)sender
{
    NSLog(@"pickerCancel");
    [_txtSoundName resignFirstResponder];
}


// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _meowSoundNames.count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *soundName = (NSString*)[_meowSoundNames objectAtIndex:row];
    return soundName;
}

// Catpure the picker view selection
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // This method is triggered whenever the user makes a change to the picker selection.
    // The parameter named row and component represents what was selected.
    NSLog(@"row : %ld", row);
}


-(void)dismissPicker:(id)sender{
    [_txtSoundName resignFirstResponder];
}


- (void) fetchConfig {
    
    _uid = [FIRAuth auth].currentUser.uid;
    
    NSLog(@"fetchConfig uid : @%@", _uid);
    
    long expirationDuration = 3600;
    // If in developer mode cacheExpiration is set to 0 so each fetch will retrieve values from
    // the server.
    if (self.remoteConfig.configSettings.isDeveloperModeEnabled) {
        expirationDuration = 0;
    }
    
    // [START fetch_config_with_callback]
    // cacheExpirationSeconds is set to cacheExpiration here, indicating that any previously
    // fetched and cached config would be considered expired because it would have been fetched
    // more than cacheExpiration seconds ago. Thus the next fetch would go to the server unless
    // throttling is in progress. The default expiration duration is 43200 (12 hours).
    [self.remoteConfig fetchWithExpirationDuration:expirationDuration completionHandler:^(FIRRemoteConfigFetchStatus status, NSError *error) {
        if (status == FIRRemoteConfigFetchStatusSuccess) {
            NSLog(@"Config fetched!");
            [self.remoteConfig activateFetched];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"noFirstLoad"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            _isUpdate = self.remoteConfig[kIsUpdateConfigKey].boolValue;
            
            NSLog(@"_isUpdate : %d", _isUpdate);
            
            
            if(_isUpdate){
                [self showUpdateAlert];
            }
            
        } else {
            NSLog(@"Config not fetched");
            NSLog(@"Error %@", error.localizedDescription);
            [self showAlertTempError];
        }
        [_spinner stopAnimating];
    }];
    // [END fetch_config_with_callback]
}

- (void) showAlertTempError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Temporary failure",nil)
                                                    message:NSLocalizedString(@"Please use after a while.",nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Done",nil) otherButtonTitles:nil];
    [alert show];
}

- (void) showUpdateAlert {
    UIAlertController * alert =   [UIAlertController
                                   alertControllerWithTitle:NSLocalizedString(@"Check for Update",nil)
                                   message:NSLocalizedString(@"Please update to the latest version.",nil)
                                   preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction* later = [UIAlertAction
                            actionWithTitle:NSLocalizedString(@"Later",nil)
                            style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction * action)
                            {
                                [alert dismissViewControllerAnimated:YES completion:nil];
                            }];
    UIAlertAction* update = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Update",nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                                 [FIRAnalytics logEventWithName:kFIREventSelectContent parameters:@{
                                                                                                    kFIRParameterContentType:@"home",
                                                                                                    kFIRParameterItemID:@"alert_app_update"
                                                                                                    }];
                                 
                                 NSString *iTunesLink = @"https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=1211559544&mt=8";
                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
                                 
                             }];
    [alert addAction:later];
    [alert addAction:update];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)handleTapToFocus:(UITapGestureRecognizer *)tgr
{
    NSLog(@"shortTap");
    
    
    AVCaptureInput *currentCameraInput = [_session.inputs objectAtIndex:0];
    
    CGPoint tapPoint = [tgr locationInView:_vImagePreview];
    
    // animation
    if (_focusSquare) {
        [_focusSquare.layer removeAllAnimations];
        [_focusSquare removeFromSuperview];
        _focusSquare = nil;
    }
    
    _focusSquare = [[CameraFocusSquare alloc] initWithTouchPoint:tapPoint];
    [_vImagePreview addSubview:_focusSquare];
    [_focusSquare setNeedsDisplay];
    [_focusSquare animateFocusingAction];
    
    // make focus
    CGPoint pointOfInterest = [HBFocusUtils convertToPointOfInterestFromViewCoordinates:tapPoint inFrame:_vImagePreview.bounds withOrientation:[[UIDevice currentDevice] orientation] andFillMode:kGPUImageFillModePreserveAspectRatioAndFill mirrored:((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionFront];
    
    [HBFocusUtils setFocus:pointOfInterest forDevice:_device];
}


- (IBAction)toggleSound:(id)sender {
    
    if([audioPlayer isPlaying]){
        [self stop];
    } else {
        
        [self play:_nowSoundIndex];
    }
    
}

- (IBAction)prevSound:(id)sender {
    
     [self stop];
    
    if(_nowSoundIndex <= 0){
        _nowSoundIndex = [_meowSounds count]-1;
    } else {
        _nowSoundIndex--;
    }
    
    [self play:_nowSoundIndex];
}

- (IBAction)nextSound:(id)sender {
    
     [self stop];
    
    if(_nowSoundIndex >= [_meowSounds count]-1){
        _nowSoundIndex = 0;
    } else {
        _nowSoundIndex++;
    }
    
    [self play:_nowSoundIndex];
}

- (void) pause {
    [audioPlayer pause];
    
    [_btnPlay setImage:[UIImage imageNamed:@"btn-play"] forState:UIControlStateNormal];
}

- (void) stop {
    [audioPlayer stop];
    [_btnPlay setImage:[UIImage imageNamed:@"btn-play"] forState:UIControlStateNormal];
}

- (void) play : (NSInteger) soundIndex {
    
    
    if([audioPlayer isPlaying]){
        return;
    }
    
    // save last sound index
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:soundIndex forKey:@"lastSoundIndex"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [_btnPlay setImage:[UIImage imageNamed:@"btn-pause"] forState:UIControlStateNormal];
    NSString *fileName = [(NSArray*)_meowSounds objectAtIndex:soundIndex];
    
    [self setSoundName:[_meowSoundNames objectAtIndex:soundIndex]];
    
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:fileName ofType: @"mp3"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath ];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    audioPlayer.numberOfLoops = -1; //infinite loop
    [audioPlayer play];
}


- (void) setSoundName : (NSString*) soundName {
//    _txtSoundName.text = [NSString stringWithFormat:@"%@ %@", @"🐱", soundName];
    _txtSoundName.text = soundName;
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    
    [self stop];
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        NSLog(@"Left Swipe");
        [self nextSound:nil];
    }
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        NSLog(@"Right Swipe");
        [self prevSound:nil];
    }
    
}

// make sure you have this method in your class
//
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
            return device;
    }
    return nil;
}

- (void) initCamera{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Boolean noFirstLoad = [defaults boolForKey:@"noFirstLoad"];
    
    if(noFirstLoad){
        if(![self checkCameraPermission]){
            
            //microphone access unavailable
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera Permission",nil)
                                                            message:NSLocalizedString(@"Please allow Camera access for capturing.\nSettings-Privacy-Camera",nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Done",nil) otherButtonTitles:nil];
            [alert show];
            
            return;
        }
    }
    /////////////////////////////////////////////////////////////////////////////
    // Create a preview layer that has a capture session attached to it.
    // Stick this preview layer into our UIView.
    /////////////////////////////////////////////////////////////////////////////
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    CALayer *viewLayer = self.vImagePreview.layer;
    NSLog(@"viewLayer = %@", viewLayer);
    
    
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    
    //    captureVideoPreviewLayer.frame = self.vImagePreview.bounds;
    
    NSLog(@"w : %f, h : %f", self.vImagePreview.bounds.size.width, self.vImagePreview.bounds.size.height);
    
    CGRect bounds = self.vImagePreview.bounds;
    
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone) {
        bounds = CGRectMake(self.vImagePreview.bounds.origin.x, self.vImagePreview.bounds.origin.y, 528.0f, 704.0f);
    }
    
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    captureVideoPreviewLayer.bounds = bounds;
    captureVideoPreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    
    [self.vImagePreview.layer addSublayer:captureVideoPreviewLayer];
    
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    
    if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] && [_device lockForConfiguration:&error]){
        [_device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        if ([_device isFocusPointOfInterestSupported])
            [_device setFocusPointOfInterest:CGPointMake(0.5f,0.5f)];
        [_device unlockForConfiguration];
    } else {
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    
    error = nil;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (!_input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    [_session addInput:_input];
    
    
    /////////////////////////////////////////////////////////////
    // OUTPUT #1: Still Image
    /////////////////////////////////////////////////////////////
    // Add an output object to our session so we can get a still image
    // We retain a handle to the still image output and use this when we capture an image.
    _stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [_stillImageOutput setOutputSettings:outputSettings];
    [_session addOutput:_stillImageOutput];
    
    
    /////////////////////////////////////////////////////////////
    // OUTPUT #2: Video Frames
    /////////////////////////////////////////////////////////////
    // Create Video Frame Outlet that will send each frame to our delegate
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    captureOutput.alwaysDiscardsLateVideoFrames = YES;
    //	captureOutput.minFrameDuration = CMTimeMake(1, 3); // deprecated in IOS5
    
    // We need to create a queue to funnel the frames to our delegate
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [captureOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    // Set the video output to store frame in BGRA (It is supposed to be faster)
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    // let's try some different keys,
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [captureOutput setVideoSettings:videoSettings];
    
    [_session addOutput:captureOutput];
    /////////////////////////////////////////////////////////////
    
    
    // start the capture session
    [_session startRunning];
    
    /////////////////////////////////////////////////////////////////////////////
    
    // initialize frame counter
    _iFrameCount = 0;
    _isCapturing = NO;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showPhoto"]) {
    
        NSLog(@"prepareForSegue");
        PhotoController *destViewController = segue.destinationViewController;
        destViewController.photos = _photos;
        
    }
}

- (Boolean) checkCameraPermission {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Boolean isCameraGranted = [defaults boolForKey:@"isCameraGranted"];
    
    if(!isCameraGranted ){
        
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            [defaults setBool:granted forKey:@"isCameraGranted"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
    }
    
    isCameraGranted = [defaults boolForKey:@"isCameraGranted"];
    
    return isCameraGranted;
}

- (IBAction)changeCamera:(id)sender {
    NSLog(@"change camera");
    

    [_session beginConfiguration];
    
    AVCaptureInput *currentCameraInput = [_session.inputs objectAtIndex:0];
    
    [_session removeInput:currentCameraInput];
    
    AVCaptureDevice *newCamera = nil;
    
    if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
    {
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
    }
    else
    {
        newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
    }
    
    NSError *err = nil;
    
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
    
    if(!newVideoInput || err)
    {
        NSLog(@"Error creating capture device input: %@", err.localizedDescription);
    }
    else
    {
        [_session addInput:newVideoInput];
    }
    
    [_session commitConfiguration];
    
}

- (IBAction)showSetting:(id)sender {
    NSLog(@"show setting");
}

- (IBAction)takePhoto:(id)sender {
    NSLog(@"takePhoto");
    
    [self stop];
    [_btnTakePhoto setEnabled:NO];
    
    _isCapturing = YES;
    
    
    /*
    for(int i=0;i<DEFAULT_BURST_COUNT;i++){
        [self capture:i];
    }
     */
}


- (CGImageRef) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    CGContextRelease(newContext);
    
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    /* CVBufferRelease(imageBuffer); */  // do not call this!
    
    return newImage;
}

/////////////////////////////////////////////////////////////////////
#pragma mark - Video Frame Delegate
/////////////////////////////////////////////////////////////////////
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    if(_isCapturing){
        
        if(_iFrameCount == 0){
//            [audioPlayer stop];
//            [self stop];
            
            NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"camera-shutter" ofType: @"mp3"];
            NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath ];
            audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
            audioPlayer.numberOfLoops = 0; //infinite loop
            [audioPlayer play];

            
            /*
            static SystemSoundID soundID = 0;
            if (soundID == 0) {
                NSString *path = [[NSBundle mainBundle] pathForResource:@"meow-28" ofType:@"mp3"];
                NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
                AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
            }
            AudioServicesPlaySystemSound(soundID);
             */
        }
        
        [self addCapturedImage:sampleBuffer];
        _iFrameCount++;
        NSLog(@"frame count %d", _iFrameCount);
        if(_iFrameCount == DEFAULT_BURST_COUNT){
            _iFrameCount = 0;
            _isCapturing = NO;
            
            [self performSelectorOnMainThread: @selector(move) withObject:nil waitUntilDone:YES];
        }
        
    }
}

- (void) addCapturedImage : (CMSampleBufferRef)sampleBuffer {
    CGImageRef cgImage = [self imageFromSampleBuffer:sampleBuffer];
    UIImage *image =     [UIImage imageWithCGImage: cgImage ];
    CGImageRelease( cgImage );
    
    if(IS_SAMPLE){
        image = [UIImage imageNamed:@"jj_sample"];
    }
    
    NSLog(@"w: %f, h:%f", image.size.width, image.size.height);
    
    UIImage *cropeddImage = [ImageUtils imageByCroppingImage:image toSize: CGSizeMake(lroundf(image.size.height*1.33333), image.size.height)];
    
    NSLog(@"w: %f, h:%f", cropeddImage.size.width, cropeddImage.size.height);
    
   
    UIImage *rotatedImage = [[UIImage alloc] initWithCGImage:cropeddImage.CGImage
                                                       scale: 1.0
                                                 orientation: UIImageOrientationRight];
    [_photos addObject: rotatedImage];
    
//    [_photos addObject: cropeddImage];
}





- (void) move {
    [self performSegueWithIdentifier: @"showPhoto" sender: self];
}


- (void) capture: (int) count {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    if(count==0){
        
        NSLog(@"count 0");
        
        static SystemSoundID soundID = 0;
        if (soundID == 0) {
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"meow-07" ofType:@"mp3"];
            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &soundID);
        }
        AudioServicesPlaySystemSound(soundID);
    }
    
    NSLog(@"about to request a capture from: %@", _stillImageOutput);
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         CFDictionaryRef exifAttachments = CMGetAttachment( imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
         if (exifAttachments)
         {
             // Do something with the attachments.
             NSLog(@"attachements: %@", exifAttachments);
         }
         else
             NSLog(@"no attachments");
         
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
         UIImage *image = [[UIImage alloc] initWithData:imageData];
         
         [_photos addObject:image];
         
         if(count == (DEFAULT_BURST_COUNT-1)){
             [self stop];
             
             [self performSegueWithIdentifier: @"showPhoto" sender: self];
         }
         
         /*
         if(count == 0)
             self.vImage.image = image;
         else if(count == 1)
             self.vImage2.image = image;
         else if(count == 2)
             self.vImage3.image = image;
         */
     }];
}

- (IBAction)showSettings:(id)sender {
    NSLog(@"showSettings");
}



- (IBAction)togglePlay:(id)sender {
    NSLog(@"togglePlay");
    
    if([audioPlayer isPlaying]){
        [self stop];
    } else {
        
        [self play:_nowSoundIndex];
    }
    
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
