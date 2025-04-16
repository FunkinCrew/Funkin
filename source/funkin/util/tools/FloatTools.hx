package funkin.util.tools;

/**
 * Utilities for performing common math operations.
 */
@:nullSafety
class FloatTools
{
  /**
   * Constrain a float between a minimum and maximum value.
   */
  public static function clamp(value:Float, min:Float, max:Float):Float
  {
    return Math.max(min, Math.min(max, value));
  }

  /**
    Round a float to a certain number of decimal places.
  **/
  public static function round(number:Float, precision:Int = 2):Float
  {
    number *= Math.pow(10, precision);
    return Math.round(number) / Math.pow(10, precision);
  }
}
