
@interface _UIBackdropViewSettings : NSObject {}
@property NSInteger style;
+ (id)settingsForStyle:(NSInteger)arg1;
- (void)setColorTint:(id)arg1;
- (void)setColorTintAlpha:(CGFloat)arg1;
- (void)setUsesColorTintView:(BOOL)arg1;

@end

@interface _UIBackdropView : UIView {}
- (id)initWithFrame:(CGRect)arg1 settings:(id)arg2;
- (void)transitionToColor:(id)arg1;
- (void)transitionToSettings:(id)arg1;
- (void)setWantsColorSettings:(BOOL)arg1;
- (void)setAllowsColorSettingsSuppression:(BOOL)arg1;
@property (retain) _UIBackdropViewSettings *outputSettings;
@property (retain) _UIBackdropViewSettings *inputSettings;
@property (retain) UIView *grayscaleTintView;
@property (retain) id backdropEffectView;
@property NSInteger maskMode;
@property NSInteger style;
@property (nonatomic, retain) UIView *contentView;
@property (assign, nonatomic) BOOL simulatesMasks;
@property (assign, nonatomic) CGFloat _saturationDeltaFactor;
- (NSString *)groupName;
- (void)setGroupName:(NSString *)groupName;
- (void)setAppliesOutputSettingsAnimationDuration:(CGFloat)duration;

@end

@interface SBFStaticWallpaperView : UIView
@end

@interface SBLockScreenViewController : UIViewController
- (void)setShowingMediaControls:(BOOL)arg1;
@end

@interface SBWallpaperController : NSObject
+ (instancetype)sharedInstance;
- (id)_newWallpaperViewForProcedural:(id)proceduralWallpaper orImage:(UIImage *)image;
- (id)_newWallpaperViewForProcedural:(id)proceduralWallpaper orImage:(UIImage *)image forVariant:(NSInteger)variant;

@end

@interface _SBFakeBlurView : UIView
+ (UIImage *)_imageForStyle:(NSInteger *)style withSource:(SBFStaticWallpaperView *)source;
- (void)updateImageWithSource:(id)source;
- (void)reconfigureWithSource:(id)source;
@end

@interface SBMediaController : NSObject {}
+ (id)sharedInstance;
- (id)artwork;
- (BOOL)pause;
- (BOOL)play;
- (BOOL)changeTrack:(NSInteger)arg1;
- (BOOL)isPaused;
- (BOOL)isPlaying;
- (void)updateImage;
- (void)updateImage:(UIImage *)image;
- (UIImage *)blurredImageWithStyle:(NSInteger)style andImage:(UIImage *)image;
@end

@interface SBFLockScreenDateView : UIView {}
@property (nonatomic, retain) UIColor *textColor;
@end

@interface _SBFVibrantSettings : NSObject
+ (id)vibrantSettingsWithReferenceColor:(id)arg1 legibilitySettings:(id)arg2;
- (void)setShimmerColor:(id)arg1;
- (void)setChevronShimmerColor:(id)arg1;
- (void)setHighlightColor:(id)arg1;
- (void)setTintColor:(id)arg1;
@property long style;
@end

@interface SBChevronView : UIView  {}
@property (nonatomic, retain) UIColor *color;
@end

@protocol _SBFVibrantView
@property (retain, nonatomic) _SBFVibrantSettings *vibrantSettings;
- (void)setBackgroundView:(id)a;
@end

@interface _UILegibilitySettings : NSObject
@property (retain) UIColor *primaryColor;
@property (retain) UIColor *contentColor;
@property (retain) UIColor *secondaryColor;
@property (retain) UIColor *shadowColor;
- (id)initWithStyle:(NSInteger)arg1 primaryColor:(id)arg2 secondaryColor:(id)arg3 shadowColor:(id)arg4;
-(id)initWithContentColor:(id)arg1 ;
-(id)initWithContentColor:(id)arg1 contrast:(CGFloat)arg2 ;
@end

@interface SBLockScreenView : UIView {}
- (void)updateControlColours:(BOOL)reset;
- (void)updateControlColours;
- (BOOL)pluginViewHidden;
@property (assign, nonatomic) BOOL statusBarLegibilityEnabled;
@property (nonatomic, retain) SBFLockScreenDateView *dateView;
@property (retain, nonatomic) UIView *mediaControlsView;
@property (nonatomic, retain) SBChevronView<_SBFVibrantView> *topGrabberView;
@property (nonatomic, retain) SBChevronView<_SBFVibrantView> *bottomGrabberView;
@property (retain, nonatomic) UIView<_SBFVibrantView> *cameraGrabberView;
@property (nonatomic, retain) _UILegibilitySettings *legibilitySettings;
@property (nonatomic, retain) UIView *notificationView;
- (void)_updateLegibility;
- (void)_updateStatusBarLegibility;
- (BOOL)isMediaPluginActive;
- (void)_updateVibrantViewBackgrounds;
- (void)_updateCameraGrabberBackground;
- (void)_updateBottomGrabberBackground;
- (void)_updateTopGrabberBackground;
- (void)_updateSlideToUnlockBackground;
- (void)_updateVibrantView:(UIView *)arg1 screenRect:(CGRect)arg2 backgroundView:(id)arg3;
@end

@interface _UIVibrantSettings : NSObject
- (void)setHighlightColor:(id)arg1;
- (void)setShimmerColor:(id)arg1;
- (void)setTintColor:(id)arg1;
- (void)setChevronShimmerColor:(id)arg1;
@end

@interface _UIGlintyStringView : UIView {}
- (void)setSpotlightView:(id)arg1;
- (void)setHighlightView:(id)arg1;
- (void)setEffectView:(id)arg1;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, retain) _UIVibrantSettings *vibrantSettings;
@property (nonatomic, retain) _UILegibilitySettings *legibilitySettings;
- (id)_highlightColor;
@end

@interface NowPlayingArtPluginController : NSObject {}
@property (nonatomic, retain) UIView *view;
- (void)sendEnquiryDetails;
- (UIView *)backgroundView;
@end

@interface _NowPlayingArtView : UIView {}
@property (nonatomic, retain) UIView *artworkView;
- (CGSize)_artworkSize;
@end

@interface SBLockScreenPlugin : NSObject {}
@property (copy) NSString *bundleName;
@end

@interface MPUMediaControlsVolumeView : UIView {}
@property (nonatomic, readonly) NSInteger style;                                          //@synthesize style=_style - In the implementation block
@property (nonatomic, readonly) UISlider *slider;                                  //@synthesize slider=_slider - In the implementation block
@end

@interface MPUNowPlayingTitlesView : UIView {}
- (void)setTitleTextAttributes:(id)arg1;
- (void)setDetailTextAttributes:(id)arg1;
@property (nonatomic, retain) UIImage *explicitImage;
@end

@interface MusicNowPlayingTitlesView : MPUNowPlayingTitlesView
@property (nonatomic, copy) NSArray *attributedTexts;
@end

@interface MPUChronologicalProgressView : UIView {
    UILabel *_currentTimeLabel;
    UILabel *_remainingTimeLabel;
    NSString *_lastCurrentTimeString;
    NSString *_lastRemainingTimeString;
    CGFloat _lastDisplayedDuration;
    BOOL _showTimeLabels;
    BOOL _scrubbingEnabled;
    NSInteger _style;
    CGFloat _totalDuration;
    CGFloat _currentTime;
}
@property (nonatomic, readonly) NSInteger style;                                                           //@synthesize style=_style - In the implementation block
@property (assign, nonatomic) CGFloat totalDuration;                                                  //@synthesize totalDuration=_totalDuration - In the implementation block
@property (assign, nonatomic) CGFloat currentTime;                                                    //@synthesize currentTime=_currentTime - In the implementation block
@property (assign, nonatomic) BOOL showTimeLabels;                                                   //@synthesize showTimeLabels=_showTimeLabels - In the implementation block
@property (assign, nonatomic) BOOL scrubbingEnabled;                                                 //@synthesize scrubbingEnabled=_scrubbingEnabled - In the implementation block
@property (nonatomic, readonly) CGRect trackRect;
- (void)_updateTimeLabels;
- (CGFloat)currentTime;
- (void)setCurrentTime:(CGFloat)arg1;
- (void)detailScrubControllerDidBeginScrubbing:(id)arg1;
- (void)detailScrubControllerDidEndScrubbing:(id)arg1;
- (void)detailScrubController:(id)arg1 didChangeValue:(CGFloat)arg2;
- (id)initWithFrame:(CGRect)arg1;
- (void)setDelegate:(id)arg1;
- (void)layoutSubviews;
- (NSInteger)style;
- (id)initWithStyle:(NSInteger)arg1;
- (id)_styledImageName:(id)arg1;
- (id)_trackImage;
- (id)_thumbImage;
- (id)_createTimeLabelWithStyle:(NSInteger)arg1;
- (void)_internalSetCurrentTime:(CGFloat)arg1;
- (CGFloat)_sliderNormalizedValueForTime:(CGFloat)arg1;
- (id)_timeLabelFont;
- (BOOL)showTimeLabels;
- (void)setShowTimeLabels:(BOOL)arg1;
- (void)setTotalDuration:(CGFloat)arg1;
- (CGFloat)totalDuration;
- (void)setScrubbingEnabled:(BOOL)arg1;
- (BOOL)scrubbingEnabled;
@end

@interface MPUTransportControlsView : UIView {
    UIButton *_leftButton;
    UIButton *_middleButton;
    UIButton *_rightButton;
    UIButton *_shuffleButton;
    UIButton *_repeatButton;
}
@property (assign, nonatomic) bool showAccessoryButtons;                                                                  //@synthesize showAccessoryButtons=_showAccessoryButtons - In the implementation block
- (void)_updateTransportControlButtons;
@end

@interface _MPUSystemMediaControlsView : UIView {
    NSInteger _style;
    MPUTransportControlsView *_transportControlsView;
    MPUChronologicalProgressView *_timeInformationView;
    MPUNowPlayingTitlesView *_trackInformationView;
    MPUMediaControlsVolumeView *_volumeView;
}
@property (nonatomic, readonly) NSInteger style;                                                     //@synthesize style=_style - In the implementation block
@property (nonatomic, retain) MPUTransportControlsView *transportControlsView;                //@synthesize transportControlsView=_transportControlsView - In the implementation block
@property (nonatomic, retain) MPUChronologicalProgressView *timeInformationView;              //@synthesize timeInformationView=_timeInformationView - In the implementation block
@property (nonatomic, retain) MPUNowPlayingTitlesView *trackInformationView;               //@synthesize trackInformationView=_trackInformationView - In the implementation block
@property (nonatomic, retain) MPUMediaControlsVolumeView *volumeView;
@end

@interface _MPUDetailSlider : UISlider {}
@end

@interface UIStatusBar : UIView {}
- (void)setForegroundColor:(id)arg1;
@end

@interface MusicNowPlayingPlaybackControlsView : UIView
- (void)fixProgressSlider;
- (void)updateColours;
- (void)updateColoursAnimated:(BOOL)animated;
- (void)resetColours;
@end

@interface MPVolumeSlider : UISlider
@end

@interface MusicNowPlayingVolumeSlider : MPVolumeSlider
@property (nonatomic, readonly) UIImageView *knobView;
- (void)_updateNowPlayingVolumeSliderTrackTintColors;
- (void)setThumbImage:(id)arg1 forState:(unsigned long long)arg2;
@end

@interface MPUBlurEffectView : UIView
@property (nonatomic, retain) UIImageView *blurImageView;
@end

@interface MPUVibrantContentEffectView : UIView
@property (nonatomic, retain) UIImageView *blurImageView;
@property (nonatomic, retain) UIView *tintingView;
@property (nonatomic, readonly) UIView *contentView;
@property (nonatomic, retain) UIView *maskedView;
- (void)setVibrancyEnabled:(BOOL)arg1;
@end

@interface MusicNowPlayingItemViewController : UIViewController
- (UIImage *)artworkImage;
@end

@interface MusicNowPlayingViewController : UIViewController <UIGestureRecognizerDelegate>
- (void)_flipsideAction:(id)arg1;
- (void)_tapAction:(id)arg1;
- (void)updateMusicImage;
- (void)updateColours;
- (void)updateColoursAnimated:(BOOL)animated;
- (void)createMainView;
- (void)createBGView;
- (void)createViews;
- (void)removeBGView;
- (void)removeMainView;
- (void)resetColours;
- (void)createGestureView;
- (void)_updateBackgroundEffects;
///8.4
@property (nonatomic, retain) MPUBlurEffectView *backgroundView;
@property (nonatomic, retain) MPUVibrantContentEffectView *vibrantEffectView;
@property (nonatomic, readonly) MusicNowPlayingItemViewController *currentItemViewController;
@property (nonatomic, readonly) UIView *playbackProgressSliderView;                                           //@synthesize playbackProgressSliderView=_playbackProgressSliderView - In the implementation block
@property (nonatomic, readonly) MusicNowPlayingTitlesView *titlesView;                                                                 //@synthesize titlesView=_titlesView - In the implementation block
@property (nonatomic, readonly) MPUTransportControlsView *transportControls;                                                           //@synthesize transportControls=_transportControls - In the implementation block
@property (nonatomic, readonly) MusicNowPlayingVolumeSlider *volumeSlider;                                                             //@synthesize volumeSlider=_volumeSlider - In the implementation block
@property (nonatomic, readonly) MPUTransportControlsView *secondaryTransportControls;                                                  //@synthesize secondaryTransportControls=_secondaryTransportControls - In the implementation block
@end

@interface MusicTheme : NSObject
+ (id)tintColor;
@end

@interface MPButton : UIButton
- (void)updateColours;
- (void)resetColours;
- (void)_updateImageView;
@end

@interface MPTransportButton : UIButton
- (void)updateColours;
- (void)resetColours;
@end

@interface MusicPlaybackProgressSlider : UISlider
@property (nonatomic, readonly) UIImageView *knobView;
@end

@interface MPUVignetteBackgroundView : UIView
- (void)updateBackgroundImage;
@end

@interface MPMediaItemArtwork : NSObject
- (id)albumImageDataWithSize:(CGSize)arg1;
- (id)albumImageWithSize:(CGSize)arg1;
- (id)imageWithSize:(CGSize)arg1;
@end

@interface MPMediaItem : NSObject
@property (readonly) MPMediaItemArtwork *artwork;
@end

@interface MPAVItem : NSObject
/// 7.0
@property (nonatomic, readonly) NSData *artworkImageData;
/// 7.1
@property (nonatomic, readonly) MPMediaItem *mediaItem;
@property (nonatomic, readonly) unsigned long long persistentID;
@end

@interface RadioArtwork : NSObject
@property (nonatomic, readonly) NSURL *URL;
@end

@interface RadioArtworkCollection : NSObject
@property (nonatomic, readonly) NSArray *artworks;
- (id)bestArtworkForPointSize:(CGSize)arg1;
- (id)bestArtworkForPixelSize:(CGSize)arg1;
@end

@interface RadioTrack : NSObject
@property (nonatomic, readonly) RadioArtworkCollection *artworkCollection;
@end

@interface MPRadioAVItem : MPAVItem
- (RadioTrack *)radioTrack;
@end

@interface MPDetailSlider : UISlider
- (void)updateColours;
@end

@interface MPURatingControl : UIView
- (void)fixColours;
@end

@interface MusicFlipsideTracksViewController : UIViewController
@end

@interface CVResources : NSObject
+ (void)setIsUnlocking:(BOOL)val;
+ (BOOL)getIsUnlocking;
+ (BOOL)unlockedWithBulletin;
+ (void)setUnlockedWithBulletin:(BOOL)val;
+ (void)setDontAnimateOut:(BOOL)dontAnimate;
+ (BOOL)getDontAnimateOut;
+ (NSMutableArray *)getLockBulletinIds;
+ (void)setLockFullscreenNotificationBundleId:(NSString *)bundleid;
+ (NSString *)getLockFullscreenNotificationBundleId;
+ (void)setShowingLockFullscreenNotification:(BOOL)enabled;
+ (BOOL)getShowingLockFullscreenNotification;
+ (void)setLockFullscreenBBBulletin:(id)bulletin;
+ (BOOL)biteSMSQrEnabled;
+ (BOOL)biteSMSEnabled;
+ (BOOL)couriaEnabledForBulletin:(NSString *)arg1;
+ (BOOL)isGuestModeEnabled;
+ (BOOL)deviceIsLocked;
+ (NSString *)themedResourceFilePathWithName:(NSString *)name andExtension:(NSString *)ext;
+ (NSString *)themedBundleFilePathWithName:(NSString *)name;
+ (NSString *)localisedStringForKey:(NSString *)key value:(NSString *)val;
+ (BOOL)lockScreenEnabled;
+ (BOOL)showBatteryPercent;
+ (NSArray *)lockWidgets;
+ (NSArray *)lockToggles;
+ (NSInteger)lockBlurRadius;
+ (BOOL)isUsingLightFonts;
+ (NSInteger)lockArtworkVariant;
+ (BOOL)lockHTMLEnabled;
+ (NSString *)lockHTMLTheme;
+ (BOOL)lockHTMLDoesScroll;
+ (BOOL)showDismissButton;
+ (CGFloat)lockScreenIdleTime;
+ (NSString *)htmlDirectory;
+ (BOOL)fadeHTMLUnderNotif;
+ (BOOL)showClock;
+ (BOOL)dontUseCustomNotificationIcons;
+ (BOOL)useSquareIcons;
+ (BOOL)disableBatteryUI;
+ (BOOL)disableIntensiveEffects;
+ (BOOL)hasLightWallpaper;
+ (UIColor *)adjustedColour;
+ (BOOL)useTransparentText;
+ (SBLockScreenViewController *)lockScreenViewController;
+ (void)reloadSettings;
+ (void)reloadNotificationInformation;
@end

@interface CVLockController : UIWindow
@property (retain, nonatomic) UIView *dynamicWallpaper;
@property (retain, nonatomic) UIView *timeMusicView;
@property (nonatomic, strong) UIImageView *blurredBackground;
@property (nonatomic, strong) UIImageView *background;
@property (nonatomic, strong) UIImageView *artwork;
@end

@interface CVAPI : NSObject
+ (CVLockController *)mainWindow;
+ (UIView *)mainScrollView;
@end

@interface PNMusica : NSObject
+ (id)sharedInstance;
@property (readonly, nonatomic) UIImageView *backgroundAlbumArtImageView;
- (id)backgroundImageWithImage:(id)arg1;
@end

@interface SBFGlintyStringView
- (void)setChevronGlimmerColor:(id)col;
- (void)setBackgroundColor:(id)col;
@end

@interface UIView (chewitt)
- (void)logViewHierarchy;
@end

@interface SBControlCenterController : NSObject {
    UIViewController *_viewController;
}
+ (id)sharedInstanceIfExists;
@end

@interface SBControlCenterContainerView : UIView
- (UIView *)contentContainerView;
@end

@interface CFSCButtonsAPI : NSObject
+ (UIButton *)loveButton;
+ (UIButton *)repostButton;
@end

@interface CFTSButtonsAPI : NSObject
+ (UIButton *)upButton;
+ (UIButton *)downButton;
@end

@interface MusicalButtonsAPI : NSObject
+ (UIButton *)repeatButton;
+ (UIButton *)shuffleButton;
@end

@interface UIView (chew)
- (void)_setDrawsAsBackdropOverlayWithBlendMode:(long long)arg1;
@end

@interface MPAVController : NSObject
@property (retain) MPAVItem *currentItem;
@end

@interface MPNowPlayingInfoCenter : NSObject
@property (copy) NSDictionary *nowPlayingInfo;
+ (id)defaultCenter;
@end

@interface MPUTransportButtonAttributes : NSObject
@property (nonatomic, retain) UIImage *image;
@end

@interface MPUNowPlayingController : UIViewController
@property (nonatomic, readonly) UIImage *currentNowPlayingArtwork;
@property (nonatomic, readonly) NSDictionary *currentNowPlayingInfo;
@property (assign, nonatomic) BOOL shouldUpdateNowPlayingArtwork;
@property (assign, nonatomic) id delegate;
@end

@interface MPUHalfTintedTransportButton : UIControl
- (void)setRegularImageColor:(UIColor *)arg1;
@end

@interface  MPUMarqueeView : UIView
@property (nonatomic, readonly) UIView *contentView;
@end

@interface MPUTransportButton : UIButton
- (void)setRegularColor:(UIColor *)arg1;
- (void)setHighlightedColor:(UIColor *)arg1;
- (void)setSelectedColor:(UIColor *)arg1;
@end

@interface MusicNowPlayingRatingControl : MPURatingControl
@end

@interface MusicUpNextViewController : UIViewController
@end

@interface FCForecastController
+ (id)sharedInstance;
- (void)updateForLegibilitySettings:(id)arg1 animated:(_Bool)arg2;
@end

@interface UIApplication (customcover)
-(long)activeInterfaceOrientation;
@end
