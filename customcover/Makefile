TARGET = iphone:clang:latest:7.0
ADDITIONAL_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CustomCover
CustomCover_FILES = Tweak.xm CCLockScreenView.mm CCMusicAppView.mm UIImage+ImageEffects.m SLColorArt.m UIImage+ColorArt.m UIImage+Scale.m
CustomCover_FRAMEWORKS = UIKit CoreGraphics QuartzCore Accelerate Foundation OpenGLES
CustomCover_PRIVATE_FRAMEWORKS = SpringBoardUI
CustomCover_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += customcoverprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
