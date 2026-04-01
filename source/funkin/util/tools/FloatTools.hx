package funkin.util.tools;

/**
 * Utilities for performing common math operations.
 */
@:nullSafety
class FloatTools
{
  /**
   * Constrain a float between a minimum and maximum value.
   *
   * @param value The value to clamp.
   * @param min The minimum value.
   * @param max The maximum value.
   * @return The clamped value.
   */
  public static function clamp(value:Float, min:Float, max:Float):Float
  {
    return Math.max(min, Math.min(max, value));
  }

  /**
   * Round a float to a certain number of decimal places.
   *
   * @param number The number to round.
   * @param precision The number of decimal places to round to.
   * @return The rounded number.
   */
  public static function round(number:Float, precision:Int = 2):Float
  {
    number *= Math.pow(10, precision);
    return Math.round(number) / Math.pow(10, precision);
  }
}
