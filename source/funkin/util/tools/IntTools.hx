package funkin.util.tools;

/**
 * Utilities for performing common math operations.
 */
@:nullSafety
class IntTools
{
  /**
   * Constrain an integer between a minimum and maximum value.
   */
  public static function clamp(value:Int, min:Int, max:Int):Int
  {
    // Don't use Math.min because it returns a Float.
    return value < min ? min : value > max ? max : value;
  }
}
