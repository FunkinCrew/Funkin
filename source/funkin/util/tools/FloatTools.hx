package funkin.util.tools;

/**
 * Utilities for performing common math operations.
 */
class FloatTools
{
  /**
   * Constrain a float between a minimum and maximum value.
   */
  public static function clamp(value:Float, min:Float, max:Float):Float
  {
    return Math.max(min, Math.min(max, value));
  }
}
