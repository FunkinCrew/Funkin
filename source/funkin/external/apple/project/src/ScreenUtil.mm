#import "ScreenUtil.hpp"

#import <TargetConditionals.h>
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif
#import <Foundation/Foundation.h>

void Apple_ScreenUtil_GetSafeAreaInsets(double* top, double* bottom, double* left, double* right)
{
  #if TARGET_OS_IOS
  if (@available(iOS 11, *))
  {
    UIWindow* window = [UIApplication sharedApplication].windows[0];
    UIEdgeInsets safeAreaInsets = window.safeAreaInsets;
    float scale = [UIScreen mainScreen].scale;

    (*top) = safeAreaInsets.top * scale;
    (*bottom) = safeAreaInsets.bottom * scale;
    (*left) = safeAreaInsets.left * scale;
    (*right) = safeAreaInsets.right * scale;

    return;
  }
  #endif

  (*top) = 0.0;
  (*bottom) = 0.0;
  (*left) = 0.0;
  (*right) = 0.0;
}

void Apple_ScreenUtil_GetScreenSize(double* width, double* height)
{
  #if TARGET_OS_IOS
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  float scale = [UIScreen mainScreen].scale;

  (*width) = (double)screenRect.size.width  * scale;
  (*height) = (double)screenRect.size.height * scale;
  #else
  (*width) = 0.0;
  (*width) = 0.0;
  #endif
}
