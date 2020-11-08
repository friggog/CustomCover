ADDITIONAL_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = CustomCoverPrefs
CustomCoverPrefs_FILES = CustomCoverPrefs.mm ColorPicker/HRBrightnessCursor.m ColorPicker/HRBrightnessSlider.m ColorPicker/HRAlphaSlider.m ColorPicker/HRBrightnessSlider.m ColorPicker/HRAlphaCursor.m ColorPicker/HRColorCursor.m ColorPicker/HRColorInfoView.m ColorPicker/HRColorMapView.m ColorPicker/HRColorPickerView.m ColorPicker/HRHSVColorUtil.m ColorPicker/UIImage+CoreGraphics.m CircleViews.mm
CustomCoverPrefs_INSTALL_PATH = /Library/PreferenceBundles
CustomCoverPrefs_FRAMEWORKS = UIKit MessageUI CoreGraphics Social QuartzCore Security
CustomCoverPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/me.chewitt.customcover.plist$(ECHO_END)