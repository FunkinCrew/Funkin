package funkin.util;

/**
 * Utility functions related to specific platforms.
 */
@:nullSafety
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
    return js.Browser.window.navigator.platform.startsWith('Mac')
      || js.Browser.window.navigator.platform.startsWith('iPad')
      || js.Browser.window.navigator.platform.startsWith('iPhone');
    #else
    return false;
    #end
  }

  /**
   * Detects and returns the current host platform.
   * Always returns `HTML5` on web, regardless of the computer running that browser.
   * @return The host platform, or `null` if the platform could not be detected.
   */
  public static function detectHostPlatform():Null<HostPlatform>
  {
    #if html5
    return HTML5;
    #elseif android
    return ANDROID;
    #elseif ios
    return IOS;
    #else
    switch (Sys.systemName())
    {
      case ~/window/i.match(_) => true:
        return WINDOWS;
      case ~/linux/i.match(_) => true:
        return LINUX;
      case ~/mac/i.match(_) => true:
        return MAC;
      default:
        return null;
    }
    #end
  }
}

/**
 * Represents a host platform.
 */
enum HostPlatform
{
  WINDOWS;
  LINUX;
  MAC;
  HTML5;
  ANDROID;
  IOS;
}
