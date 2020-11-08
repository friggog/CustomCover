#import "CCLockScreenView.h"
#import "SharedFunctions.h"
#import "Headers.h"

@implementation CCLockScreenView

- (id)initWithFrame:(CGRect)frame andThemeName:(NSString *)theme andPreferences:(NSDictionary *)preferences {
    self = [super initWithFrame:frame];
    if (self) {
        currentTheme = theme;

        NSString *deviceName = getDeviceName(currentTheme);

        CGPoint centreOfScreen = CGPointMake(frame.size.width / 2, frame.size.height / 2);

        NSDictionary *metrics = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Metrics.plist", baseDirectory, theme, deviceName]];

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

        CGFloat legacyOffset = [[metrics objectForKey:@"LegacyOffset"] floatValue];

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

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }

        UIView *themeContainerView = [[UIView alloc] initWithFrame:biggestRect];

        if ([UIScreen mainScreen].bounds.size.height == 480) {
            themeContainerView.frame = CGRectMake(themeContainerView.frame.origin.x, themeContainerView.frame.origin.y + legacyOffset, themeContainerView.frame.size.width, themeContainerView.frame.size.height);
        }

        CGFloat manualOffsetX = [[preferences valueForKey:@"manualOffsetX"] floatValue];
        CGFloat manualOffsetY = [[preferences valueForKey:@"manualOffsetY"] floatValue];

        themeContainerView.frame = CGRectMake(themeContainerView.frame.origin.x + manualOffsetX, themeContainerView.frame.origin.y + manualOffsetY, themeContainerView.frame.size.width, themeContainerView.frame.size.height);

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            themeContainerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        }

        [self addSubview:themeContainerView];

        _artworkView = [[UIImageView alloc] initWithFrame:artworkFrame];
        _artworkView.contentMode = UIViewContentModeScaleAspectFill;
        _artworkView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        _artworkView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Default.png", baseDirectory, theme, deviceName]];
        _artworkView.layer.masksToBounds = YES;

        UIImage *maskImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Mask.png", baseDirectory, theme, deviceName]];

        if (maskImage) {
            CALayer *mask = [CALayer layer];
            mask.contents = (id)[maskImage CGImage];
            mask.frame = CGRectMake(0, 0, artworkFrame.size.width, artworkFrame.size.height);
            _artworkView.layer.mask = mask;
        }

        [themeContainerView addSubview:_artworkView];

        UIImageView *behindImageView = [[UIImageView alloc] initWithFrame:backFrame];
        UIImage *backImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Background.png", baseDirectory, theme, deviceName]];
        behindImageView.image = backImage;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            behindImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        }
        if ([[metrics objectForKey:@"BlendBackground"] boolValue]) {
            [behindImageView _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeOverlay];
        }
        [themeContainerView insertSubview:behindImageView belowSubview:_artworkView];

        UIImageView *inFrontImageView = [[UIImageView alloc] initWithFrame:overlayFrame];
        UIImage *frontImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Overlay.png", baseDirectory, theme, deviceName]];
        inFrontImageView.image = frontImage;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            inFrontImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        }
        [themeContainerView insertSubview:inFrontImageView aboveSubview:_artworkView];
    }
    return self;
}

- (void)updateWithImage:(UIImage *)image {
    [UIView transitionWithView:_artworkView
     duration:0.2f
     options:UIViewAnimationOptionTransitionCrossDissolve
     animations:^{
        _artworkView.image = image;
    } completion:nil];
}

- (void)setImage:(UIImage *)img {}

- (id)image {
    return _artworkView.image;
}

- (NSString *)themeName {
    return currentTheme;
}

- (CGSize)artworkSize {
    if ([currentTheme isEqualToString:@"Blank"]) {
        return CGSizeMake(320, 320);
    }

    if (_artworkView.frame.size.height >= _artworkView.frame.size.width) {
        return CGSizeMake(_artworkView.frame.size.height, _artworkView.frame.size.height);
    }
    else {
        return CGSizeMake(_artworkView.frame.size.width, _artworkView.frame.size.width);
    }
}

- (long long)orientation {
    return 0;
}

- (void)setOrientation:(long long)arg1 {}

@end
