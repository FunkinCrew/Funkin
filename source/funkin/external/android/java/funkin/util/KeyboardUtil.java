package funkin.util;

import org.haxe.extension.Extension;

public class KeyboardUtil
{
  public static boolean isKeyboardConnected()
  {
    if (Extension.mainContext == null) return false;

    // KEYBOARD_UNDEFINED = 0, KEYBOARD_NOKEYS = 1
    return Extension.mainContext.getResources().getConfiguration().keyboard > 1;
  }
}
