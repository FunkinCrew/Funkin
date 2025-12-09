package funkin.util;

import flixel.util.FlxColor;

/**
 * Non inline FlxColor functions for use in hscript files
 */
@:nullSafety
class FlxColorUtil
{
  /**
   * Get an interpolated color based on two different colors.
   *
   * @param 	Color1 The first color
   * @param 	Color2 The second color
   * @param 	Factor Value from 0 to 1 representing how much to shift Color1 toward Color2
   * @return	The interpolated color
   */
  public static function interpolate(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor
  {
    return FlxColor.interpolate(Color1, Color2, Factor);
  }
}
