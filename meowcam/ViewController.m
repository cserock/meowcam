//
//  ViewController.m
//  meowcam
//
//  Created by 1100003 on 2017. 2. 23..
//  Copyright © 2017년 neosave. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HBFocusUtils.h"
#import <MapKit/MKAnnotation.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet GPUImageView *primaryView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnTakePhoto;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnPlayer;
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) IBOutlet UISlider *filterSettingSlider;

@property (strong, nonatomic) NSArray *sounds;
@property (nonatomic, assign) NSInteger nowSoundIndex;

@end

@implementation ViewController

@synthesize audioPlayer;

- (IBAction)updateSliderValue:(id)sender {
    
    float brightnessValue = [(UISlider *)sender value];
    float contastValue = brightnessValue + 1.6f;
    
    NSLog(@"bright : %f / contrast : %f", brightnessValue, contastValue);
    
    [(GPUImageBrightnessFilter*) filter setBrightness:brightnessValue];
    [(GPUImageContrastFilter*) secondFilter setContrast:contastValue];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    _sounds = [NSArray arrayWithObjects: @"meow-01",
               @"meow-02",
               @"meow-03",
               @"meow-04",
               @"meow-05",
               @"meow-06",
               @"purr-01",
               @"song-01",
               nil];
    
    [_primaryView setUserInteractionEnabled:YES];
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    // Setting the swipe direction.
    [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    
    // Adding the swipe gesture on image view
    [_primaryView addGestureRecognizer:swipeLeft];
    [_primaryView addGestureRecognizer:swipeRight];
    
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [tapRecognizer setNumberOfTapsRequired:1];
//    [tapRecognizer setDelegate:self];
    [_primaryView addGestureRecognizer:tapRecognizer];
    
    
//    stillCamera = [[GPUImageStillCamera alloc] init];
    
    
    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    
    
//        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    //    filter = [[GPUImageGammaFilter alloc] init];
//    filter = [[GPUImageSketchFilter alloc] init];
    //    filter = [[GPUImageUnsharpMaskFilter alloc] init];
    //    [(GPUImageSketchFilter *)filter setTexelHeight:(1.0 / 1024.0)];
    //    [(GPUImageSketchFilter *)filter setTexelWidth:(1.0 / 768.0)];
    //    filter = [[GPUImageSmoothToonFilter alloc] init];
//        filter = [[GPUImageSepiaFilter alloc] init];
    //    filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.5, 0.5, 0.5, 0.5)];
    //    secondFilter = [[GPUImageSepiaFilter alloc] init];
    //    terminalFilter = [[GPUImageSepiaFilter alloc] init];
    //    [filter addTarget:secondFilter];
    //    [secondFilter addTarget:terminalFilter];
    
//    	[filter prepareForImageCapture];
    //	[terminalFilter prepareForImageCapture];
    
    
    filter = [[GPUImageBrightnessFilter alloc] init];
    
    secondFilter = [[GPUImageContrastFilter alloc] init];
    [(GPUImageContrastFilter*) secondFilter setContrast:1.6f];
    
    terminalFilter = [[GPUImageSaturationFilter alloc] init];
    [(GPUImageSaturationFilter*) terminalFilter setSaturation:1.5f];
    //    terminalFilter = [[GPUImageSepiaFilter alloc] init];
    //    [filter addTarget:secondFilter];
    //    [secondFilter addTarget:terminalFilter];

    
//    [stillCamera addTarget:filter];
//    [filter addTarget:_primaryView];

    [stillCamera addTarget:terminalFilter];
    
    [secondFilter addTarget:filter];
    [terminalFilter addTarget:secondFilter];
    
    [filter addTarget:_primaryView];
    
    //    [terminalFilter addTarget:filterView];
    
    //    [stillCamera.inputCamera lockForConfiguration:nil];
    //    [stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
    //    [stillCamera.inputCamera unlockForConfiguration];
    
    [stillCamera startCameraCapture];
    
    // play sound
    _nowSoundIndex = 0;
    [self play:_nowSoundIndex];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(becomeActive)
                                                name:UIApplicationDidBecomeActiveNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(becomeDeactive)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
    
}


- (void)tapped:(UITapGestureRecognizer *)tgr
{
    CGPoint tapPoint = [tgr locationInView:_primaryView];
    
    CGPoint pointOfInterest = [HBFocusUtils convertToPointOfInterestFromViewCoordinates:tapPoint inFrame:_primaryView.bounds withOrientation:[[UIDevice currentDevice] orientation] andFillMode:_primaryView.fillMode mirrored:stillCamera.cameraPosition == AVCaptureDevicePositionFront];
    
    [HBFocusUtils setFocus:pointOfInterest forDevice:stillCamera.inputCamera];
}

- (void) becomeActive {
}

- (void) becomeDeactive {
    NSLog(@"becomeDective");
    [self stop];
}

- (void) pause {
    [audioPlayer pause];
    _btnPlayer.title = @"Play";
}

- (void) stop {
    [audioPlayer stop];
    _btnPlayer.title = @"Play";
}

- (void) play : (NSInteger) soundIndex {
    
    
    if([audioPlayer isPlaying]){
        return;
    }
    
    _btnPlayer.title = @"Stop";
    
    NSString *fileName = [_sounds objectAtIndex:soundIndex];
    
    NSLog(@"play sound : %@", fileName);
    
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:fileName ofType: @"mp3"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath ];
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    audioPlayer.numberOfLoops = -1; //infinite loop
    [audioPlayer play];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe {
    
    [self stop];
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        NSLog(@"Left Swipe");
        
        if(_nowSoundIndex >= ([_sounds count]-1)){
            _nowSoundIndex = 0;
        } else {
            _nowSoundIndex++;
        }
        
        [self play:_nowSoundIndex];
    }
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight) {
        NSLog(@"Right Swipe");
        
        if(_nowSoundIndex <= 0){
            _nowSoundIndex = [_sounds count]-1;
        } else {
            _nowSoundIndex--;
        }
        
        [self play:_nowSoundIndex];
    }
    
}

- (IBAction)showLibray:(id)sender {
    NSLog(@"showLibray");
}

- (IBAction)takePhoto:(id)sender {
    NSLog(@"takePhoto");
    [_btnTakePhoto setEnabled:NO];
    
    [stillCamera capturePhotoAsPNGProcessedUpToFilter:filter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        
                // Save to assets library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:stillCamera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2)
         {
             if (error2) {
                 NSLog(@"ERROR: the image failed to be written");
             }
             else {
                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
             }
             
             runOnMainQueueWithoutDeadlocking(^{
                 [_btnTakePhoto setEnabled:YES];
             });
         }];
        
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



@end
