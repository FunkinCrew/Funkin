package funkin.util;

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
    return js.html.Navigator.platform.startsWith("Mac")
      || js.html.Navigator.platform.startsWith("iPad")
      || js.html.Navigator.platform.startsWith("iPhone");
    #else
    return false;
    #end
  }
}
