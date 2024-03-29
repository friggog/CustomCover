#import "UIImage+ImageEffects.h"
#import <float.h>
#import <objc/runtime.h>

SBFStaticWallpaperView *_wallpaperView;

@implementation UIImage (ImageEffects)

- (UIImage *)SBblurredImage {
    SBWallpaperController *controller = [objc_getClass("SBWallpaperController") sharedInstance];

    if ([controller respondsToSelector:@selector(_newWallpaperViewForProcedural:orImage:)]) {
        _wallpaperView = [controller _newWallpaperViewForProcedural:nil orImage:self];
    }
    else {
        _wallpaperView = [controller _newWallpaperViewForProcedural:nil orImage:self forVariant:0];
    }

    [_wallpaperView removeFromSuperview];

    NSInteger style = 4;

    UIImage *img = [objc_getClass("_SBFakeBlurView") _imageForStyle:&style withSource:_wallpaperView];

    return img;
}

- (UIImage *)musicDarkBlurredImage {
    return [self applyLightEffect];
}

- (UIImage *)musicLightBlurredImage {
    return [self applyDarkEffect];
}

- (UIImage *)imageWithBurnTint:(UIColor *)color {
    UIImage *img = self;

    // lets tint the icon - assumes your icons are black
    UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);

    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, img.CGImage);

    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);

    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return coloredImage;
}

- (UIImage *)opaqueImageWithBurnTint:(UIColor *)color {
    UIImage *img = self;

    // lets tint the icon - assumes your icons are black
    UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);

    // draw alpha-mask
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, img.CGImage);

    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);
    CGContextDrawImage(context, rect, img.CGImage);

    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);

    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return coloredImage;
}

+ (UIImage *)filledImageWithColor:(UIColor *)color andSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)filledImageWithColor:(UIColor *)color {
    UIImage *img = self;

    // lets tint the icon - assumes your icons are black
    UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    //CGContextTranslateCTM(context, 0, img.size.height);
    //CGContextScaleCTM(context, 1.0, -1.0);

    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);

    // draw alpha-mask
//	CGContextSetBlendMode(context, kCGBlendModeNormal);
//	CGContextDrawImage(context, rect, img.CGImage);

    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [color setFill];
    CGContextFillRect(context, rect);

    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return coloredImage;
}

- (UIImage *)applyLightEffect {
    UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    return [self applyBlurWithRadius:15 tintColor:tintColor saturationDeltaFactor:2.0 maskImage:nil];
}

- (UIImage *)applyDarkEffect {
    UIColor *tintColor = [UIColor colorWithWhite:0.11 alpha:0.45];
    return [self applyBlurWithRadius:15 tintColor:tintColor saturationDeltaFactor:2.5 maskImage:nil];
}

- (UIImage *)applyExtraLightEffect {
    UIColor *tintColor = [UIColor colorWithWhite:0.97 alpha:0.82];
    return [self applyBlurWithRadius:20 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}

- (UIImage *)applyTintEffectWithColor:(UIColor *)tintColor {
    const CGFloat EffectColorAlpha = 0.6;
    UIColor *effectColor = tintColor;
    NSInteger componentCount = CGColorGetNumberOfComponents(tintColor.CGColor);
    if (componentCount == 2) {
        CGFloat b;
        if ([tintColor getWhite:&b alpha:NULL]) {
            effectColor = [UIColor colorWithWhite:b alpha:EffectColorAlpha];
        }
    }
    else {
        CGFloat r, g, b;
        if ([tintColor getRed:&r green:&g blue:&b alpha:NULL]) {
            effectColor = [UIColor colorWithRed:r green:g blue:b alpha:EffectColorAlpha];
        }
    }
    return [self applyBlurWithRadius:10 tintColor:effectColor saturationDeltaFactor:-1.0 maskImage:nil];
}

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage {
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    if (! self.CGImage) {
        return nil; 
    }
    if (maskImage && ! maskImage.CGImage) {
        return nil;
    }

    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;

    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);

        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);

        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);

        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix) / sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (! effectImageBuffersAreSwapped) {
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();

        if (effectImageBuffersAreSwapped) {
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
    }

    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);

    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);

    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }

    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }

    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return outputImage;
}

- (BOOL)isEqualTo:(UIImage *)image {
    NSData *data1 = UIImagePNGRepresentation(self);
    NSData *data2 = UIImagePNGRepresentation(image);

    return [data1 isEqual:data2];
}

@end
