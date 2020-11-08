#import "Headers.h"
#import "UIImage+ImageEffects.h"
#import "SLColorArt.h"
#import "UIImage+Scale.h"
#import <UIKit/UIKit.h>
#import "CCLockScreenView.h"
#import "CCMusicAppView.h"
#import "substrate.h"
#import <sys/utsname.h>
#import "SharedFunctions.h"

@interface CFWPrefsManager : NSObject
+ (instancetype)sharedInstance;
@property(nonatomic, assign, getter=isLockScreenEnabled) BOOL lockScreenEnabled;
@end

#define colorFlowLockscreenEnabled ((CFWPrefsManager*)[%c(CFWPrefsManager) sharedInstance]).lockScreenEnabled

static NSDictionary *preferences;

static NSString *selectedThemeName = nil;
static NSString *musicSelectedThemeName = nil;
static NSString *deviceNameLS = @"iPhone";
static NSString *deviceNameM = @"iPhone";

static UIView *backgroundColourView = nil;
static UIImageView *backgroundArtworkView = nil;
static UIView *backgroundArtworkDarkenView = nil;

static SBLockScreenView *activeLockScreenView = nil;
static CCLockScreenView *activeCCLockScreenView = nil;

static UIImage *currentArtwork = nil;
static NSData *currentArtworkData = nil;
static MPUNowPlayingController *currentNowPlayingController = nil;

//static NSObject  *IDNumberObject = [NSObject new];
static BOOL areNotificationsVisible = NO;

static UIView *lsScrubThumbView = nil;
static UIImage *LSMaxVolImage = nil;
static UIImage *LSMinVolImage = nil;
static CGFloat lsClockOrigY;

static UIImage *cameraGrabberImage = nil;
static UIView *bottomGrabberColourView = nil;
static UIView *topGrabberColourView = nil;

static BOOL isLockScreenActive;
//static BOOL isLocked;
static BOOL forceCache;

static UIColor *pCol = nil;
static UIColor *sCol = nil;
static UIColor *bCol = nil;

static NSString  *currentSongID;
static NSString  *previousSongID;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
    selectedThemeName = [preferences valueForKey:@"SelectedTheme"];
    musicSelectedThemeName = [preferences valueForKey:@"MusicSelectedTheme"];
    deviceNameLS = getDeviceName(selectedThemeName);
    deviceNameM =  getDeviceName(musicSelectedThemeName);
}

static BOOL isLandscape() {
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] activeInterfaceOrientation]);
}

%group CustomCoverLockScreen

@interface CustomCoverAPI:NSObject
+(UIView*) mainLSView;
+(UIView*) backgroundLSView;
+(UIColor*) primaryLSColour;
+(UIColor*) secondaryLSColour;
+(UIColor*) backgroundLSColour;
@end

@implementation CustomCoverAPI

+(UIView*) mainLSView {
    return activeCCLockScreenView;
}

+(UIView*) backgroundLSView {
    if ([[preferences valueForKey:@"colourFromArtwork"] boolValue]) {
        return backgroundColourView;
    }
    else if ([[preferences valueForKey:@"ArtworkBG"] boolValue]) {
        UIView *v = [[UIView alloc] initWithFrame:backgroundArtworkView.frame];
        [v addSubview:backgroundArtworkView];
        [v addSubview:backgroundArtworkDarkenView];
        return v;
    }
    else {
        return nil;
    }
}

+(UIColor*) primaryLSColour {
    return pCol;
}

+(UIColor*) secondaryLSColour {
    return sCol;
}

+(UIColor*) backgroundLSColour {
    return bCol;
}

@end

%hook SBLockScreenViewController

- (void)activate {
    %orig;
    isLockScreenActive = YES;
}

-(void) deactivate {
    %orig;
    isLockScreenActive = NO;
    areNotificationsVisible = NO;
}

-(void) notificationListBecomingVisible:(BOOL)arg1 {
    %orig;
    areNotificationsVisible = arg1;
    if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] && [activeLockScreenView isMediaPluginActive] && ! [[preferences valueForKey:@"keepColoursForNotifications"] boolValue]) {
        if (arg1) {
            [activeLockScreenView updateControlColours:YES];
        }
        else {
            [activeLockScreenView updateControlColours:NO];
        }
    }
    [activeLockScreenView layoutSubviews];
}

%end

%hook _NowPlayingArtView

- (void)layoutSubviews {
    %orig;
    if ([selectedThemeName isEqualToString:@"Default"]) {
        CGRect startFrame = self.artworkView.frame;
        CGFloat manualOffsetX = [[preferences valueForKey:@"manualOffsetX"] floatValue];
        CGFloat manualOffsetY = [[preferences valueForKey:@"manualOffsetY"] floatValue];
        CGRect newFrame = CGRectMake(startFrame.origin.x + manualOffsetX, startFrame.origin.y + manualOffsetY, startFrame.size.width, startFrame.size.height);
        self.artworkView.frame = newFrame;
    }
}

%end

%hook NowPlayingArtPluginController

- (void)loadView {
    %orig;
    if (selectedThemeName == nil) {
        selectedThemeName = @"Default";
    }

    if (! [selectedThemeName isEqualToString:@"Default"]) {
        CGRect screenBounds = [UIScreen mainScreen].bounds;

        activeCCLockScreenView = [[%c(CCLockScreenView) alloc] initWithFrame:screenBounds andThemeName:selectedThemeName andPreferences:preferences];

        _NowPlayingArtView *view = (_NowPlayingArtView*)self.view;
        view.artworkView = nil;

        [view addSubview:activeCCLockScreenView];
    }
    [[%c(SBMediaController) sharedInstance] performSelector:@selector(updateImage) withObject:nil afterDelay:0.1];
    //}
}

-(void) viewWillAppear:(BOOL)arg1 {
    %orig;
    if (backgroundArtworkView) {
        backgroundArtworkView.hidden = NO;
    }
    if (backgroundArtworkDarkenView) {
        backgroundArtworkDarkenView.hidden = NO;
    }
    if (backgroundColourView) {
        backgroundColourView.hidden = NO;
    }
}

-(void) viewWillDisappear:(BOOL)arg1 {
    %orig;
    if (backgroundArtworkView) {
        backgroundArtworkView.hidden = YES;
    }
    if (backgroundArtworkDarkenView) {
        backgroundArtworkDarkenView.hidden = YES;
    }
    if (backgroundColourView) {
        backgroundColourView.hidden = YES;
    }
}

%end

%hook MPUNowPlayingController

- (id)init {
    currentNowPlayingController = %orig;
    return %orig;
}

-(UIImage*) currentNowPlayingArtwork {
    UIImage *newArtwork = %orig;
    NSData *newData = UIImagePNGRepresentation(newArtwork);
    currentSongID = [[currentNowPlayingController.currentNowPlayingInfo valueForKey:@"kMRMediaRemoteNowPlayingInfoUniqueIdentifier"] stringValue];
    if (! [currentArtworkData isEqual:newData]) {
        if([currentSongID isEqualToString:previousSongID]) {
            forceCache = YES;
        }
        previousSongID = currentSongID;
        currentArtworkData = newData;

        [[%c(SBMediaController) sharedInstance] updateImage:newArtwork];

        if (activeCCLockScreenView.hidden) {
            activeCCLockScreenView.hidden = NO;
        }
    }
    return %orig;
}

%end

%hook SBMediaController

%new

- (void)updateImage {
    [self updateImage:currentArtwork];
}

%new

- (void)updateImage : (UIImage*)image {
    currentArtwork = image;

    if (currentArtwork == nil) {
        currentArtwork = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Default.png", baseDirectory, selectedThemeName, deviceNameLS]];
    }

    UIImage *artworkToSet = currentArtwork;

    if (backgroundArtworkView && [activeLockScreenView isMediaPluginActive]) {
        UIImage *imageForBG = artworkToSet;
        if (imageForBG != nil) {
            if ([[preferences valueForKey:@"LSBackgroundMode"] intValue] != 2) {
                imageForBG = [imageForBG scaledToSize:CGSizeMake(320, 320)];
                if ([[preferences valueForKey:@"LSBackgroundMode"] intValue] == 1) {
                    imageForBG = [imageForBG musicLightBlurredImage];
                }
                else {
                    imageForBG = [imageForBG musicDarkBlurredImage];
                }
            }
        }

        backgroundArtworkView.hidden = NO;

        [UIView transitionWithView:backgroundArtworkView
         duration:0.2f
         options:UIViewAnimationOptionTransitionCrossDissolve
         animations:^{
            backgroundArtworkView.image = imageForBG;
        } completion:nil];

        if (backgroundArtworkDarkenView) {
            if (imageForBG) {
                backgroundArtworkDarkenView.hidden = NO;
            }
            else {
                backgroundArtworkDarkenView.hidden = YES;
            }
        }
    }

    if (activeCCLockScreenView) {
        [activeCCLockScreenView updateWithImage:currentArtwork];
    }

    if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] && [activeLockScreenView isMediaPluginActive]) {
        backgroundColourView.hidden = NO;
        if (activeLockScreenView) {
            [activeLockScreenView updateControlColours];
        }
    }
}

%end

%hook SBLockScreenView

- (void)layoutSubviews {
    %orig;
    activeLockScreenView = self;

    if (! lsClockOrigY) {
        lsClockOrigY = self.dateView.center.y;
    }

    self.mediaControlsView.hidden = [[preferences valueForKey:@"HideControls"] boolValue];

    if ([self isMediaPluginActive]) {
        if (! areNotificationsVisible) {
            self.dateView.center = CGPointMake(self.dateView.center.x, lsClockOrigY + [[preferences valueForKey:@"controlsOffset"] floatValue]);
            MSHookIvar<UIView*>(self, "_slideToUnlockView").hidden = [[preferences valueForKey:@"HideS2U"] boolValue];
        }
        else {
            self.dateView.center = CGPointMake(self.dateView.center.x, lsClockOrigY);
            self.dateView.textColor = self.legibilitySettings.primaryColor;
            MSHookIvar<UIView*>(self, "_slideToUnlockView").hidden = NO;
        }

        if ([[preferences valueForKey:@"ArtworkBG"] boolValue] && !colorFlowLockscreenEnabled) {
            if (! backgroundArtworkView) {
                backgroundArtworkView = [[UIImageView alloc] initWithFrame:isLandscape()?CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width):CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
                backgroundArtworkView.contentMode = UIViewContentModeScaleAspectFill;
                backgroundArtworkView.layer.masksToBounds = YES;

                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    backgroundArtworkView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                }
            }

            if (! [backgroundArtworkView isDescendantOfView:self]) {
                UIView *fv = MSHookIvar<UIView*>(self, "_foregroundView");
                [self insertSubview:backgroundArtworkView belowSubview:fv];
                [self updateControlColours:YES];
            }

            if (! backgroundArtworkDarkenView) {
                backgroundArtworkDarkenView = [[UIView alloc] initWithFrame:isLandscape()?CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width):CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
                backgroundArtworkDarkenView.hidden = YES;
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    backgroundArtworkDarkenView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                }
            }

            if ([[preferences valueForKey:@"LSBackgroundMode"] intValue] == 1) {
                backgroundArtworkDarkenView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
            }
            else if ([[preferences valueForKey:@"LSBackgroundMode"] intValue] == 2) {
                backgroundArtworkDarkenView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
            }
            else {
                backgroundArtworkDarkenView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
            }

            if (! [backgroundArtworkDarkenView isDescendantOfView:backgroundArtworkView]) {
                [backgroundArtworkView addSubview:backgroundArtworkDarkenView];
            }
        }
        else if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] && !colorFlowLockscreenEnabled) {
            if (! backgroundColourView) {
                backgroundColourView = [[UIView alloc] initWithFrame:isLandscape()?CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width):CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
                backgroundColourView.contentMode = UIViewContentModeScaleAspectFill;
                backgroundColourView.layer.masksToBounds = YES;
                backgroundColourView.hidden = YES;

                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    backgroundColourView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                }
            }

            if (! [backgroundColourView isDescendantOfView:self]) {
                UIView *fv = MSHookIvar<UIView*>(self, "_foregroundView");
                [self insertSubview:backgroundColourView belowSubview:fv];
            }
        }
        else {
            [self updateControlColours:YES];
            if (backgroundArtworkView) {
                [backgroundArtworkView removeFromSuperview];
                backgroundArtworkView = nil;
            }
            if (backgroundColourView) {
                [backgroundColourView removeFromSuperview];
                backgroundColourView = nil;
            }
        }
    }
    else {
        self.dateView.center = CGPointMake(self.dateView.center.x, lsClockOrigY);
        self.dateView.textColor = self.legibilitySettings.primaryColor;
    }
}

-(CGFloat) _mediaControlsY {
    if ([self isMediaPluginActive] && [preferences valueForKey:@"controlsOffset"] && ! areNotificationsVisible) {
        return [[preferences valueForKey:@"controlsOffset"] floatValue] + 20;
    }
    else {
        return %orig;
    }
}

-(id) _effectiveStatusBarColor {
    if (!colorFlowLockscreenEnabled && ([[preferences valueForKey:@"colourFromArtwork"] boolValue] || [preferences valueForKey:@"LSPrimaryCol"] != nil) && [self isMediaPluginActive] && isLockScreenActive) {
        return pCol;
    }
    else {
        return %orig;
    }
}

-(void) _updateDateViewLegibility {
    if (! [self isMediaPluginActive] || colorFlowLockscreenEnabled) {
        %orig;
    }
}

-(void) setLegibilitySettingsOverrideVibrancy:(BOOL)arg1 {
    if ([self isMediaPluginActive] && !colorFlowLockscreenEnabled) {
        %orig(YES);
    }
    else {
        %orig;
    }
}

%new

- (void)updateControlColours {
    [self updateControlColours:NO];
}

%new

- (void)updateControlColours : (BOOL)reset {
    if(!colorFlowLockscreenEnabled) {
        if (areNotificationsVisible) {
            reset = YES;
        }

        [UIView animateWithDuration:0.2f animations:^{
            backgroundColourView.hidden = NO;

            if (currentArtwork && [[preferences valueForKey:@"colourFromArtwork"] boolValue]) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:cacheDirectory];
                if (! dic) {
                    dic = [[NSMutableDictionary alloc] init];
                }

                if ([dic valueForKey:[NSString stringWithFormat:@"%@", currentSongID]] && currentSongID && ! forceCache) {
                    NSDictionary *subDic = [dic valueForKey:[NSString stringWithFormat:@"%@", currentSongID]];
                    pCol = UIColorFromHexString([subDic valueForKey:@"Primary"]);
                    sCol = UIColorFromHexString([subDic valueForKey:@"Secondary"]);
                    bCol = UIColorFromHexString([subDic valueForKey:@"Background"]);
                }
                else {
                    forceCache = NO;

                    SLColorArt *colours = [[SLColorArt alloc] initWithImage:[currentArtwork scaledToSize:CGSizeMake(200, 200)]];
                    pCol = colours.primaryColor;
                    sCol = colours.secondaryColor;
                    bCol = colours.backgroundColor;

                    if (currentSongID) {
                        NSArray *keys = [NSArray arrayWithObjects:@"Primary", @"Secondary", @"Background", nil];
                        NSArray *colourArray = [NSArray arrayWithObjects:HexStringFromUIColor(pCol), HexStringFromUIColor(sCol), HexStringFromUIColor(bCol), nil];
                        NSDictionary *subDic = [NSDictionary dictionaryWithObjects:colourArray forKeys:keys];
                        [dic setValue:subDic forKey:currentSongID];
                        [dic writeToFile:cacheDirectory atomically:YES];
                    }
                }

                if (backgroundColourView) {
                    backgroundColourView.backgroundColor = bCol;
                }
            }
            else {
                NSString *pColString = [preferences valueForKey:@"LSPrimaryCol"];
                if (pColString) {
                    pCol = UIColorFromHexString(pColString);
                }
                else {
                    pCol = [UIColor whiteColor];
                }

                NSString *sColString = [preferences valueForKey:@"LSSecondaryCol"];
                if (sColString) {
                    sCol = UIColorFromHexString(sColString);
                }
                else {
                    sCol = pCol;
                }

                if ([pCol isEqual:sCol] || [pColString isEqualToString:sColString]) {
                    sCol = [sCol colorWithAlphaComponent:0.5];
                }

                if (backgroundColourView) {
                    backgroundColourView.backgroundColor = bCol = [UIColor clearColor];
                }
            }

            if (reset) {
                static NSString *const CustomCoverResetColourisationNotification = @"CustomCoverLockScreenColourResetNotification";
                [[NSNotificationCenter defaultCenter] postNotificationName:CustomCoverResetColourisationNotification object:nil];

                NSString *pColString = [preferences valueForKey:@"LSPrimaryCol"];
                if (pColString) {
                    pCol = UIColorFromHexString(pColString);
                }
                else {
                    pCol = [UIColor whiteColor];
                }

                NSString *sColString = [preferences valueForKey:@"LSSecondaryCol"];
                if (sColString) {
                    sCol = UIColorFromHexString(sColString);
                }
                else {
                    sCol = pCol;
                }

                if ([pCol isEqual:sCol] || [pColString isEqualToString:sColString]) {
                    sCol = [sCol colorWithAlphaComponent:0.5];
                }

                backgroundColourView.backgroundColor = bCol = [UIColor clearColor];
                backgroundColourView.hidden = YES;
            }
            else {
                static NSString *const CustomCoverColourisationNotification = @"CustomCoverLockScreenColourUpdateNotification";
                NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:pCol, @"PrimaryColour", sCol, @"SecondaryColour", bCol, @"BackgroundColour", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:CustomCoverColourisationNotification object:nil userInfo:userInfo];
            }

            [self _updateStatusBarLegibility];

            //TODO maybe dont need if legibility works
            /*
               if (self.bottomGrabberView.vibrantSettings.style == 0) {
                if (! cameraGrabberImage) {
                    UIView *lView;
                    if (self.cameraGrabberView.subviews.count > 0) {
                        lView = (UIView*)[self.cameraGrabberView.subviews objectAtIndex:0];
                    }

                    UIImageView *iv;
                    if (lView.subviews.count > 1) {
                        iv = [(lView).subviews objectAtIndex:1];
                    }

                    if (iv && [iv respondsToSelector:@selector(image)]) {
                        cameraGrabberImage = iv.image;
                    }
                }

                if (cameraGrabberImage) {
                    UIView *lView;
                    if (self.cameraGrabberView.subviews.count > 0) {
                        lView = (UIView*)[self.cameraGrabberView.subviews objectAtIndex:0];
                    }

                    UIImageView *iv;
                    if (lView.subviews.count > 1) {
                        iv = [(lView).subviews objectAtIndex:1];
                    }

                    if (iv && [iv respondsToSelector:@selector(image)]) {
                        iv.image = [cameraGrabberImage opaqueImageWithBurnTint:sCol];
                    }
                }

                if (! bottomGrabberColourView) {
                    bottomGrabberColourView = [[UIView alloc] initWithFrame:CGRectMake(0, 3.5, 36, 7)];
                    bottomGrabberColourView.layer.cornerRadius = 3.5;
                    bottomGrabberColourView.layer.masksToBounds = YES;
                }
                bottomGrabberColourView.backgroundColor = sCol;
                if (! [bottomGrabberColourView isDescendantOfView:self.bottomGrabberView]) {
                    [self.bottomGrabberView addSubview:bottomGrabberColourView];
                }

                if (! topGrabberColourView) {
                    topGrabberColourView = [[UIView alloc] initWithFrame:CGRectMake(0, 3.5, 36, 7)];
                    topGrabberColourView.layer.cornerRadius = 3.5;
                    topGrabberColourView.layer.masksToBounds = YES;
                }
                topGrabberColourView.backgroundColor = sCol;
                if (! [topGrabberColourView isDescendantOfView:self.topGrabberView]) {
                    [self.topGrabberView addSubview:topGrabberColourView];
                }
               }
               else {
                UIView *v1 = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
                v1.backgroundColor = sCol;
                v1.alpha = 1;
                [self.cameraGrabberView setBackgroundView:v1];
                UIView *v2 = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
                v2.backgroundColor = sCol;
                v2.alpha = 1;
                [self.topGrabberView setBackgroundView:v2];
                UIView *v3 = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
                v3.backgroundColor = sCol;
                v3.alpha = 1;
                [self.bottomGrabberView setBackgroundView:v3];
               }
             */
            id controlsT = [[self mediaControlsView].subviews objectAtIndex:0];
            if (! ([controlsT isKindOfClass: %c(_MPUSystemMediaControlsView)] || [controlsT isKindOfClass: %c(MPUSystemMediaControlsView)])) {
                return;
            }

            _MPUSystemMediaControlsView *controls = (_MPUSystemMediaControlsView*)controlsT;

            if ([[preferences valueForKey:@"LSControlBlending"] boolValue] && [[preferences valueForKey:@"ArtworkBG"] boolValue]) {
                if ([[preferences valueForKey:@"LSBackgroundMode"] intValue] == 1) {
                    [controls _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeMultiply];
                }
                else if ([[preferences valueForKey:@"LSBackgroundMode"] intValue] == 2) {
                    [controls _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
                }
                else {
                    [controls _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeOverlay];
                }
            }
            else {
                [controls _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
            }

            [controls.trackInformationView setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:pCol, NSForegroundColorAttributeName, nil]];
            [controls.trackInformationView setDetailTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:sCol, NSForegroundColorAttributeName, nil]];
            MSHookIvar<UIView*>(controls.trackInformationView, "_explicitImageView").tintColor = pCol;
            MSHookIvar<UILabel*>(controls.trackInformationView, "_detailLabel").alpha = 1;

            MPUChronologicalProgressView *timeView = controls.timeInformationView;

            UILabel *ctl = MSHookIvar<UILabel*>(timeView, "_currentTimeLabel");
            ctl.textColor = sCol;
            [ctl _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];

            UILabel *rtl = MSHookIvar<UILabel*>(timeView, "_remainingTimeLabel");
            rtl.textColor = sCol;
            [rtl _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];

            UISlider *slider = MSHookIvar<UISlider*>(timeView, "_slider");

            UIView *mxtv = MSHookIvar<UIView*>(slider, "_maxTrackView");
            mxtv.alpha = 1;
            [mxtv _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];

            UIView *mntv = MSHookIvar<UIView*>(slider, "_minTrackView");
            mntv.alpha = 1;
            [mntv _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];

            [slider setMaximumTrackImage:[slider.currentMaximumTrackImage opaqueImageWithBurnTint:sCol] forState:UIControlStateNormal];
            [slider setMinimumTrackImage:[slider.currentMinimumTrackImage opaqueImageWithBurnTint:pCol] forState:UIControlStateNormal];

            UIImageView *thumb = MSHookIvar<UIImageView*>(slider, "_thumbView");

            if (! lsScrubThumbView) {
                lsScrubThumbView = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 2, thumb.frame.size.height - 4)];
            }
            lsScrubThumbView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

            lsScrubThumbView.backgroundColor = pCol;

            if (! [lsScrubThumbView isDescendantOfView:thumb]) {
                [thumb addSubview:lsScrubThumbView];
            }

            MPUTransportControlsView *controlsView = controls.transportControlsView;
            if ([controlsView respondsToSelector:@selector(_updateTransportControlButtons)]) {                                                                                                                              // <8.4
                [controlsView _updateTransportControlButtons];
            }
            else {
                [controlsView layoutSubviews];
            }

            UISlider *volumeSlider = controls.volumeView.slider;

            if (! LSMaxVolImage) {
                LSMaxVolImage = volumeSlider.maximumValueImage;
            }
            if (! LSMinVolImage) {
                LSMinVolImage = volumeSlider.minimumValueImage;
            }

            if ( IS_IOS_(8,0)) {
                volumeSlider.minimumValueImage = [LSMinVolImage imageWithBurnTint:sCol];
                volumeSlider.maximumValueImage = [LSMaxVolImage imageWithBurnTint:sCol];
            }
            else {
                volumeSlider.minimumValueImage = [LSMinVolImage opaqueImageWithBurnTint:sCol];
                volumeSlider.maximumValueImage = [LSMaxVolImage opaqueImageWithBurnTint:sCol];
            }

            UIView *vsmniv = MSHookIvar<UIView*>(volumeSlider, "_minValueImageView");
            vsmniv.alpha = 1;
            [vsmniv _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];

            UIView *vsmxiv = MSHookIvar<UIView*>(volumeSlider, "_maxValueImageView");
            vsmxiv.alpha = 1;
            [vsmxiv _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];

            MSHookIvar<UIView*>(volumeSlider, "_maxTrackView").alpha = 1;
            MSHookIvar<UIView*>(volumeSlider, "_minTrackView").alpha = 1;

            if ( IS_IOS_(7,1)) {
                MSHookIvar<UIView*>(volumeSlider, "_maxTrackView").layer.cornerRadius = 1;
                MSHookIvar<UIView*>(volumeSlider, "_minTrackView").layer.cornerRadius = 1;
                MSHookIvar<UIView*>(volumeSlider, "_minTrackView").backgroundColor = pCol;

                [volumeSlider setMaximumTrackImage:[volumeSlider.currentMaximumTrackImage opaqueImageWithBurnTint:sCol] forState:UIControlStateNormal];
                [volumeSlider setMinimumTrackImage:[volumeSlider.currentMinimumTrackImage opaqueImageWithBurnTint:[UIColor clearColor]] forState:UIControlStateNormal];
            }
            else {
                [volumeSlider setMinimumTrackTintColor:pCol];
                [volumeSlider setMaximumTrackTintColor:sCol];
            }
            [volumeSlider setThumbImage:[[volumeSlider thumbImageForState:UIControlStateNormal] imageWithBurnTint:[pCol colorWithAlphaComponent:1]] forState:UIControlStateNormal];

            self.dateView.textColor = pCol;

            [self setLegibilitySettings:[[_UILegibilitySettings alloc] initWithStyle:0 primaryColor:pCol secondaryColor:sCol shadowColor:[UIColor clearColor]]];
        }];
    }
}

%new

- (BOOL)isMediaPluginActive {
    if (MSHookIvar<UIView*>(self, "_pluginView") != nil) {
        return [MSHookIvar<UIView *>(self, "_pluginView") isKindOfClass: %c(_NowPlayingArtView)];
    }
    else {
        return NO;
    }
}

%end

%hook MPUTransportControlsView

//7

- (void)_setImage : (id)arg1 forButton : (id)arg2 {
    %orig;
    if(!colorFlowLockscreenEnabled) {
        if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] || [[preferences valueForKey:@"ArtworkBG"] boolValue] || [preferences valueForKey:@"LSPrimaryCol"] != nil) {
            UIImage *imageToSet = [(UIImage*)arg1 imageWithBurnTint:pCol];
            [arg2 setImage:imageToSet forState:UIControlStateNormal];
            [arg2 setImage:imageToSet forState:UIControlStateHighlighted];
        }
    }
}

//<8.4

-(void) _configureButton:(id)arg1 withAttributes:(id)arg2 forTransportControl:(id)arg3 deferApplyingAttributes:(bool)arg4 {
    %orig;
    if(!colorFlowLockscreenEnabled) {
        if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] || [[preferences valueForKey:@"ArtworkBG"] boolValue] || [preferences valueForKey:@"LSPrimaryCol"] != nil) {
            MPUTransportButtonAttributes *at = (MPUTransportButtonAttributes*)arg2;
            UIButton *but = (UIButton*)arg1;
            UIImage *imageToSet = [at.image imageWithBurnTint:pCol];
            [but setImage:imageToSet forState:UIControlStateNormal];
            [but setImage:imageToSet forState:UIControlStateHighlighted];
        }
    }
}

-(void) _layoutButton:(id)arg1 withAttributes:(id)arg2 frame:(CGRect)arg3 inExpandedTouchRect:(CGRect)arg4 {
    %orig;
    if(!colorFlowLockscreenEnabled) {
        if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] || [[preferences valueForKey:@"ArtworkBG"] boolValue] || [preferences valueForKey:@"LSPrimaryCol"] != nil) {
            MPUTransportButtonAttributes *at = (MPUTransportButtonAttributes*)arg2;
            UIButton *but = (UIButton*)arg1;
            UIImage *imageToSet = [at.image imageWithBurnTint:pCol];
            [but setImage:imageToSet forState:UIControlStateNormal];
            [but setImage:imageToSet forState:UIControlStateHighlighted];
        }
    }
}

//8.4

-(void) _configureTransportButton:(id)arg1 forTransportControl:(id)arg2 {
    UIButton *b = arg1;
    if(!colorFlowLockscreenEnabled) {
        if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] || [[preferences valueForKey:@"ArtworkBG"] boolValue] || [preferences valueForKey:@"LSPrimaryCol"] != nil) {
            if (((_MPUSystemMediaControlsView*)self.superview).style == 2) {
                b.tintColor = pCol;
                if ([b respondsToSelector:@selector(imageForState:)]) {
                    [b setImage:[[b imageForState:UIControlStateNormal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                }
                else if ([b respondsToSelector:@selector(setRegularImageColor:)]) {
                    [(MPUHalfTintedTransportButton*)b setRegularImageColor:pCol];
                }
            }
        }
    }
    %orig(b, arg2);
}

%end

%hook SBLockScreenPlugin

- (void)setOverlay : (id)arg1 {
    if ([self.bundleName isEqual:@"NowPlayingArtLockScreen"] && !colorFlowLockscreenEnabled) {
        preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
        BOOL blurOrColor = [[preferences valueForKey:@"ArtworkBG"] boolValue] || [[preferences valueForKey:@"colourFromArtwork"] boolValue];
        BOOL noBlur = [[preferences valueForKey:@"NoBlur"] boolValue] && ! [[preferences valueForKey:@"ArtworkBG"] boolValue] && ! [[preferences valueForKey:@"colourFromArtwork"] boolValue];
        if (blurOrColor || noBlur) {}
        else {
            %orig;
        }
    }
    else {
        %orig;
    }
}

%end

%hook MPUNowPlayingTitlesView

- (void)layoutSubviews {
    %orig;
    if (!colorFlowLockscreenEnabled && ! [self isKindOfClass: %c(MusicNowPlayingTitlesView)] && ! [self.superview.superview.superview isKindOfClass: %c(SBControlCenterSectionView)]) {
        if ([[preferences valueForKey:@"colourFromArtwork"] boolValue] || [[preferences valueForKey:@"ArtworkBG"] boolValue]  || [preferences valueForKey:@"LSPrimaryCol"] != nil) {
            MSHookIvar<UIView*>(self, "_explicitImageView").tintColor = pCol;
        }
        else {
            MSHookIvar<UIView*>(self, "_explicitImageView").tintColor = [UIColor whiteColor];
        }
    }
    else {
        MSHookIvar<UIView*>(self, "_explicitImageView").tintColor = [UIColor whiteColor];
    }
}

-(void) setExplicitImage:(id)arg1 {
    UIImage *o = arg1;
    if(!colorFlowLockscreenEnabled) {
        o = [o imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    %orig(o);
}

%end

%end //CustomCoverLockScreen

////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////

static CCMusicAppView  *musicCCContainerView;
static UIImage *volMinImg;
static UIImage *volMaxImg;

static UIColor *musicBCol;
static UIColor *musicPCol;
static UIColor *musicSCol;

static UIImage *musicCurrentArtwork;

%group CustomCoverMusicApp

static UIImageView  *musicBlurredBGView;

static UIView *scrubThumbView;
static UIImage *volSliderBaseImage;

static UINavigationBar *navBar;

static NSString *oldThemeName;

static BOOL musicColoursReset;
static BOOL flipsideActive;

static NSObject *MusicIDNumberObject = [NSObject new];

static long long activeBlendMode;

static UIImage *verifiedAlbumArtwork(UIImage *artwork) {
    if (! artwork) {
        artwork = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@/%@/Default.png", baseDirectory, musicSelectedThemeName, deviceNameM]];
    }
    if (! artwork) {
        artwork = [UIImage filledImageWithColor:[UIColor whiteColor] andSize:CGSizeMake(1, 1)];
    }
    return artwork;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

%hook MusicNowPlayingPlaybackControlsView

- (void)layoutSubviews {
    %orig;
    if (([[preferences valueForKey:@"MusicArtworkBG"] boolValue] || [[preferences valueForKey:@"MusicColourFromArtwork"] boolValue]) && [self.backgroundColor isEqual:[UIColor clearColor]]) {
        self.backgroundColor = musicBCol;
    }

    UIButton *createButton = MSHookIvar<MPButton*>(self, "_createButton");
    MPButton *repeatButton = MSHookIvar<MPButton*>(self, "_repeatButton");
    MPButton *shuffleButton = MSHookIvar<MPButton*>(self, "_shuffleButton");

    repeatButton.tintColor = musicSCol;
    shuffleButton.tintColor = musicSCol;
    createButton.tintColor = musicSCol;

    if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue] && [[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 2) {
        [createButton _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
        [shuffleButton _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
        [repeatButton _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
    }
    else {
        [createButton _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
        [shuffleButton _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
        [repeatButton _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
    }
}

%new

- (void)updateColoursAnimated : (BOOL)animated {
    UIView *controls = MSHookIvar<UIView*>(self, "_transportControls");
    if (controls == nil) {
        return;
    }

    for (UIView *s in controls.subviews) {
        if ([s isKindOfClass: %c(MPTransportButton)]) {
            [(MPTransportButton*)s updateColours];
        }
    }

    UISlider *progressSlider = MSHookIvar<UISlider*>(self, "_progressControl");
    if (progressSlider == nil) {
        return;
    }

    MusicNowPlayingVolumeSlider *volumeSlider = MSHookIvar<MusicNowPlayingVolumeSlider*>(self, "_volumeSlider");
    if (volumeSlider == nil) {
        return;
    }
    UIView *vMaxTrack = MSHookIvar<UIView*>(volumeSlider, "_maxTrackView");

    CGFloat duration = 0.2;
    if (! animated) {
        duration = 0;
    }

    [UIView animateWithDuration:duration animations:^{
        self.backgroundColor = musicBCol;

        UIImageView *vMinTrack = MSHookIvar<UIImageView*>(volumeSlider, "_minTrackView");

        vMaxTrack.backgroundColor = musicSCol;
        [volumeSlider setMaximumTrackImage:[volumeSlider.currentMaximumTrackImage filledImageWithColor:musicSCol] forState:UIControlStateNormal];

        if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue] && [[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 2) {
            [vMaxTrack _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
            [vMinTrack _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
        }
        else {
            [vMaxTrack _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
            [vMinTrack _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
        }

        [volumeSlider setMinimumTrackImage:[volumeSlider.currentMinimumTrackImage filledImageWithColor:musicPCol] forState:UIControlStateNormal];
        vMinTrack.layer.cornerRadius = 1.5;
        vMaxTrack.layer.cornerRadius = 1.5;

        if (! volSliderBaseImage) {
            volSliderBaseImage = [volumeSlider thumbImageForState:UIControlStateNormal];
        }

        if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue] && [[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 1) {
            [volumeSlider setThumbImage:volSliderBaseImage forState:UIControlStateNormal];
        }
        else {
            [volumeSlider setThumbImage:[volSliderBaseImage imageWithBurnTint:[musicPCol colorWithAlphaComponent:1]] forState:UIControlStateNormal];
        }

        if (! volMinImg) {
            volMinImg = volumeSlider.minimumValueImage;
        }
        if (! volMaxImg) {
            volMaxImg = volumeSlider.maximumValueImage;
        }

        if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue] && [[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 2) {
            UIImageView *minView =  MSHookIvar<UIImageView*>(volumeSlider, "_minValueImageView");
            [minView _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
            volumeSlider.minimumValueImage = [volMinImg opaqueImageWithBurnTint:musicSCol];

            UIImageView *maxView =  MSHookIvar<UIImageView*>(volumeSlider, "_maxValueImageView");
            [maxView _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
            volumeSlider.maximumValueImage = [volMaxImg opaqueImageWithBurnTint:musicSCol];
        }
        else {
            UIImageView *maxView =  MSHookIvar<UIImageView*>(volumeSlider, "_maxValueImageView");
            UIImageView *minView =  MSHookIvar<UIImageView*>(volumeSlider, "_minValueImageView");
            [minView _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
            [maxView _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
            volumeSlider.minimumValueImage = [volMinImg opaqueImageWithBurnTint:musicSCol];
            volumeSlider.maximumValueImage = [volMaxImg opaqueImageWithBurnTint:musicSCol];
        }
    }];
}

%new

- (void)resetColours {
    activeBlendMode = kCGBlendModeNormal;

    UISlider *progressSlider = MSHookIvar<UISlider*>(self, "_progressControl");
    MusicNowPlayingVolumeSlider *volumeSlider = MSHookIvar<MusicNowPlayingVolumeSlider*>(self, "_volumeSlider");
    UIView *vMaxTrack = MSHookIvar<UIView*>(volumeSlider, "_maxTrackView");

    [scrubThumbView removeFromSuperview];
    scrubThumbView = nil;

    UIView *controls = MSHookIvar<UIView*>(self, "_transportControls");
    for (UIView *s in controls.subviews) {
        if ([s isKindOfClass: %c(MPTransportButton)]) {
            [(MPTransportButton*)s resetColours];
        }
    }

    [UIView animateWithDuration:0.2f animations:^{
        musicCCContainerView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];

        UILabel *l1 = MSHookIvar<UILabel*>(progressSlider, "_currentTimeLabel");
        UILabel *l2 = MSHookIvar<UILabel*>(progressSlider, "_currentTimeInverseLabel");

        l1.textColor = [UIColor blackColor];
        l2.textColor = [UIColor blackColor];
        [progressSlider setMaximumTrackImage:[progressSlider.currentMaximumTrackImage filledImageWithColor:[UIColor colorWithWhite:0 alpha:0.2]] forState:UIControlStateNormal];
        MSHookIvar<UIImageView*>(progressSlider, "_minTrackView").alpha = 1;
        [progressSlider setMinimumTrackImage:[progressSlider.currentMinimumTrackImage filledImageWithColor:[UIColor colorWithWhite:0 alpha:0.2]] forState:UIControlStateNormal];

        UIView *vMinTrack = MSHookIvar<UIImageView*>(volumeSlider, "_minTrackView");

        [volumeSlider setMaximumTrackImage:[volumeSlider.currentMaximumTrackImage filledImageWithColor:[UIColor colorWithWhite:0 alpha:0.2]] forState:UIControlStateNormal];
        vMaxTrack.layer.cornerRadius = 1.5;
        vMinTrack.alpha = 1;

        [volumeSlider setMinimumTrackImage:[volumeSlider.currentMinimumTrackImage filledImageWithColor:[UIColor blackColor]] forState:UIControlStateNormal];
        vMinTrack.layer.cornerRadius = 1.5;

        if (! volMinImg) {
            volMinImg = volumeSlider.minimumValueImage;
        }
        if (! volMaxImg) {
            volMaxImg = volumeSlider.maximumValueImage;
        }

        volumeSlider.minimumValueImage = volMinImg;
        volumeSlider.maximumValueImage = volMaxImg;

        MPButton *createButton = MSHookIvar<MPButton*>(self, "_createButton");
        MPButton *infoButton = MSHookIvar<MPButton*>(self, "_infoButton");
        MPButton *repeatButton = MSHookIvar<MPButton*>(self, "_repeatButton");
        MPButton *shuffleButton = MSHookIvar<MPButton*>(self, "_shuffleButton");

        [repeatButton resetColours];
        [shuffleButton resetColours];

        createButton.tintColor = [%c(MusicTheme) tintColor];
        infoButton.tintColor = [UIColor blackColor];

        if (! volSliderBaseImage) {
            volSliderBaseImage = [volumeSlider thumbImageForState:UIControlStateNormal];
        }
        [volumeSlider setThumbImage:volSliderBaseImage forState:UIControlStateNormal];
    }];
}

%end

%hook MusicNowPlayingViewController

- (void)willRotateToInterfaceOrientation : (NSInteger)arg1 duration : (CGFloat)arg2 {
    %orig;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [UIView animateWithDuration:arg2 animations:^{
            if (arg1 == UIInterfaceOrientationLandscapeLeft || arg1 == UIInterfaceOrientationLandscapeRight) {
                musicBlurredBGView.frame = CGRectMake(0, 0, 1024, 768);
            }
            else {
                musicBlurredBGView.frame = CGRectMake(0, 0, 768, 1024);
            }
        }];
    }
}

-(void) _updateForCurrentItemAnimated:(BOOL)arg1 {
    if (! [musicSelectedThemeName isEqual:@"Default"]) {
        %orig(NO);
    }
    else {
        %orig;
    }
}

-(void) _updateContentView:(id)arg1 forItem:(id)arg2 {
    if (!  IS_IOS_(7,1)) {
        MPAVItem *item = arg2;
        musicCurrentArtwork = verifiedAlbumArtwork([UIImage imageWithData:item.artworkImageData]);
        objc_setAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork, [NSString stringWithFormat:@"%lu", (long)item.persistentID], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        %orig;

        [self updateMusicImage];

        if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
            [self updateColours];
            musicColoursReset = NO;
        }
        else if (! musicColoursReset) {
            [self resetColours];
        }
    }
    else {
        %orig;
    }
}

-(id) _createContentViewForItem:(id)arg1 contentViewController:(id*)arg2 {
    UIImageView *o = %orig;

    id item = arg1;
    if (IS_IOS_(8,0)) {
        if ([item isKindOfClass: %c(MPRadioAVItem)]) {
            MPRadioAVItem *mitem = (MPRadioAVItem*)item;
            musicCurrentArtwork = verifiedAlbumArtwork([UIImage imageWithData:[NSData dataWithContentsOfURL:((RadioArtwork*)[mitem.radioTrack.artworkCollection bestArtworkForPointSize:CGSizeMake(320, 320)]).URL]]);
            objc_setAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork, [NSString stringWithFormat:@"%lu", (long)mitem.persistentID], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        else {
            MPAVItem *mitem = (MPAVItem*)item;
            musicCurrentArtwork = verifiedAlbumArtwork([mitem.mediaItem.artwork imageWithSize:CGSizeMake(320, 320)]);
            objc_setAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork, [NSString stringWithFormat:@"%lu", (long)mitem.persistentID], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    else if (IS_IOS_(7,1)) {
        if ([item isKindOfClass: %c(MPRadioAVItem)]) {
            MPRadioAVItem *mitem = (MPRadioAVItem*)item;
            musicCurrentArtwork = verifiedAlbumArtwork([UIImage imageWithData:[NSData dataWithContentsOfURL:((RadioArtwork*)[mitem.radioTrack.artworkCollection bestArtworkForPointSize:CGSizeMake(320, 320)]).URL]]);
            objc_setAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork, [NSString stringWithFormat:@"%lu", (long)mitem.persistentID], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        else {
            MPAVItem *mitem = (MPAVItem*)item;
            musicCurrentArtwork = verifiedAlbumArtwork([mitem.mediaItem.artwork albumImageWithSize:CGSizeMake(320, 320)]);
            objc_setAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork, [NSString stringWithFormat:@"%lu", (long)mitem.persistentID], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    else {
        MPAVItem *mitem = (MPAVItem*)item;
        musicCurrentArtwork = verifiedAlbumArtwork([UIImage imageWithData:mitem.artworkImageData]);
        objc_setAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork, [NSString stringWithFormat:@"%lu", (long)mitem.persistentID], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    @try {
        [o removeObserver:self forKeyPath:@"image"];
    }
    @catch (NSException *exception) {}

    [self createViews];

    [self updateMusicImage];

    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        if (MSHookIvar<MPAVItem*>(self, "_item") != nil) {
            [self updateColours];
        }
        musicColoursReset = NO;
    }
    else if (! musicColoursReset) {
        [self resetColours];
    }

    if (! [musicSelectedThemeName isEqual:@"Default"]) {
        for (UIGestureRecognizer *recognizer in o.gestureRecognizers) {
            [musicCCContainerView addGestureRecognizer:recognizer];
            [o removeGestureRecognizer:recognizer];
        }

        UIView *lyrics = MSHookIvar<UIView*>(self, "_lyricsView");
        if (lyrics) {
            [lyrics removeFromSuperview];
            lyrics = nil;
        }
        return musicCCContainerView;
    }
    else {
        return %orig;
    }
}

-(void) viewWillAppear:(BOOL)arg1 {
    %orig;
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        [self performSelector:@selector(updateColoursAnimated:) withObject:[NSNumber numberWithInt:0] afterDelay:0.05];

        if (self.navigationController.navigationBar) {
            navBar = self.navigationController.navigationBar;
        }
        if (navBar) {
            navBar.tag = 1238973798;
            MSHookIvar<UIView*>(navBar, "_backgroundView").hidden = YES;
            MSHookIvar<UIView*>(navBar, "_backIndicatorView").tag = 1238973798;
            [MSHookIvar<UIView *>(navBar, "_backIndicatorView")layoutSubviews];
            navBar.tintColor = musicPCol;
        }
        UINavigationBar *padNB = MSHookIvar<UINavigationBar*>(self, "_padFakeNavigationBar");
        if (padNB) {
            padNB.tag = 1238973798;
            MSHookIvar<UIView*>(padNB, "_backIndicatorView").tag = 1238973798;
            [MSHookIvar<UIView *>(padNB, "_backIndicatorView")layoutSubviews];
        }

        UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
        sb.tag = 127123998;
        sb.foregroundColor = musicPCol;
    }
}

-(void) viewWillDisappear:(BOOL)arg1 {
    %orig;

    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
        sb.tag = nil;
        sb.foregroundColor = [UIColor blackColor];
        if (navBar) {
            navBar.tag = nil;
            MSHookIvar<UIView*>(navBar, "_backIndicatorView").tag = nil;
            [MSHookIvar<UIView *>(navBar, "_backIndicatorView")layoutSubviews];
            [UIView animateWithDuration:0.2 animations:^{
                navBar.tintColor = [%c(MusicTheme) tintColor];
            }];
            MSHookIvar<UIView*>(navBar, "_backgroundView").hidden = NO;
        }

        UINavigationBar *padNB = MSHookIvar<UINavigationBar*>(self, "_padFakeNavigationBar");
        if (padNB) {
            padNB.tag = nil;
            [UIView animateWithDuration:0.2 animations:^{
                padNB.tintColor = [%c(MusicTheme) tintColor];
            }];
        }
    }
}

-(void) viewDidLayoutSubviews {
    %orig;
    if (musicCCContainerView && UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if ([UIScreen mainScreen].bounds.size.height == 480) {
            musicCCContainerView.frame = CGRectMake(0, 64, 320, 265);
        }
        else {
            musicCCContainerView.frame = CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
        }
    }
}

-(void) _infoButtonAction:(id)arg1 {
    %orig;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        flipsideActive = YES;
        if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
            UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
            sb.foregroundColor = [UIColor blackColor];
        }
    }
}

-(void) stationActionsViewController:(id)arg1 didFinishAction:(NSInteger)arg2 withObject:(id)arg3 error:(id)arg4 {
    %orig;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        flipsideActive = NO;
        if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
            UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
            sb.foregroundColor = musicPCol;
        }
    }
}

%new

- (void)createViews {
    if (musicSelectedThemeName == nil) {
        musicSelectedThemeName = @"Default";
    }

    if (! [musicSelectedThemeName isEqual:@"Default"]) {
        if (! [oldThemeName isEqual:musicSelectedThemeName] && musicCCContainerView) {
            [musicCCContainerView removeFromSuperview];
            musicCCContainerView = nil;
            oldThemeName = musicSelectedThemeName;
        }

        if (! musicCCContainerView) {
            [self createMainView];
        }
    }
    else {
        [self performSelector:@selector(removeMainView) withObject:nil afterDelay:0.2];
    }

    if (! [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        if (musicBlurredBGView) {
            [self performSelector:@selector(removeBGView) withObject:nil afterDelay:0.2];
        }
    }
    else {
        if (! musicBlurredBGView) {
            [self createBGView];
        }

        if (! [musicBlurredBGView isDescendantOfView:self.view]) {
            [self.view insertSubview:musicBlurredBGView belowSubview:MSHookIvar < MusicNowPlayingPlaybackControlsView  *> (self, "_playbackControlsView")];
        }
    }
}

%new

- (void)updateMusicImage {
    if (musicCCContainerView) {
        [musicCCContainerView updateWithImage:musicCurrentArtwork];
    }

    if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        UIImage *imageForBG = musicCurrentArtwork;

        if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 2) {
            imageForBG = [imageForBG scaledToSize:CGSizeMake(320, 320)];
            if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 1) {
                imageForBG = [imageForBG  musicLightBlurredImage];
            }
            else {
                imageForBG = [imageForBG musicDarkBlurredImage];
            }
        }

        if (musicBlurredBGView) {
            [UIView transitionWithView:musicBlurredBGView
             duration:0.2f
             options:UIViewAnimationOptionTransitionCrossDissolve
             animations:^{
                musicBlurredBGView.image = imageForBG;
            } completion:nil];
        }
    }

    if (%c(PNMusica)) {
        PNMusica *aria = [%c(PNMusica) sharedInstance];
        [UIView transitionWithView:aria.backgroundAlbumArtImageView duration:0.2f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            aria.backgroundAlbumArtImageView.image = [aria backgroundImageWithImage:musicCurrentArtwork];
        } completion:nil];
    }
}

%new

- (void)updateColours {
    [self updateColoursAnimated:YES];
}

%new

- (void)updateColoursAnimated : (BOOL)animated {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue]) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:cacheDirectory];
        if (! dic) {
            dic = [[NSMutableDictionary alloc] init];
        }

        NSString *songID = objc_getAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork);
        if ([dic valueForKey:[NSString stringWithFormat:@"%@", songID]] && songID != nil) {
            NSDictionary *subDic = [dic valueForKey:[NSString stringWithFormat:@"%@", songID]];
            musicPCol = UIColorFromHexString([subDic valueForKey:@"Primary"]);
            musicSCol = UIColorFromHexString([subDic valueForKey:@"Secondary"]);
            musicBCol = UIColorFromHexString([subDic valueForKey:@"Background"]);
        }
        else {
            SLColorArt *colours = [[SLColorArt alloc] initWithImage:[currentArtwork scaledToSize:CGSizeMake(200, 200)]];
            musicPCol = colours.primaryColor;
            musicSCol = colours.secondaryColor;
            musicBCol = colours.backgroundColor;

            if (songID) {
                NSArray *keys = [NSArray arrayWithObjects:@"Primary", @"Secondary", @"Background", nil];
                NSArray *colourArray = [NSArray arrayWithObjects:HexStringFromUIColor(musicPCol), HexStringFromUIColor(musicSCol), HexStringFromUIColor(musicBCol), nil];
                NSDictionary *subDic = [NSDictionary dictionaryWithObjects:colourArray forKeys:keys];
                [dic setValue:subDic forKey:songID];
                [dic writeToFile:cacheDirectory atomically:YES];
            }
        }
    }
    else if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 1) {  // LIGHT BLUR
        musicPCol = [UIColor colorWithWhite:0 alpha:0.75];
        musicSCol = [UIColor colorWithWhite:0.8 alpha:1];
        musicBCol = [UIColor colorWithWhite:1 alpha:0.3];
        activeBlendMode = kCGBlendModeMultiply;
    }
    else if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 2) {  // NO BLUR
        musicPCol = [UIColor colorWithWhite:1 alpha:0.75];
        musicSCol = [UIColor colorWithWhite:1 alpha:0.5];
        musicBCol = [UIColor colorWithWhite:0 alpha:0.8];
    }
    else {                                                                        // DARK BLUR
        musicPCol = [UIColor colorWithWhite:1 alpha:0.75];
        musicSCol = [UIColor colorWithWhite:0.7 alpha:1];
        musicBCol = [UIColor colorWithWhite:0 alpha:0.7];
        activeBlendMode = kCGBlendModeOverlay;
    }

    MusicNowPlayingPlaybackControlsView *m = MSHookIvar<MusicNowPlayingPlaybackControlsView*>(self, "_playbackControlsView");

    if (m != nil) {
        [m updateColoursAnimated:animated];
    }

    CGFloat duration = 0.2;
    if (! animated) {
        duration = 0;
    }

    [UIView animateWithDuration:duration animations:^{
        if (! flipsideActive) {
            UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
            if (sb != nil) {
                sb.foregroundColor = musicPCol;
            }
        }

        navBar = self.navigationController.navigationBar;
        if (navBar != nil) {
            navBar.tintColor = musicPCol;
            MSHookIvar<UIView*>(navBar, "_backgroundView").hidden = YES;
            MSHookIvar<UINavigationBar*>(self, "_padFakeNavigationBar").tintColor = musicPCol;

            UILabel *label = MSHookIvar<UILabel*>(navBar, "_titleView");
            if (label != nil) {
                if ([label respondsToSelector:@selector(setTextColor:)]) {
                    if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue] && [[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 2) {
                        label.textColor = musicSCol;
                        [label _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
                    }
                    else {
                        label.textColor = musicSCol;
                        [label _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
                    }
                }
            }
        }

        MusicNowPlayingTitlesView *titles = MSHookIvar<MusicNowPlayingTitlesView*>(self, "_titlesView");
        if (titles != nil) {
            if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue] && [[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 2) {
                MSHookIvar<UILabel*>(titles, "_detailLabel").textColor = musicSCol;                                                                                                                                                                                                                                                       //OverlayGrey;
                [MSHookIvar<UILabel *>(titles, "_detailLabel") _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
            }
            else {
                MSHookIvar<UILabel*>(titles, "_detailLabel").textColor = musicSCol;
                [MSHookIvar<UILabel *>(titles, "_detailLabel") _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
            }

            MSHookIvar<UILabel*>(titles, "_titleLabel").textColor = musicPCol;
            MSHookIvar<UIImageView*>(titles, "_explicitImageView").tintColor = musicPCol;
        }
    }];
}

%new

- (void)createMainView {
    CGRect screenBounds = CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);

    if ([UIScreen mainScreen].bounds.size.height == 480) {
        screenBounds = CGRectMake(0, 64, 320, 265);
    }

    CGPoint centreOfScreen = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 3);

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect tempScreenBounds;
        if (isLandscape()) {
            tempScreenBounds = CGRectMake(0, 0, 1024, 768);
        }
        else {
            tempScreenBounds = CGRectMake(0, 0, 768, 1024);
        }
        CGPoint tempCentre = CGPointMake(tempScreenBounds.size.width / 2, tempScreenBounds.size.height / 2);
        screenBounds = CGRectMake(tempCentre.x - 250, tempCentre.y - 250, 500, 500);
        centreOfScreen = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 1.9);
    }
    UIInterfaceOrientation o;
    if(isLandscape())
        o = UIInterfaceOrientationLandscapeLeft;
    else
        o = UIInterfaceOrientationPortrait;
    musicCCContainerView = [[CCMusicAppView alloc] initWithPreferences:preferences orientation:o];
    [musicCCContainerView updateWithImage:musicCurrentArtwork];
}

%new

- (void)createBGView {
    CGRect frame = self.view.frame;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (isLandscape()) {
            frame = CGRectMake(0, 0, 1024, 768);
        }
        else {
            frame = CGRectMake(0, 0, 768, 1024);
        }
    }
    musicBlurredBGView = [[UIImageView alloc] initWithFrame:frame];
    musicBlurredBGView.contentMode = UIViewContentModeScaleAspectFill;
    musicBlurredBGView.layer.masksToBounds = YES;
}

%new

- (void)removeBGView {
    if (musicBlurredBGView) {
        [musicBlurredBGView removeFromSuperview];
        musicBlurredBGView = nil;
    }
}

%new

- (void)removeMainView {
    if (musicCCContainerView) {
        [musicCCContainerView removeFromSuperview];
        musicCCContainerView = nil;
    }
}

%new

- (void)resetColours {
        musicColoursReset = YES;
        [self removeBGView];

        [MSHookIvar<MusicNowPlayingPlaybackControlsView *>(self, "_playbackControlsView") resetColours];

        [UIView animateWithDuration:0.2f animations:^{
            UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
            sb.foregroundColor = [UIColor blackColor];

            UINavigationBar *navBar =  self.navigationController.navigationBar;
            navBar.tintColor = [%c(MusicTheme) tintColor];
            navBar.tag = nil;
            MSHookIvar<UINavigationBar*>(self, "_padFakeNavigationBar").tintColor = [%c(MusicTheme) tintColor];
            MSHookIvar<UINavigationBar*>(self, "_padFakeNavigationBar").tag = nil;

            MSHookIvar<UIView*>(navBar, "_backgroundView").hidden = NO;

            UILabel *label = MSHookIvar<UILabel*>(navBar, "_titleView");
            if ([label respondsToSelector:@selector(setTextColor:)]) {
                label.textColor = [UIColor blackColor];
            }

            UIView *titles = MSHookIvar<UIView*>(self, "_titlesView");
            MSHookIvar<UILabel*>(titles, "_titleLabel").textColor = [UIColor blackColor];
            MSHookIvar<UILabel*>(titles, "_detailLabel").textColor = [UIColor blackColor];
            UIImage *img = MSHookIvar<UIImage*>(titles, "_explicitImage");
            img = [img imageWithBurnTint:[UIColor blackColor]];
        }];
}

%end

%hook MPURatingControl

- (void)layoutSubviews {
    %orig;
    [self fixColours];
}

-(void) _updateImageViewsForRatingAnimated:(BOOL)arg1 {
    %orig;
    [self fixColours];
}

%new

- (void)fixColours {
    if (self.superview) {
        if (([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) && ! [self.superview isKindOfClass: %c(UITableViewCellContentView)]) {
            for (UIImageView *iv in MSHookIvar<NSMutableArray*>(self, "_imageViews")) {
                iv.image = [iv.image imageWithBurnTint:musicPCol];
            }
        }
    }
}

%end

%hook MPTransportButton

- (void)setTintColor : (id)col {
    if (([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) && [self.superview isKindOfClass: %c(MusicNowPlayingTransportControls)]) {
        if ([col isEqual:musicPCol]) {
            %orig;
        }
    }
    else {
        %orig;
    }
}

%new

- (void)updateColours {
    [UIView animateWithDuration:0.2f animations:^{
        if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
            self.tintColor = musicPCol;
        }
    }];
}

%new

- (void)resetColours {
    self.tintColor = [UIColor blackColor];
}

%end

%hook MusicFlipsideTracksViewController

- (void)viewWillAppear : (BOOL)arg1 {
    %orig;
    flipsideActive = YES;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self performSelector:@selector(fixStuff) withObject:nil afterDelay:0.1];
    }
    else {
        UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
        sb.foregroundColor = [UIColor blackColor];
    }
}

-(void) viewWillDisappear:(BOOL)arg1 {
    %orig;
    flipsideActive = NO;
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
        sb.foregroundColor = musicPCol;
    }
}

%new

- (void)fixStuff {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        UIStatusBar *sb = MSHookIvar<UIStatusBar*>([%c(UIApplication) sharedApplication], "_statusBar");
        sb.foregroundColor = [UIColor blackColor];
        UIView *v = MSHookIvar<UIView*>(self, "_segmentedControl").superview;
        if (v) {
            UIView *v2 = MSHookIvar<UIView*>(v, "__backgroundView");
            if (v2) {
                ((UIView*)[v2.subviews objectAtIndex:0]).hidden = YES;
            }
        }
    }
}

%end

%hook MPButton

- (void)setTitleColor : (id)arg1 forState : (unsigned)arg2 {
    if ([arg1 isEqual:[%c(MusicTheme) tintColor]]) {
        if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
            %orig(musicSCol, arg2);
        }
        else {
            %orig;
        }
    }
    else {
        %orig;
    }
}

%end

%hook MusicNowPlayingVolumeSlider

- (void)_updateTrackTintForVolumeControlAvailability {
    %orig;
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        [self setMinimumTrackImage:[self.currentMinimumTrackImage filledImageWithColor:musicPCol] forState:UIControlStateNormal];
    }
}

%end

%hook MPUVignetteBackgroundView

- (id)initWithFrame : (CGRect)arg1  {
    if (!  IS_IOS_(8,0)) {
        UIView *o = %orig;
        MSHookIvar<UIView*>(o, "_imageView").hidden = YES;
        return o;
    }
    else {
        return %orig;
    }
}

%end

%hook MPUNowPlayingTitlesView // MusicNowPlayingTitlesView

- (void)layoutSubviews {
    %orig;
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        MSHookIvar<UIView*>(self, "_explicitImageView").tintColor = musicPCol;
    }
    else {
        MSHookIvar<UIView*>(self, "_explicitImageView").tintColor = [UIColor blackColor];
    }
}

-(void) setExplicitImage:(id)arg1 {
    UIImage *o = arg1;
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        o = [o imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    %orig(o);
}

%end

%hook MPDetailSlider

- (void)layoutSubviews {
    %orig;

    UIImageView *minTrack = MSHookIvar<UIImageView*>(self, "_minTrackView");
    UIImageView *maxTrack = MSHookIvar<UIImageView*>(self, "_maxTrackView");
    UILabel *l1 = MSHookIvar<UILabel*>(self, "_currentTimeLabel");
    UILabel *l2 = MSHookIvar<UILabel*>(self, "_currentTimeInverseLabel");

    if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue] && [[preferences valueForKey:@"MusicBackgroundMode"] intValue] != 2) {
        [l1 _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
        [l2 _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
        [minTrack _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
        [maxTrack _setDrawsAsBackdropOverlayWithBlendMode:activeBlendMode];
    }
    else {
        [l1 _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
        [l2 _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
        [maxTrack _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
        [minTrack _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
    }
}

-(id) timeLabelTextColorForStyle:(long long)arg1 {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        return musicSCol;
    }
    else {
        return %orig;
    }
}

-(void) setMinimumTrackImage:(id)arg1 forState:(unsigned)arg2 {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        %orig([arg1 filledImageWithColor:musicPCol], arg2);
    }
    else {
        %orig;
    }
}

-(void) setMaximumTrackImage:(id)arg1 forState:(unsigned)arg2 {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        %orig([arg1 filledImageWithColor:musicSCol], arg2);
    }
    else {
        %orig;
    }
}

-(id) _modernThumbImageWithColor:(id)arg1 height:(CGFloat)arg2 includeShadow:(bool)arg3 {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        return %orig(musicPCol, arg2, arg3);
    }
    else {
        return %orig;
    }
}

%end

%hook MusicTheme

+ (id)tintColor {
    if ([preferences valueForKey:@"MusicTintColour"]) {
        NSString *s = [preferences valueForKey:@"MusicTintColour"];
        if (! [s isEqual:@"#FF2D55"]) {
            return UIColorFromHexString(s);
        }
        else {
            return %orig;
        }
    }
    else {
        return %orig;
    }
}

%end

%end //CustomCoverMusicApp

%group CustomCoverMusicApp_8_4

static UIView  *tempBackgroundViewPointer = nil;

%hook MusicNowPlayingItemViewController

- (void) _setArtworkImage:(UIImage *)arg1 {
    %orig;
    musicCurrentArtwork = verifiedAlbumArtwork(arg1);
    if (musicCCContainerView != nil && ! [musicSelectedThemeName isEqual:@"Default"]) {
        UIImageView *artView = MSHookIvar<UIImageView *>(self, "_imageView");
        artView.image = nil;
        [musicCCContainerView updateWithImage:musicCurrentArtwork];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateArtworkCustomCover" object:self];
}

-(void) viewDidLoad {
    %orig;
    if (! [musicSelectedThemeName isEqual:@"Default"]) {
        UIInterfaceOrientation o;
        if(isLandscape())
            o = UIInterfaceOrientationLandscapeLeft;
        else
            o = UIInterfaceOrientationPortrait;
        musicCCContainerView = [[CCMusicAppView alloc] initWithPreferences:preferences orientation:o];
        UIImageView *artView = MSHookIvar<UIImageView*>(self, "_imageView");
        artView.backgroundColor = [UIColor clearColor];
        artView.image = nil;
        artView.clipsToBounds = NO;
        [artView addSubview:musicCCContainerView];
        [musicCCContainerView updateWithImage:[self artworkImage]];
    }
}

%end

%hook MusicNowPlayingViewController

-(void) viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateColours) name:@"UpdateArtworkCustomCover" object:self.currentItemViewController];
}

-(void) viewDidAppear:(BOOL)arg1 {
    %orig;
    [self updateColours];
}

-(void) _updateBackgroundEffects {
    if (! ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue])) {
        %orig;
    }
}

-(void) _showUpNext:(id)arg1 {
    %orig;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        tempBackgroundViewPointer = self.vibrantEffectView;
        if (musicCCContainerView != nil) {
            [UIView transitionWithView:musicCCContainerView
             duration:0.2f
             options:UIViewAnimationOptionTransitionCrossDissolve
             animations:^{
                musicCCContainerView.alpha = 0;
                self.vibrantEffectView.backgroundColor = [UIColor clearColor];
            } completion:^(BOOL completed) {
                if (completed) {
                    musicCCContainerView.hidden = YES;
                }
            }];
        }
    }
}

%new

-(void)updateColours {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue]) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:cacheDirectory];
        if (! dic) {
            dic = [[NSMutableDictionary alloc] init];
        }

        NSString *songID = objc_getAssociatedObject(MusicIDNumberObject, (__bridge void*)musicCurrentArtwork);
        if ([dic valueForKey:[NSString stringWithFormat:@"%@", songID]] && songID != nil) {
            NSDictionary *subDic = [dic valueForKey:[NSString stringWithFormat:@"%@", songID]];
            musicPCol = UIColorFromHexString([subDic valueForKey:@"Primary"]);
            musicSCol = UIColorFromHexString([subDic valueForKey:@"Secondary"]);
            musicBCol = UIColorFromHexString([subDic valueForKey:@"Background"]);
        }
        else {
            SLColorArt *colours = [[SLColorArt alloc] initWithImage:musicCurrentArtwork];
            musicPCol = colours.primaryColor;
            musicSCol = colours.secondaryColor;
            musicBCol = colours.backgroundColor;

            if (songID) {
                NSArray *keys = [NSArray arrayWithObjects:@"Primary", @"Secondary", @"Background", nil];
                NSArray *colourArray = [NSArray arrayWithObjects:HexStringFromUIColor(musicPCol), HexStringFromUIColor(musicSCol), HexStringFromUIColor(musicBCol), nil];
                NSDictionary *subDic = [NSDictionary dictionaryWithObjects:colourArray forKeys:keys];
                [dic setValue:subDic forKey:songID];
                [dic writeToFile:cacheDirectory atomically:YES];
            }
        }
        self.vibrantEffectView.backgroundColor = musicBCol;
        [self.vibrantEffectView setVibrancyEnabled:NO];

        self.secondaryTransportControls.tag = 45323;
        [self.secondaryTransportControls layoutSubviews];
        [self.transportControls layoutSubviews];

        MusicNowPlayingVolumeSlider *volSlider = self.volumeSlider;

        [volSlider setMaximumTrackImage:[volSlider.currentMaximumTrackImage filledImageWithColor:musicSCol] forState:UIControlStateNormal];
        [volSlider setMinimumTrackImage:[volSlider.currentMinimumTrackImage filledImageWithColor:musicPCol] forState:UIControlStateNormal];
        MSHookIvar<UIView*>(volSlider, "_maxTrackView").layer.cornerRadius = 1.5;
        MSHookIvar<UIView*>(volSlider, "_maxTrackView").layer.cornerRadius = 1.5;
        if (! volMinImg) {
            volMinImg = volSlider.minimumValueImage;
        }
        if (! volMaxImg) {
            volMaxImg = volSlider.maximumValueImage;
        }
        volSlider.minimumValueImage = [volMinImg opaqueImageWithBurnTint:musicSCol];
        volSlider.maximumValueImage = [volMaxImg opaqueImageWithBurnTint:musicSCol];
        [volSlider setThumbImage:[volSlider.knobView.image imageWithBurnTint:musicPCol] forState:UIControlStateNormal];

        UIButton *b = MSHookIvar<UIButton*>(volSlider, "_routesButton");  // airplay button
        b.tintColor = musicSCol;
        [b setImage:[[b imageForState:UIControlStateNormal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

        MSHookIvar<UILabel*>(self.playbackProgressSliderView, "_timePlayedLabel").textColor = musicSCol;
        MSHookIvar<UILabel*>(self.playbackProgressSliderView, "_timeRemainingLabel").textColor = musicSCol;
        MusicPlaybackProgressSlider *progressSlider = MSHookIvar<MusicPlaybackProgressSlider*>(self.playbackProgressSliderView, "_playbackProgressSlider");
        [progressSlider setMaximumTrackImage:[progressSlider.currentMaximumTrackImage filledImageWithColor:musicSCol] forState:UIControlStateNormal];
        [progressSlider setMinimumTrackImage:[progressSlider.currentMinimumTrackImage filledImageWithColor:musicPCol] forState:UIControlStateNormal];
        progressSlider.knobView.tintColor = musicPCol;
        [progressSlider.knobView removeFromSuperview];
        [progressSlider addSubview:progressSlider.knobView];

        [self.titlesView setAttributedTexts:self.titlesView.attributedTexts]; //ensures update in radio
    }
    else if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
        if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 1) {       // LIGHT BLUR
            musicPCol = [UIColor colorWithWhite:0 alpha:0.75];
            musicSCol = [UIColor colorWithWhite:0.8 alpha:1];
            musicBCol = [UIColor colorWithWhite:1 alpha:0.3];
            activeBlendMode = kCGBlendModeMultiply;
        }
        else if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 2) {  // NO BLUR
            musicPCol = [UIColor colorWithWhite:1 alpha:0.75];
            musicSCol = [UIColor colorWithWhite:1 alpha:0.5];
            musicBCol = [UIColor colorWithWhite:0 alpha:0.8];
        }
        else {                                                                        // DARK BLUR
            musicPCol = [UIColor colorWithWhite:1 alpha:0.75];
            musicSCol = [UIColor colorWithWhite:0.7 alpha:1];
            musicBCol = [UIColor colorWithWhite:0 alpha:0.7];
            activeBlendMode = kCGBlendModeOverlay;
        }

        self.vibrantEffectView.backgroundColor = musicBCol;
        self.vibrantEffectView.maskedView.backgroundColor = musicPCol;

        UIImage *imageForBG = musicCurrentArtwork;

        if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 2) {
            [self.vibrantEffectView.maskedView _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeNormal];
        }
        else if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 1) {
            imageForBG = [[imageForBG scaledToSize:CGSizeMake(320, 320)] musicLightBlurredImage];
            [self.vibrantEffectView.maskedView _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeMultiply];
        }
        else {
            imageForBG = [[imageForBG scaledToSize:CGSizeMake(320, 320)] musicDarkBlurredImage];
            [self.vibrantEffectView.maskedView _setDrawsAsBackdropOverlayWithBlendMode:kCGBlendModeOverlay];
        }

        [UIView transitionWithView:((MPUBlurEffectView*)self.backgroundView).blurImageView
         duration:0.2f
         options:UIViewAnimationOptionTransitionCrossDissolve
         animations:^{
            ((MPUBlurEffectView*)self.backgroundView).blurImageView.image = imageForBG;
        } completion:nil];
    }
}

%end

%hook MusicUpNextViewController

-(void) viewWillAppear:(BOOL)arg1 {
    %orig;
    UIView *bgView = self.navigationController.navigationBar.superview;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue]) {
            bgView.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
        }
        else if ([[preferences valueForKey:@"MusicArtworkBG"] boolValue]) {
            if ([[preferences valueForKey:@"MusicBackgroundMode"] intValue] == 2) {
                bgView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
            }
            else {
                bgView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
            }
        }
        self.view.alpha = 0;
        [UIView transitionWithView:self.view
         duration:0.2f
         options:UIViewAnimationOptionTransitionCrossDissolve
         animations:^{
            self.view.alpha = 1;
        }
         completion:nil];
    }
}

-(void) _dismissUpNext {
    %orig;
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        if (musicCCContainerView) {
            musicCCContainerView.hidden = NO;
        }
        [UIView transitionWithView:self.view
         duration:0.2f
         options:UIViewAnimationOptionTransitionCrossDissolve
         animations:^{
            tempBackgroundViewPointer.backgroundColor = musicBCol;
            self.view.alpha = 0;
            self.navigationController.navigationBar.alpha = 0;
            self.navigationController.navigationBar.superview.backgroundColor = [UIColor clearColor];
            if (musicCCContainerView) {
                musicCCContainerView.alpha = 1;
            }
        }
         completion:nil];
        tempBackgroundViewPointer = nil;
    }
}

%end

%hook MusicNowPlayingTitlesView

- (void) setAttributedTexts:(NSArray *)arg1 {
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] && musicPCol != nil && musicSCol != nil && [self.superview.superview isKindOfClass: %c(MPUVibrantContentEffectView)]) {
        NSMutableArray *a = [NSMutableArray array];
        BOOL setOne = NO;
        for (NSAttributedString *string in arg1) {
            NSMutableAttributedString *s = [string mutableCopy];
            UIColor *col = musicSCol;
            if (! setOne) {
                setOne = YES;
                col = musicPCol;
            }
            [s beginEditing];
            [s addAttribute:NSForegroundColorAttributeName value:col range:NSMakeRange(0, s.length)];
            [s endEditing];
            [a addObject:s];
        }
        %orig(a);
    }
    else {
        %orig;
    }
}

%end

%hook MPUTransportControlsView

- (void)_configureTransportButton : (id)arg1 forTransportControl : (id)arg2 {
    MPUTransportButton *b = arg1;
    if ([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue]) {
        if ([b respondsToSelector:@selector(setRegularImageColor:)]) {
            [(MPUHalfTintedTransportButton*)b setRegularImageColor:musicPCol];
        }
        else if ([[NSNumber numberWithInt:self.tag] isEqual:[NSNumber numberWithInt:45323]]) {
            [b setRegularColor:musicSCol];
            [b setHighlightedColor:musicPCol];
            [b setSelectedColor:musicPCol];
            MSHookIvar<CALayer*>(b, "_selectionIndicatorLayer").backgroundColor = [musicPCol colorWithAlphaComponent:0.15].CGColor;
        }
        else {
            [b setRegularColor:musicPCol];
            [b setHighlightedColor:musicPCol];
            [b setSelectedColor:musicPCol];
        }
    }
    %orig(b, arg2);
}

%end

%hook MusicNowPlayingVolumeSlider

-(void)_updateNowPlayingVolumeSliderTrackTintColors {}

%end

%hook MusicNowPlayingRatingControl

- (void)setAlpha : (CGFloat)a {
    %orig;
    [self fixColours];
}

-(void) _updateImageViewsForRatingAnimated:(BOOL)arg1 {
    %orig;
    [self fixColours];
}

%new

- (void)fixColours {
    if (self.superview) {
        if (([[preferences valueForKey:@"MusicColourFromArtwork"] boolValue] || [[preferences valueForKey:@"MusicArtworkBG"] boolValue]) && ! [self.superview isKindOfClass: %c(UITableViewCellContentView)]) {
            for (UIImageView *iv in MSHookIvar<NSMutableArray*>(self, "_imageViews")) {
                iv.image = [iv.image imageWithBurnTint:musicSCol];
            }
        }
    }
}

%end

%hook MusicTheme

+ (id)tintColor {
    if ([preferences valueForKey:@"MusicTintColour"]) {
        NSString *s = [preferences valueForKey:@"MusicTintColour"];
        if (! [s isEqual:@"#FF2D55"]) {
            return UIColorFromHexString(s);
        }
        else {
            return %orig;
        }
    }
    else {
        return %orig;
    }
}

%end

%hook SKUIViewControllerContainerView

-(void)setViewController : (UIViewController*)arg1 {
    %orig;
    if ([preferences valueForKey:@"MusicTintColour"]) {
        NSString *s = [preferences valueForKey:@"MusicTintColour"];
        if (! [s isEqual:@"#FF2D55"]) {
            arg1.view.tintColor = UIColorFromHexString(s);
        }
    }
}

%end

%end //CustomCoverMusicApp_8_4

%ctor {
    dlopen("/System/Library/SpringBoardPlugins/NowPlayingArtLockScreen.lockbundle/NowPlayingArtLockScreen", 2);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
    preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
    selectedThemeName = [preferences valueForKey:@"SelectedTheme"];
    musicSelectedThemeName = [preferences valueForKey:@"MusicSelectedTheme"];

    deviceNameLS = getDeviceName(selectedThemeName);
    deviceNameM = getDeviceName(musicSelectedThemeName);

    if ([[NSBundle mainBundle].bundleIdentifier isEqual:@"com.apple.springboard"]) {
        %init(CustomCoverLockScreen);
    }
    else if ([[NSBundle mainBundle].bundleIdentifier isEqual:@"com.apple.Music"]) {
        if (IS_IOS_(8,4)) {
            %init(CustomCoverMusicApp_8_4)
        }
        else {
            %init(CustomCoverMusicApp);
        }
    }
}
