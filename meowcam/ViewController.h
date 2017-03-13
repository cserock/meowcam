//
//  ViewController.h
//  meowcam
//
//  Created by 1100003 on 2017. 2. 23..
//  Copyright © 2017년 neosave. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface ViewController : UIViewController {

    GPUImageStillCamera *stillCamera;
    GPUImageOutput<GPUImageInput> *filter, *secondFilter, *terminalFilter;
    
    GPUImagePicture *memoryPressurePicture1, *memoryPressurePicture2;
    AVAudioPlayer *audioPlayer;
}

@end

