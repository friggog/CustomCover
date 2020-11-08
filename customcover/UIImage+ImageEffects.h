
#import <Accelerate/Accelerate.h>

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import "Headers.h"

@interface UIImage (ImageEffects)

+ (UIImage *)filledImageWithColor:(UIColor *)color andSize:(CGSize)size;
- (UIImage *)SBblurredImage;
- (UIImage *)musicLightBlurredImage;
- (UIImage *)musicDarkBlurredImage;
- (UIImage *)imageWithBurnTint:(UIColor *)color;
- (UIImage *)opaqueImageWithBurnTint:(UIColor *)color;
- (UIImage *)filledImageWithColor:(UIColor *)color;
- (BOOL)isEqualTo:(UIImage *)image;

@end
