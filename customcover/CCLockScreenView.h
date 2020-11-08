#import <UIKit/UIKit.h>

@interface CCLockScreenView :UIView {
    UIView *customCoverContainerView;
    //UIImageView * albumArtworkView;
    NSString *currentTheme;
}
@property (nonatomic, retain) UIImageView *artworkView;
- (id)initWithFrame:(CGRect)frame andThemeName:(NSString *)theme andPreferences:(NSDictionary *)preferences;
- (void)updateWithImage:(UIImage *)image;
- (void)setImage:(UIImage *)img;
- (id)image;
- (NSString *)themeName;
- (CGSize)artworkSize;
@end
