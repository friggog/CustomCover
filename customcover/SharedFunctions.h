#import <sys/utsname.h>

#define baseDirectory @"/Library/Application Support/CustomCover/Themes"
#define PreferencesChangedNotification "me.chewitt.customcoverprefs.settingschanged"
#define PreferencesFilePath [NSString stringWithFormat:@"/var/mobile/Library/Preferences/me.chewitt.customcoverprefs.plist"]
#define cacheDirectory @"/Library/Application Support/CustomCover/Cache/colours.plist"

static NSString *getDeviceName(NSString *theme) {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return @"iPad";
    }

    NSString *d;

    if ([UIScreen mainScreen].bounds.size.width == 375) {
        d = @"iPhone6";
    }
    else if ([UIScreen mainScreen].bounds.size.width >= 414) {
        d = @"iPhone6+";
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@/%@", baseDirectory, theme, d]]) {
        return d;
    }

    return @"iPhone";
}

static inline NSString *HexStringFromUIColor(UIColor *colour) {
    CGFloat r, g, b, a;
    [colour getRed:&r green:&g blue:&b alpha:&a];
    int rgb = (int)(r * 255.0f) << 16 | (int)(g * 255.0f) << 8 | (int)(b * 255.0f) << 0;
    return [NSString stringWithFormat:@"#%06x", rgb];
}

static inline UIColor *UIColorFromHexString(NSString *hexString) {
    unsigned rgbValue = 0;
    if (! hexString) {
        return [UIColor clearColor];
    }

    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha:1.0];
}

typedef struct Pixel { uint8_t r, g, b, a; } Pixel;
/*
   static UIEdgeInsets transparencyInsetsByCuttingWhitespace(UIImage* img, UInt8 tolerance)
   {
   // Draw our image on that context
   NSInteger width  = (NSInteger)CGImageGetWidth([img CGImage]);
   NSInteger height = (NSInteger)CGImageGetHeight([img CGImage]);
   NSInteger bytesPerRow = width * (NSInteger)sizeof(uint8_t);

   // Allocate array to hold alpha channel
   uint8_t * bitmapData = (uint8_t *)calloc((size_t)(width * height), sizeof(uint8_t));

   // Create grayscale image
   CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
   CGContextRef contextRef = CGBitmapContextCreate(bitmapData, (NSUInteger)width, (NSUInteger)height, 8, (NSUInteger)bytesPerRow, colorSpace, kCGImageAlphaNone);

   CGImageRef cgImage = img.CGImage;
   CGRect rect = CGRectMake(0, 0, width, height);
   CGContextDrawImage(contextRef, rect, cgImage);

   // Sum all non-transparent pixels in every row and every column
   uint16_t * rowSum = (uint16_t *)calloc((size_t)height, sizeof(uint16_t));
   uint16_t * colSum = (uint16_t *)calloc((size_t)width,  sizeof(uint16_t));

   // Enumerate through all pixels
   for (NSInteger row = 0; row < height; row++) {

    for (NSInteger col = 0; col < width; col++) {

      // Found darker pixel
      if (bitmapData[row*bytesPerRow + col] <= UINT8_MAX - tolerance) {

        rowSum[row]++;
        colSum[col]++;

      }
    }
   }

   // Initialize crop insets and enumerate cols/rows arrays until we find non-empty columns or row
   UIEdgeInsets crop = UIEdgeInsetsZero;

   // Top
   for (NSInteger i = 0; i < height; i++) {

    if (rowSum[i] > 0) {

      crop.top = i;
      break;

    }

   }

   // Bottom
   for (NSInteger i = height - 1; i >= 0; i--) {

    if (rowSum[i] > 0) {
      crop.bottom = MAX(0, height - i - 1);
      break;
    }

   }

   // Left
   for (NSInteger i = 0; i < width; i++) {

    if (colSum[i] > 0) {
      crop.left = i;
      break;
    }

   }

   // Right
   for (NSInteger i = width - 1; i >= 0; i--) {

    if (colSum[i] > 0) {

      crop.right = MAX(0, width - i - 1);
      break;

    }
   }

   free(bitmapData);
   free(colSum);
   free(rowSum);

   CGContextRelease(contextRef);

   return crop;
   }

   static UIImage* imageByTrimmingWhitePixelsWithOpacity(UIImage*img, UInt8 tolerance)
   {
   if (img.size.height < 2 || img.size.width < 2)
    return img;

    CGRect rect = CGRectMake(0, 0, img.size.width * img.scale, img.size.height * img.scale);
    UIEdgeInsets crop = transparencyInsetsByCuttingWhitespace(img,tolerance);

    UIImage *newImg = img;
    if ((crop.top == 0 && crop.bottom == 0 && crop.left == 0 && crop.right == 0) || crop.top > 0.15*img.size.height || crop.bottom > 0.15*img.size.height || crop.left > 0.15*img.size.width || crop.right > 0.15*img.size.width) {

      // No cropping needed

    } else {

      // Calculate new crop bounds
      rect.origin.x += crop.left;
      rect.origin.y += crop.top;
      rect.size.width -= crop.left + crop.right;
      rect.size.height -= crop.top + crop.bottom;

      // Crop it
      CGImageRef newImage = CGImageCreateWithImageInRect([img CGImage], rect);

      // Convert back to UIImage
      newImg = [UIImage imageWithCGImage:newImage scale:img.scale orientation:img.imageOrientation];

      CGImageRelease(newImage);
    }

    return newImg;
   }
 */
