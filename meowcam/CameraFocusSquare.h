@import UIKit;

@interface CameraFocusSquare : UIView

- (instancetype)initWithTouchPoint:(CGPoint)touchPoint;
- (void)updatePoint:(CGPoint)touchPoint;
- (void)animateFocusingAction;

@end
