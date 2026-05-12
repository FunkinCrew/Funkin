#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

bool Apple_KeyboardUtil_isKeyboardConnected()
{
  #if TARGET_OS_IOS
  if (@available(iOS 16.4, *))
  {
    return UITextInputContext.current.isHardwareKeyboardInputExpected;
  }
  #endif

  return false;
}
