//
//  PhotoController.h
//  meowcam
//
//  Created by 1100003 on 2017. 2. 27..
//  Copyright © 2017년 neosave. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface PhotoController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *primaryImageView;
@property (strong, nonatomic) IBOutlet UIScrollView *photoScrollView;
@property (nonatomic, assign) int selectedIndex;
@property (strong, nonatomic) NSMutableArray *photos;
@property (strong, nonatomic) GPUImagePicture *sourcePicture;
@property (strong, nonatomic) GPUImageView *filterView;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *firstFilter, *secondFilter;

@end
