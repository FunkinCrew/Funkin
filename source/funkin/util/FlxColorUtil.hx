package funkin.util;

import flixel.util.FlxColor;

/**
 * Non inline FlxColor functions for use in hscript files
 */
class FlxColorUtil
{
  public static var TRANSPARENT:FlxColor = FlxColor.TRANSPARENT;
  public static var WHITE:FlxColor = FlxColor.WHITE;
  public static var GRAY:FlxColor = FlxColor.GRAY;
  public static var BLACK:FlxColor = FlxColor.BLACK;
  public static var GREEN:FlxColor = FlxColor.GREEN;
  public static var LIME:FlxColor = FlxColor.LIME;
  public static var YELLOW:FlxColor = FlxColor.YELLOW;
  public static var ORANGE:FlxColor = FlxColor.ORANGE;
  public static var RED:FlxColor = FlxColor.RED;
  public static var PURPLE:FlxColor = FlxColor.PURPLE;
  public static var BLUE:FlxColor = FlxColor.BLUE;
  public static var BROWN:FlxColor = FlxColor.BROWN;
  public static var PINK:FlxColor = FlxColor.PINK;
  public static var MAGENTA:FlxColor = FlxColor.MAGENTA;
  public static var CYAN:FlxColor = FlxColor.CYAN;

  /**
   * Generate a color from integer RGB values (0 to 255)
   *
   * @param Red	The red value of the color from 0 to 255
   * @param Green	The green value of the color from 0 to 255
   * @param Blue	The green value of the color from 0 to 255
   * @param Alpha	How opaque the color should be, from 0 to 255
   * @return The color as a FlxColor
   */
  public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
  {
    return FlxColor.fromRGB(Red, Green, Blue, Alpha);
  }

  /**
   * Generate a color from float RGB values (0 to 1)
   *
   * @param Red	The red value of the color from 0 to 1
   * @param Green	The green value of the color from 0 to 1
   * @param Blue	The green value of the color from 0 to 1
   * @param Alpha	How opaque the color should be, from 0 to 1
   * @return The color as a FlxColor
   */
  public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
  {
    return FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
  }

  /**
   * Generate a color from CMYK values (0 to 1)
   *
   * @param Cyan		The cyan value of the color from 0 to 1
   * @param Magenta	The magenta value of the color from 0 to 1
   * @param Yellow	The yellow value of the color from 0 to 1
   * @param Black		The black value of the color from 0 to 1
   * @param Alpha		How opaque the color should be, from 0 to 1
   * @return The color as a FlxColor
   */
  public static function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
  {
    return FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
  }

  /**
   * Generate a color from HSB (aka HSV) components.
   *
   * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
   * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
   * @param	Brightness	(aka Value) A number between 0 and 1, indicating how bright the color should be.  0 is black, 1 is full bright.
   * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
   * @return	The color as a FlxColor
   */
  public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
  {
    return FlxColor.fromHSB(Hue, Saturation, Brightness, Alpha);
  }

  /**
   * Generate a color from HSL components.
   *
   * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
   * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
   * @param	Lightness	A number between 0 and 1, indicating the lightness of the color
   * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
   * @return	The color as a FlxColor
   */
  public static function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
  {
    return FlxColor.fromHSL(Hue, Saturation, Lightness, Alpha);
  }

  /**
   * Parses a `String` and returns a `FlxColor` or `null` if the `String` couldn't be parsed.
   *
   * Examples (input -> output in hex):
   *
   * - `0x00FF00`    -> `0xFF00FF00`
   * - `0xAA4578C2`  -> `0xAA4578C2`
   * - `#0000FF`     -> `0xFF0000FF`
   * - `#3F000011`   -> `0x3F000011`
   * - `GRAY`        -> `0xFF808080`
   * - `blue`        -> `0xFF0000FF`
   *
   * @param	str 	The string to be parsed
   * @return	A `FlxColor` or `null` if the `String` couldn't be parsed
   */
  public static function fromString(str:String):Null<FlxColor>
  {
    return FlxColor.fromString(str);
  }

  /**
   * Get HSB color wheel values in an array which will be 360 elements in size
   *
   * @param	Alpha Alpha value for each color of the color wheel, between 0 (transparent) and 255 (opaque)
   * @return	HSB color wheel as Array of FlxColors
   */
  public static function getHSBColorWheel(Alpha:Int = 255):Array<FlxColor>
  {
    return FlxColor.getHSBColorWheel(Alpha);
  }

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

  /**
   * Create a gradient from one color to another
   *
   * @param Color1 The color to shift from
   * @param Color2 The color to shift to
   * @param Steps How many colors the gradient should have
   * @param Ease An optional easing function, such as those provided in FlxEase
   * @return An array of colors of length Steps, shifting from Color1 to Color2
   */
  public static function gradient(Color1:FlxColor, Color2:FlxColor, Steps:Int, ?Ease:flixel.tweens.FlxEase.EaseFunction):Array<FlxColor>
  {
    return FlxColor.gradient(Color1, Color2, Steps, Ease);
  }

  /**
   * Multiply the RGB channels of two FlxColors
   */
  public static function multiply(lhs:FlxColor, rhs:FlxColor):FlxColor
  {
    return FlxColor.multiply(lhs, rhs);
  }

  /**
   * Add the RGB channels of two FlxColors
   */
  public static function add(lhs:FlxColor, rhs:FlxColor):FlxColor
  {
    return FlxColor.add(lhs, rhs);
  }

  /**
   * Subtract the RGB channels of one FlxColor from another
   */
  public static function subtract(lhs:FlxColor, rhs:FlxColor):FlxColor
  {
    return FlxColor.subtract(lhs, rhs);
  }
}
