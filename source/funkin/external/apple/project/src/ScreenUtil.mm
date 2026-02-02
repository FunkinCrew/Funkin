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
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    if (window)
    {
      UIEdgeInsets insets = window.safeAreaInsets;
      CGFloat scale = window.screen.nativeScale;

      (*top) = (double)(insets.top * scale);
      (*bottom) = (double)(insets.bottom * scale);
      (*left) = (double)(insets.left * scale);
      (*right)  = (double)(insets.right * scale);
      return;
    }
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
  if (@available(iOS 11, *))
  {
    UIWindow *window = [UIApplication sharedApplication].windows[0];
    if (window && window.rootViewController)
    {
      UIView *view = window.rootViewController.view;
      CGSize size = view.bounds.size;
      CGFloat scale = window.screen.nativeScale;

      (*width) = (double)((int)(size.width  * scale));
      (*height) = (double)((int)(size.height * scale));
      return;
    }
  }
  #endif

  (*width) = 0.0;
  (*height) = 0.0;
}
