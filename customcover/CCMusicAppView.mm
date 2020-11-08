#import "CCMusicAppView.h"
#import "SharedFunctions.h"
#import "Headers.h"

@implementation CCMusicAppView

- (id)initWithPreferences:(NSDictionary *)preferences orientation:(long)o {
    currentTheme = [preferences valueForKey:@"MusicSelectedTheme"];
    NSString *deviceName = getDeviceName(currentTheme);

    CGFloat yPos = 64;
    if (IS_IOS_(8,4)) {
        yPos = 0;
    }
    CGRect screenBounds = CGRectMake(0, yPos, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);

    if ([UIScreen mainScreen].bounds.size.height == 480) {
        screenBounds = CGRectMake(0, 64, 320, 265);
        if (IS_IOS_(8,4)) {
            screenBounds = CGRectMake(-64, -30, 320, 232);
        }
    }

    CGPoint centreOfScreen = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 3);
    if (IS_IOS_(8,4)) {
        centreOfScreen = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2.5);
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect tempScreenBounds;
        if (UIDeviceOrientationIsLandscape(o)) {
            tempScreenBounds = CGRectMake(0, 0, 1024, 768);
        }
        else {
            tempScreenBounds = CGRectMake(0, 0, 768, 1024);
        }
        CGPoint tempCentre = CGPointMake(tempScreenBounds.size.width / 2, tempScreenBounds.size.height / 2);
        screenBounds = CGRectMake(tempCentre.x - 250, tempCentre.y - 250, 500, 500);
        centreOfScreen = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 1.9);
        if (IS_IOS_(8,4)) {
            screenBounds = CGRectMake(-30, -77, 500, 500);
        }
    }

    NSDictionary *metrics = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Metrics.plist", baseDirectory, currentTheme, deviceName]];

    CGFloat artworkOriginX = [[metrics objectForKey:@"ArtworkOriginX"] floatValue];
    CGFloat artworkOriginY = [[metrics objectForKey:@"ArtworkOriginY"] floatValue];
    CGFloat artworkSizeX = [[metrics objectForKey:@"ArtworkSizeX"] floatValue];
    CGFloat artworkSizeY = [[metrics objectForKey:@"ArtworkSizeY"] floatValue];

    CGFloat backOriginX = [[metrics objectForKey:@"BackOriginX"] floatValue];
    CGFloat backOriginY = [[metrics objectForKey:@"BackOriginY"] floatValue];
    CGFloat backSizeX = [[metrics objectForKey:@"BackSizeX"] floatValue];
    CGFloat backSizeY = [[metrics objectForKey:@"BackSizeY"] floatValue];

    CGFloat overlayOriginX = [[metrics objectForKey:@"OverlayOriginX"] floatValue];
    CGFloat overlayOriginY = [[metrics objectForKey:@"OverlayOriginY"] floatValue];
    CGFloat overlaySizeX = [[metrics objectForKey:@"OverlaySizeX"] floatValue];
    CGFloat overlaySizeY = [[metrics objectForKey:@"OverlaySizeY"] floatValue];

    CGFloat legacyOffset = [[metrics objectForKey:@"MusicOffset"] floatValue];

    CGFloat mostLeftValue = backOriginX;

    if (overlayOriginX < mostLeftValue) {
        mostLeftValue = overlayOriginX;
    }

    if (artworkOriginX < mostLeftValue) {
        mostLeftValue = artworkOriginX;
    }

    CGFloat mostUpValue = backOriginY;

    if (overlayOriginY < mostUpValue) {
        mostUpValue = overlayOriginY;
    }

    if (artworkOriginY < mostUpValue) {
        mostUpValue = artworkOriginY;
    }

    CGFloat biggestWidth = backSizeX;

    if (overlaySizeX > biggestWidth) {
        biggestWidth = overlaySizeX;
    }

    if (artworkSizeX > biggestWidth) {
        biggestWidth = artworkSizeX;
    }

    CGFloat biggestHeight = backSizeY;

    if (overlaySizeY > biggestHeight) {
        biggestHeight = overlaySizeY;
    }

    if (artworkSizeY > biggestHeight) {
        biggestHeight = artworkSizeY;
    }

    CGRect biggestRect = CGRectMake(centreOfScreen.x + mostLeftValue, centreOfScreen.y + mostUpValue, biggestWidth, biggestHeight);

    CGRect artworkFrame = CGRectMake(artworkOriginX - mostLeftValue, artworkOriginY - mostUpValue, artworkSizeX, artworkSizeY);
    CGRect overlayFrame = CGRectMake(overlayOriginX - mostLeftValue, overlayOriginY - mostUpValue, overlaySizeX, overlaySizeY);
    CGRect backFrame = CGRectMake(backOriginX - mostLeftValue, backOriginY - mostUpValue, backSizeX, backSizeY);

    self = [super initWithFrame:screenBounds];

    UIView *themeContainerView = [[UIView alloc] initWithFrame:biggestRect];

    themeContainerView.frame = CGRectMake(themeContainerView.frame.origin.x, themeContainerView.frame.origin.y + legacyOffset, themeContainerView.frame.size.width, themeContainerView.frame.size.height);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        themeContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    }

    themeContainerView.userInteractionEnabled = YES;

    [self addSubview:themeContainerView];

    albumArtworkView = [[UIImageView alloc] initWithFrame:artworkFrame];
    albumArtworkView.contentMode = UIViewContentModeScaleAspectFill;
    albumArtworkView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    albumArtworkView.layer.masksToBounds = YES;

    UIImage *maskImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Mask.png", baseDirectory, currentTheme, deviceName]];

    if (maskImage) {
        CALayer *mask = [CALayer layer];
        mask.contents = (id)[maskImage CGImage];
        mask.frame = CGRectMake(0, 0, artworkFrame.size.width, artworkFrame.size.height);
        albumArtworkView.layer.mask = mask;
    }

    [themeContainerView addSubview:albumArtworkView];

    UIImageView *behindImageView = [[UIImageView alloc] initWithFrame:backFrame];
    if ([[metrics objectForKey:@"BlendBackground"] boolValue]) {
        [behindImageView _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeOverlay];
    }
    UIImage *backImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Background.png", baseDirectory, currentTheme, deviceName]];
    behindImageView.image = backImage;
    behindImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [themeContainerView insertSubview:behindImageView belowSubview:albumArtworkView];

    UIImageView *inFrontImageView = [[UIImageView alloc] initWithFrame:overlayFrame];
    UIImage *frontImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Overlay.png", baseDirectory, currentTheme, deviceName]];
    inFrontImageView.image = frontImage;
    inFrontImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    [themeContainerView insertSubview:inFrontImageView aboveSubview:albumArtworkView];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_tapAction:)];
    singleTap.numberOfTapsRequired = 1;
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_flipsideAction:)];
    doubleTap.numberOfTapsRequired = 2;

    [singleTap requireGestureRecognizerToFail:doubleTap];

    [self addGestureRecognizer:singleTap];
    [self addGestureRecognizer:doubleTap];

    return self;
}

- (void)updateWithImage:(UIImage *)image {
    [UIView transitionWithView:albumArtworkView
     duration:0.2f
     options:UIViewAnimationOptionTransitionCrossDissolve
     animations:^{
        albumArtworkView.image = image;
    } completion:nil];
}

- (id)image {
    return albumArtworkView.image;
}

- (NSString *)themeName {
    return currentTheme;
}

@end
