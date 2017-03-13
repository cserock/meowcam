#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageView.h"

@interface HBFocusUtils : NSObject

+ (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates inFrame:(CGRect)frame withOrientation:(UIDeviceOrientation)orientation andFillMode:(GPUImageFillModeType)fillMode mirrored:(BOOL)mirrored;
+ (void)setFocus:(CGPoint)focus forDevice:(AVCaptureDevice *)device;
@end
