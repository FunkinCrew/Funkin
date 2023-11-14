package funkin.util;

/**
 * Utility functions related to specific platforms.
 */
class PlatformUtil
{
  /**
   * Returns true if the current platform is MacOS.
   *
   * NOTE: Only use this for choosing modifier keys for shortcut hints.
   * @return Whether the current platform is MacOS, or HTML5 running on MacOS.
   */
  public static function isMacOS():Bool
  {
    #if mac
    return true;
    #elseif html5
    return js.Browser.window.navigator.platform.startsWith("Mac")
      || js.Browser.window.navigator.platform.startsWith("iPad")
      || js.Browser.window.navigator.platform.startsWith("iPhone");
    #else
    return false;
    #end
  }
}
