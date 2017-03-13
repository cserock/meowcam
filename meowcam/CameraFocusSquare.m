#import "CameraFocusSquare.h"

@implementation CameraFocusSquare {
    CABasicAnimation *_selectionBlink;
}

/**
 This is the init method for the square. It sets the frame for the view and sets border parameters. It also creates the blink animation.
 */
- (instancetype)initWithTouchPoint:(CGPoint)touchPoint {
    self = [self init];
    if (self) {
        [self updatePoint:touchPoint];
        self.backgroundColor = [UIColor clearColor];
        self.layer.borderWidth = 2.0f;
        self.layer.borderColor = [UIColor colorWithRed:246.0f/255.0f green:49.0f/255.0f blue:140.0f/255.0f alpha:1.0f].CGColor;
        
        // create the blink animation
        _selectionBlink = [CABasicAnimation
                           animationWithKeyPath:@"borderColor"];
        _selectionBlink.toValue = (id)[UIColor colorWithRed:255.0f/255.0f green:242.0f/255.0f blue:190.0f/255.0f alpha:1.0f].CGColor;
        _selectionBlink.repeatCount = INFINITY;  // number of blinks
//        _selectionBlink.repeatCount = 3;  // number of blinks
        _selectionBlink.duration = 0.4;  // this is duration per blink
        _selectionBlink.delegate = self;
    }
    return self;
}

/**
 Updates the location of the view based on the incoming touchPoint.
 */
- (void)updatePoint:(CGPoint)touchPoint {
    CGFloat squareWidth = 50;
    CGRect frame = CGRectMake(touchPoint.x - squareWidth/2, touchPoint.y - squareWidth/2, squareWidth, squareWidth);
    self.frame = frame;
}

/**
 This unhides the view and initiates the animation by adding it to the layer.
 */
- (void)animateFocusingAction {
    // make the view visible
    self.alpha = 1.0f;
    self.hidden = NO;
    // initiate the animation
    [self.layer addAnimation:_selectionBlink forKey:@"selectionAnimation"];
}

/**
 Hides the view after the animation stops. Since the animation is automatically removed, we don't need to do anything else here.
 */
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    // hide the view
    self.alpha = 0.0f;
    self.hidden = YES;
    
    NSLog(@"finished");
}

@end
