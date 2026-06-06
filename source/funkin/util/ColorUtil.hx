package funkin.util;

import haxe.ui.util.Color as HaxeUIColor;
import flixel.util.FlxColor;

/**
 * Utility functions for working with colors.
 */
class ColorUtil
{
  static final WHITE:HaxeUIColor = 0xFFFFFF;
  static final OFFWHITE:HaxeUIColor = 0xF9F9F9;
  static final OFFBLACK:HaxeUIColor = 0x1A1A1A;
  static final BLACK:HaxeUIColor = 0x000000;

  /**
   * Based on the provided background color, calculate the text color that will be most readable.
   *
   * @param backgroundColor The background color to calculate the text color for.
   * @return The text color to use.
   */
  public static function getHaxeUITextColor(backgroundColor:HaxeUIColor):HaxeUIColor
  {
    var brightness:Float = luminanceFromHaxeUIColor(backgroundColor);
    // Black on bright backgrounds, white on dark backgrounds.
    return (brightness > 0.65) ? OFFBLACK : OFFWHITE;
  }

  static function brightnessFromHaxeUIColor(color:HaxeUIColor):Float
  {
    return Math.max(color.r, Math.max(color.g, color.b)) / 255.0;
  }

  static function luminanceFromHaxeUIColor(color:HaxeUIColor):Float
  {
    return ((color.r / 255 * 299) + (color.g / 255 * 587) + (color.b / 255 * 114)) / 1000;
  }
}
