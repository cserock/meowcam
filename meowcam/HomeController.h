//
//  HomeController.h
//  meowcam
//
//  Created by 1100003 on 2017. 2. 27..
//  Copyright © 2017년 neosave. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFSocket.h>
#import <ImageIO/CGImageProperties.h>

@interface HomeController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVAudioPlayer *audioPlayer;
}
@end
