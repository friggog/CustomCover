#import <UIKit/UIKit.h>

@interface CCMusicAppView : UIView {
    UIView *customCoverContainerView;
    UIImageView *albumArtworkView;
    NSString *currentTheme;
}

- (id)initWithPreferences:(NSDictionary *)preferences orientation:(long)o;
- (void)updateWithImage:(UIImage *)image;
- (id)image;
- (NSString *)themeName;

@end
