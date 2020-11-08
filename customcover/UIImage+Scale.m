//
//  UIImage+Scale.m
//  ColorArt
//
//  Created by Fred Leitz on 2012-12-15.
//  Copyright (c) 2012 Fred Leitz. All rights reserved.
//

#import "UIImage+Scale.h"

@implementation UIImage (Scale)
- (UIImage *)scaledToSize:(CGSize)newSize {
    if ([[UIScreen mainScreen] scale] == 2.0) {
        UIGraphicsBeginImageContextWithOptions(newSize, YES, 2.0);
    }
    else {
        UIGraphicsBeginImageContext(newSize);
    }
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
