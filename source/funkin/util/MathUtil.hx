package funkin.util;

/**
 * Utilities for performing mathematical operations.
 */
class MathUtil
{
  /**
   * Perform linear interpolation between the base and the target, based on the current framerate.
   */
  public static function coolLerp(base:Float, target:Float, ratio:Float):Float
  {
    return base + cameraLerp(ratio) * (target - base);
  }

  public static function cameraLerp(lerp:Float):Float
  {
    return lerp * (FlxG.elapsed / (1 / 60));
  }

  /**
   * Get the logarithm of a value with a given base.
   * @param base The base of the logarithm.
   * @param value The value to get the logarithm of.
   * @return `log_base(value)`
   */
  public static function logBase(base:Float, value:Float):Float
  {
    return Math.log(value) / Math.log(base);
  }
}
