//
//  Util.h
//  meowcam
//
//  Created by 1100003 on 2017. 3. 18..
//  Copyright © 2017년 neosave. All rights reserved.
//

#ifndef Util_h
#define Util_h


#endif /* Util_h */



@interface Util : NSObject

+ (Util*)sharedInstance;
- (UIImage *)imageByCroppingImage:(UIImage *)image toSize:(CGSize)size;

@end
