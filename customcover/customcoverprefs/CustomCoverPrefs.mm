#import <Preferences/Preferences.h>
#import <UIKit/UIPeripheralHostView.h>
#import <MessageUI/MessageUI.h>
#import <Social/Social.h>
#import <sys/utsname.h>
#import "ColorPicker/HRColorPickerView.h"
#import "CircleViews.h"
#import <MobileGestalt/MobileGestalt.h>
#import <CommonCrypto/CommonCrypto.h>

#define TINT_COLOUR [UIColor colorWithRed:52.0 / 255.0 green:170.0 / 255.0 blue:220.0 / 255.0 alpha:1];
#define TWEAK_VERSION @"1.7.1"
#define listPath @"/var/lib/dpkg/info/me.chewitt.customcover.list"
#define prefsPath @"/User/Library/Preferences/me.chewitt.customcoverprefs.plist"

NSString *machineName() {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

static UIColor* defaultBarTint;
static BOOL beta = NO;
static BOOL iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
static BOOL is_IOS_8_1 = [[[UIDevice currentDevice] systemVersion] compare:@"8.1" options:NSNumericSearch] != NSOrderedAscending;
static BOOL is_IOS_8_4 = [[[UIDevice currentDevice] systemVersion] compare:@"8.4" options:NSNumericSearch] != NSOrderedAscending;

static NSString *HexStringFromUIColor(UIColor* colour) {
    CGFloat r, g, b, a;
    [colour getRed:&r green:&g blue:&b alpha:&a];
    int rgb = (int)(r * 255.0f) << 16 | (int)(g * 255.0f) << 8 | (int)(b * 255.0f) << 0;
    return [NSString stringWithFormat:@"#%06x", rgb];
}

static UIColor *UIColorFromHexString(NSString* hexString) {
    unsigned rgbValue = 0;
    if (! hexString) {
        return [UIColor clearColor];
    }
    NSScanner* scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0 green:((rgbValue & 0xFF00) >> 8) / 255.0 blue:(rgbValue & 0xFF) / 255.0 alpha:1.0];
}

__attribute__((always_inline)) static BOOL jabba() {
    return [[NSFileManager defaultManager] fileExistsAtPath:listPath];
}

__attribute__((always_inline)) static BOOL jango() {
    return [[NSFileManager defaultManager] fileExistsAtPath:listPath];
}

@interface CHCCPSListController:PSListController
@end
@implementation CHCCPSListController
-(void) viewWillAppear:(BOOL)anim {
    [super viewWillAppear:anim];
    if (! defaultBarTint) {
        defaultBarTint = self.navigationController.navigationBar.tintColor;
    }
    self.navigationController.navigationBar.tintColor = TINT_COLOUR;
    self.view.tintColor = TINT_COLOUR;
    [UIApplication sharedApplication].keyWindow.tintColor = TINT_COLOUR;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    id val = nil;
    if (! dic[specifier.properties[@"key"]]) {
        val = specifier.properties[@"default"];
    }
    else {
        val = dic[specifier.properties[@"key"]];
    }

    if ([specifier.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger)! [val boolValue]];
    }
    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefsPath]];
    if ([specifier.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger)! [value boolValue]] forKey:specifier.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:specifier.properties[@"key"]];
    }
    [defaults writeToFile:prefsPath atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

@interface CHCCPSListItemsController:PSListItemsController
@end
@implementation CHCCPSListItemsController
-(void) viewWillAppear:(BOOL)anim {
    [super viewWillAppear:anim];
    self.navigationController.navigationBar.tintColor = TINT_COLOUR;
    self.view.tintColor = TINT_COLOUR;
    [UIApplication sharedApplication].keyWindow.tintColor = TINT_COLOUR;
}

-(id) readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:prefsPath];
    id val = nil;
    if (! dic[specifier.properties[@"key"]]) {
        val = specifier.properties[@"default"];
    }
    else {
        val = dic[specifier.properties[@"key"]];
    }

    if ([specifier.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger)! [val boolValue]];
    }
    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefsPath]];
    if ([specifier.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger)! [value boolValue]] forKey:specifier.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:specifier.properties[@"key"]];
    }
    [defaults writeToFile:prefsPath atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

@interface UITableViewCell (chew)
-(id) _tableView;
@end

@interface CCBetterSliderCell:PSSliderTableCell <UIAlertViewDelegate, UITextFieldDelegate> {
    UIAlertView* alert;
}
-(void) presentPopup;
-(void)typeMinus;
@end

@implementation CCBetterSliderCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        CGRect frame = [self frame];
        UIButton* button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = CGRectMake(frame.size.width - 50, 0, 50, frame.size.height);
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [button setTitle:@"" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(presentPopup) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
    return self;
}

-(void) presentPopup {
    alert = [[UIAlertView alloc] initWithTitle:self.specifier.name
                                                    message:[NSString stringWithFormat:@"Please enter a value between %zd and %zd.", (NSInteger)[[self.specifier propertyForKey:@"min"] floatValue], (NSInteger)[[self.specifier propertyForKey:@"max"] floatValue]]
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Enter"
                          , nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 342879;
    [alert show];
    [[alert textFieldAtIndex:0] setDelegate:self];
    [[alert textFieldAtIndex:0] resignFirstResponder];
    [[alert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    if(!iPad) {
        UIToolbar* toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        UIBarButtonItem* buttonOne = [[UIBarButtonItem alloc] initWithTitle:@"Negate" style:UIBarButtonItemStylePlain target:self action:@selector(typeMinus)];
        NSArray* buttons = [NSArray arrayWithObjects:buttonOne, nil];
        [toolBar setItems:buttons animated:NO];
        [[alert textFieldAtIndex:0] setInputAccessoryView:toolBar];
    }
    [[alert textFieldAtIndex:0] becomeFirstResponder];
}

-(void) typeMinus {
    if (alert) {
        NSString* text = [alert textFieldAtIndex:0].text;
        if ([text hasPrefix:@"-"]) {
            [alert textFieldAtIndex:0].text = [text substringFromIndex:1];
        }
        else {
            [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"-%@", text];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 342879) {
        if(buttonIndex == 1){
            NSInteger value = [[alertView textFieldAtIndex:0].text integerValue];
            if (value <= [[self.specifier propertyForKey:@"max"] intValue] && value >= [[self.specifier propertyForKey:@"min"] intValue]) {
                [self setValue:[NSNumber numberWithInt:value]];
                [PSRootController setPreferenceValue:[NSNumber numberWithInt:value] specifier:self.specifier];
                [[NSUserDefaults standardUserDefaults] synchronize];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[self.specifier propertyForKey:@"PostNotification"], NULL, NULL, YES);
                });
            }
            else {
                UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                      message:@"Ensure you enter a valid value."
                                                                     delegate:self
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil
                                            , nil];
                errorAlert.tag = 85230234;
                [errorAlert show];
            }
        }
        [[alertView textFieldAtIndex:0] resignFirstResponder];
    }
    else if (alertView.tag == 85230234) {
        [self presentPopup];
    }
}

@end

@interface CCBannerCell:PSTableCell {}
@end

@implementation CCBannerCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        CGRect frame = [self frame];
        frame.size.height = 100;

        NSString* bundleName = @"CustomCoverPrefs";

        UIView* containerView = [[UIView alloc] initWithFrame:frame];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        containerView.clipsToBounds = YES;

        UIImageView* titleImage = [[UIImageView alloc] initWithFrame:frame];
        if (iPad) {
            titleImage.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/banner_ipad.png", bundleName]];
            containerView.layer.cornerRadius = 5;
        }
        else {
            titleImage.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/banner_iphone.png", bundleName]];
        }

        titleImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleImage.contentMode = UIViewContentModeScaleAspectFill;

        [containerView addSubview:titleImage];

        if (beta) {
            UIImageView* betaBadge = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
            betaBadge.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/beta_badge.png", bundleName]];
            [containerView addSubview:betaBadge];
        }
        [self.contentView addSubview:containerView];
    }
    return self;
}

@end

@interface CustomCoverPrefsListController:CHCCPSListController <MFMailComposeViewControllerDelegate> {}
@end

@implementation CustomCoverPrefsListController

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.tintColor = defaultBarTint;
    [UIApplication sharedApplication].keyWindow.tintColor = defaultBarTint;
}

-(id) specifiers {
    if (_specifiers == nil) {
        UIBarButtonItem* likeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/CustomCoverPrefs.bundle/heart.png"] style:UIBarButtonItemStylePlain target:self action:@selector(composeTweet)];
        ((UINavigationItem*)self.navigationItem).rightBarButtonItem = likeButton;

        _specifiers = [self loadSpecifiersFromPlistName:@"CustomCoverPrefs" target:self];

        NSString* deviceName = @"iPhone";
        if (iPad) {
            deviceName = @"iPad";
        }
        else if ([UIScreen mainScreen].bounds.size.width == 414) {
            deviceName = @"iPhone6+";
        }

        NSString* documentsDirectory = @"/Library/Application Support/CustomCover/Themes";
        NSFileManager* fM = [NSFileManager defaultManager];
        NSArray* fileList = [fM contentsOfDirectoryAtPath:documentsDirectory error:nil];
        NSMutableArray* directoryList = [[NSMutableArray alloc] init];
        for (NSString* file in fileList) {
            NSString* path = [documentsDirectory stringByAppendingPathComponent:file];
            BOOL isDir = NO;
            [fM fileExistsAtPath:path isDirectory:(&isDir)];
            BOOL fileExists = [fM fileExistsAtPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", deviceName]]] || ([deviceName isEqualToString:@"iPhone6+"] && [fM fileExistsAtPath:[path stringByAppendingPathComponent:@"/iPhone/Mask@3x.png"]]);
            if (isDir && ! [file isEqual:@".AppleDouble"] && fileExists) {
                [directoryList addObject:file];
            }
        }

        PSSpecifier* themeSelect = [_specifiers objectAtIndex:2];
        PSSpecifier* musicThemeSelect = [_specifiers objectAtIndex:6];
        if (beta) {
            themeSelect = [_specifiers objectAtIndex:3];
            musicThemeSelect = [_specifiers objectAtIndex:7];
        }

        [themeSelect setValues:directoryList titles:directoryList];
        [musicThemeSelect setValues:directoryList titles:directoryList];

        PSSpecifier* supportGroup = [self specifierForID:@"supportGroup"];
        PSSpecifier* copyright = [self specifierForID:@"copyright"];
        NSString* footer = [copyright propertyForKey:@"footerText"];
        if (! jabba() && ! jango()) {
            [supportGroup setProperty:@"If you like CustomCover, please consider supporting future development by purchasing." forKey:@"footerText"];
            footer = [footer stringByReplacingOccurrencesOfString:@"$" withString:[NSString stringWithFormat:@"%@ ☠", TWEAK_VERSION]];
        }
        else {
            footer = [footer stringByReplacingOccurrencesOfString:@"$" withString:TWEAK_VERSION];
        }

        [copyright setProperty:footer forKey:@"footerText"];
    }
    return _specifiers;
}

-(void) composeTweet {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController* tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:@"I'm using CustomCover (by @friggog) to make my music app and lockscreen look awesome!"];
        UIViewController* rootViewController = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:tweetSheet animated:YES completion:nil];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to tweet at this time." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

-(void) openEmailLink {
    NSString* currSysVer = [[UIDevice currentDevice] systemVersion];
    NSString* tweakVer = TWEAK_VERSION;
    if (! jabba() && ! jango()) {
        tweakVer = [tweakVer stringByAppendingString:@"."];
    }
    NSString* device = machineName();

    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:[NSString stringWithFormat:@"CustomCover %@ - %@ : %@", tweakVer, device, currSysVer]];

        NSArray* toRecipients = [NSArray arrayWithObject:@"contact@chewitt.me"];
        [picker setToRecipients:toRecipients];

        UIViewController* rootViewController = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:picker animated:YES completion:NULL];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                              message:@"You seem to be unable to send emails."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil
                              , nil];
        [alert show];
    }
}

-(void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

-(void) openTwitterLink {
    NSURL* appURL = [NSURL URLWithString:@"twitter:///user?screen_name=friggog"];
    if ([[UIApplication sharedApplication] canOpenURL:appURL]) {
        [[UIApplication sharedApplication] openURL:appURL];
    }
    else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/friggog"]];
    }
}

@end

@interface OtherSettingsController:CHCCPSListController {}
-(void) setUseArtworkColours:(id)value specifier:(id)specifier;
-(void) setArtworkAsWall:(id)value specifier:(id)specifier;
@end

@implementation OtherSettingsController
-(void) setUseArtworkColours:(id)value specifier:(id)specifier {}

-(void) setArtworkAsWall:(id)value specifier:(id)specifier {}

@end

@interface LockOtherSettingsController:OtherSettingsController
@end

@implementation LockOtherSettingsController
-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self];        // retain];
        BOOL colourise = [[self readPreferenceValue:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"colourFromArtwork"]]] boolValue];
        BOOL artworkBG = [[self readPreferenceValue:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"ArtworkBG"]]] boolValue];
        BOOL keepCols = [[self readPreferenceValue:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"keepColoursForNotifications"]]] boolValue];
        NSInteger bgMode = [[self readPreferenceValue:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"LSBackgroundMode"]]] intValue];
        NSMutableArray* a = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < _specifiers.count; i++) {
            if (i == 6) {
                if (colourise) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            else if (i == 1) {
                if (! is_IOS_8_1) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            else if (i == 8) {
                if (artworkBG) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            else if (i == 9) {
                if (! artworkBG && ! colourise) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            else if (i >= 10 && i < 13) {
                if (! colourise || (colourise && keepCols)) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            else if (i == 13) {
                if (bgMode < 2 && artworkBG) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            else {
                [a addObject:[_specifiers objectAtIndex:i]];
            }
        }
        _specifiers = [a copy];
    }
    return _specifiers;
}

-(void) setUseArtworkColours:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];

    BOOL val = [value boolValue];
    if (val) {    /////
        [self setPreferenceValue:[NSNumber numberWithInt:0] specifier:[self specifierForID:@"ArtworkBG"]];
        [self insertSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:6] afterSpecifier:[self specifierForID:@"colourFromArtwork"] animated:YES];
        //  if([[self readPreferenceValue:[self specifierForID:@"keepColoursForNotifications"]] boolValue])
        //    [self removeSpecifier:[self specifierForID:@"colGroup"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"LSBackgroundMode"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"NoBlur"] animated:YES];
    }
    else {
        [self removeSpecifier:[self specifierForID:@"keepColoursForNotifications"] animated:YES];
        if (! [[self readPreferenceValue:[self specifierForID:@"ArtworkBG"]] boolValue]) {
            [self insertSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:9] afterSpecifier:[self specifierForID:@"ArtworkBG"] animated:YES];
        }
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:10] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:11] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:12] animated:YES];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

-(void) setArtworkAsWall:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];

    BOOL val = [value boolValue];
    if (val) {
        [self removeSpecifier:[self specifierForID:@"NoBlur"] animated:YES];
        [self removeSpecifier:[self specifierForID:@"keepColoursForNotifications"] animated:YES];
        [self insertSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:8] afterSpecifier:[self specifierForID:@"ArtworkBG"] animated:YES];
        if ([[self readPreferenceValue:[self specifierForID:@"colourFromArtwork"]] boolValue] && ! [[self readPreferenceValue:[self specifierForID:@"keepColoursForNotifications"]] boolValue]) {
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:10] animated:YES];
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:11] animated:YES];
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:12] animated:YES];
            //  if([[self readPreferenceValue:[self specifierForID:@"LSBackgroundMode"]] intValue] < 2)
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:13] animated:YES];
        }
        [self setPreferenceValue:[NSNumber numberWithInt:0] specifier:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"colourFromArtwork"]]];
    }
    else {
        if (! [[self readPreferenceValue:[self specifierForID:@"colourFromArtwork"]] boolValue]) {
            [self insertSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:9] afterSpecifier:[self specifierForID:@"ArtworkBG"] animated:YES];
        }
        [self removeSpecifier:[self specifierForID:@"LSBackgroundMode"] animated:YES];
        if ([[self readPreferenceValue:[self specifierForID:@"LSBackgroundMode"]] intValue] < 2) {
            [self removeSpecifier:[self specifierForID:@"LSControlBlending"] animated:YES];
        }
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

-(void) setKeepColoursForNotifications:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];

    BOOL val = [value boolValue];
    if (val) {
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:10] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:11] animated:YES];
        [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:12] animated:YES];
    }
    else {
        [self removeSpecifier:[self specifierForID:@"colGroup"] animated:YES];
    }
}

-(void) setBackgroundMode:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];

    NSInteger val = [value intValue];
    if (val < 2) {
        if ([self specifierForID:@"LSControlBlending"] == nil) {
            [self addSpecifier:[[self loadSpecifiersFromPlistName:@"LockOtherPrefs" target:self] objectAtIndex:13] animated:YES];
        }
    }
    else {
        [self removeSpecifier:[self specifierForID:@"LSControlBlending"] animated:YES];
    }
}

@end

@interface MusicOtherSettingsController:OtherSettingsController
@end

@implementation MusicOtherSettingsController
-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"MusicOtherPrefs" target:self];        // retain];
        BOOL artworkBG = [[self readPreferenceValue:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"ArtworkBG"]]] boolValue];
        NSMutableArray* a = [[NSMutableArray alloc] init];
        if (! artworkBG) {
            for (NSInteger i = 0; i < _specifiers.count; i++) {
                if (i != 3) {
                    [a addObject:[_specifiers objectAtIndex:i]];
                }
            }
            _specifiers = [a copy];
        }
    }
    return _specifiers;
}

-(void) setArtworkAsWall:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];

    BOOL val = [value boolValue];
    if (val) {
        [self setPreferenceValue:[NSNumber numberWithInt:0] specifier:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"colourFromArtwork"]]];
        [self insertSpecifier:[[self loadSpecifiersFromPlistName:@"MusicOtherPrefs" target:self] objectAtIndex:3] afterSpecifier:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"ArtworkBG"]] animated:YES];
    }
    else {
        [self removeSpecifier:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"BackgroundMode"]] animated:YES];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

-(void) setUseArtworkColours:(id)value specifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];

    BOOL val = [value boolValue];
    if (val) {
        [self setPreferenceValue:[NSNumber numberWithInt:0] specifier:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"ArtworkBG"]]];
        if ([self indexOfSpecifierID:@"BackgroundMode"] == 4 || [self indexOfSpecifierID:@"BackgroundMode"] == 3) {
            [self removeSpecifier:[_specifiers objectAtIndex:[self indexOfSpecifierID:@"BackgroundMode"]] animated:YES];
        }
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3];
}

@end

@interface OffsetSettingsController:CHCCPSListController {}
@end

@implementation OffsetSettingsController

-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"OffsetPrefs" target:self];
    }
    return _specifiers;
}

@end

@interface CHCCColourPickerController:CHCCPSListController {
    HRColorPickerView* colorPickerView;
}
@end

@implementation CHCCColourPickerController

-(id) specifiers {
    if (_specifiers == nil) {
        if (! colorPickerView) {
            [self performSelector:@selector(createPickerView) withObject:nil afterDelay:0.01];
        }
        PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:@" "
                             target:self
                             set:nil
                             get:nil
                             detail:nil
                             cell:[PSTableCell cellTypeFromString:@"PSGroupCell"]
                             edit:0];
        _specifiers = [NSArray arrayWithObjects:spec, nil];
    }
    return _specifiers;
}

-(void) createPickerView {
    colorPickerView = [[HRColorPickerView alloc] init];
    CGRect frame = ((UIView*)self.table).frame;
    frame = CGRectMake(0, 0, frame.size.width, frame.size.height - 66);
    if (iPad) {
        frame = CGRectMake(frame.size.width / 2 - 200, 25, 400, 600);
    }
    colorPickerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    colorPickerView.frame = frame;
    colorPickerView.backgroundColor = [UIColor clearColor];
    UIColor* col = UIColorFromHexString([self.specifier propertyForKey:@"default"]);
    if ([self readPreferenceValue:self.specifier]) {
        col = UIColorFromHexString([self readPreferenceValue:self.specifier]);
    }
    colorPickerView.color = col;
    colorPickerView.alphaValue = 1;
    colorPickerView.wantsAlpha = NO;
    [colorPickerView addTarget:self
     action:@selector(action:)
     forControlEvents:UIControlEventValueChanged];
    [self.table addSubview:colorPickerView];
}

-(void) action:(HRColorPickerView*)obj {
    [self setPreferenceValue:HexStringFromUIColor(obj.color) specifier:self.specifier];
    [(PSListController*)_parentController reloadSpecifier:self.specifier];
}

@end

@interface CHCCButtonCell:PSTableCell
@end

@implementation CHCCButtonCell
-(void) layoutSubviews {
    [super layoutSubviews];
    self.titleTextLabel.textColor = TINT_COLOUR;
}

@end

@interface CHCCColourPickerLinkCell:PSTableCell {
    CircleColourView* circle;
}
@end

@implementation CHCCColourPickerLinkCell

-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        circle = [[CircleColourView alloc] initWithFrame:CGRectMake(self.frame.size.width - 30, 7, 30, 30) andColour:[UIColor clearColor]];
        [self.contentView addSubview:circle];
        [self valueLabel].hidden = YES;
    }
    return self;
}

-(void) setValue:(id)value {
    [super setValue:value];
    UIColor* col = UIColorFromHexString(value);
    circle.backgroundColor = col;
}

@end
