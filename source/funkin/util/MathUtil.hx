package funkin.util;
/**
 * Utilities for performing mathematical operations.
 */
@:nullSafety
class MathUtil
{
  /** Euler's constant and the base of the natural logarithm. */
  public static inline final E:Float = 2.71828182845904523536;

  /** The ratio of a circle's circumference to its diameter. */
  public static inline final PI:Float = 3.14159265358979323846;

  /** Tau (2 * PI). Represents a full 360-degree rotation in radians. */
  public static inline final TAU:Float = 6.28318530717958647692;

  /** Half PI (PI / 2). Represents 90 degrees in radians. */
  public static inline final HALF_PI:Float = 1.57079632679489661923;

  /** Quarter PI (PI / 4). Represents 45 degrees in radians. */
  public static inline final QUARTER_PI:Float = 0.78539816339744830962;

  /** Multiplier to convert degrees to radians. */
  public static inline final DEG2RAD:Float = PI / 180.0;

  /** Multiplier to convert radians to degrees. */
  public static inline final RAD2DEG:Float = 180.0 / PI;

  /** The square root of 2. Useful for normalizing diagonal movement. */
  public static inline final SQRT_2:Float = 1.41421356237309504880;

  /** Half of the square root of 2 (or 1 / SQRT_2). */
  public static inline final SQRT_1_2:Float = 0.70710678118654752440;

  /** The Golden Ratio. Great for UI proportions and procedural generation. */
  public static inline final GOLDEN_RATIO:Float = 1.61803398874989484820;

  /** Machine Epsilon. A remarkably small number used for float comparisons. */
  public static inline final EPSILON:Float = 0.0000001;

  /**
   * Safely compares two floats to see if they are practically equal, 
   * bypassing floating-point rounding errors.
   * * @param a The first float to compare.
   * @param b The second float to compare.
   * @param epsilon The maximum difference allowed.
   * @return True if the difference between a and b is less than or equal to epsilon.
   */
  public static inline function approximatelyEqual(a:Float, b:Float, epsilon:Float = EPSILON):Bool
  {
    return Math.abs(a - b) <= epsilon;
  }

  /**
   * Get the logarithm of a value with a given base.
   * @param base The base of the logarithm.
   * @param value The value to get the logarithm of.
   * @return `log_base(value)`
   */
  public static inline function logBase(base:Float, value:Float):Float
  {
    return Math.log(value) / Math.log(base);
  }

  /**
   * Get the base-2 exponent of a value.
   * @param x value
   * @return `2^x`
   */
  public static inline function exp2(x:Float):Float
  {
    return Math.pow(2, x);
  }

  /**
   * Performs a modulo operation to calculate the remainder of `a` divided by `b`.
   * Euclidean division remainder (always positive).
   * * @param a The dividend.
   * @param b The divisor.
   * @return `a mod b`.
   */
  public static inline function mod(a:Float, b:Float):Float
  {
    b = Math.abs(b);
    return a - b * Math.floor(a / b);
  }

  /**
   * Helper function to get the fractional part of a value.
   * @param x value
   * @return `x mod 1`.
   */
  public static inline function fract(x:Float):Float
  {
    return x - Math.floor(x);
  }

  /**
   * Wraps a value around a range (like an angle wrapping between 0 and 360).
   * * @param value The value to wrap.
   * @param min The minimum value of the range.
   * @param max The maximum value of the range.
   * @return The wrapped value.
   */
  public static inline function wrap(value:Float, min:Float, max:Float):Float
  {
    return mod(value - min, max - min) + min;
  }

  /**
   * Checks if an integer is a power of two (useful for texture generation).
   * * @param value The integer to check.
   * @return True if the integer is a power of two.
   */
  public static inline function isPowerOfTwo(value:Int):Bool
  {
    return value > 0 && (value & (value - 1)) == 0;
  }

  /**
   * Linear interpolation.
   *
   * @param base The starting value, when `alpha = 0`.
   * @param target The ending value, when `alpha = 1`.
   * @param alpha The percentage of the interpolation from `base` to `target`.
   * @return The interpolated value.
   */
  public static inline function lerp(base:Float, target:Float, alpha:Float):Float
  {
    return base + alpha * (target - base);
  }

  /**
   * The inverse of Lerp. Determines where a value lies between two points.
   * * @param base The starting value.
   * @param target The ending value.
   * @param value The value to find the percentage for.
   * @return A float between 0.0 and 1.0 representing the position.
   */
  public static inline function inverseLerp(base:Float, target:Float, value:Float):Float
  {
    if (base == target) return 0.0;
    return (value - base) / (target - base);
  }

  /**
   * Maps a value from one range to another. 
   * * @param value The current value to map.
   * @param start1 The lower bound of the current range.
   * @param stop1 The upper bound of the current range.
   * @param start2 The lower bound of the target range.
   * @param stop2 The upper bound of the target range.
   * @return The mapped value.
   */
  public static inline function remap(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
  {
    return lerp(start2, stop2, inverseLerp(start1, stop1, value));
  }

  /**
   * GLSL-style SmoothStep. Interpolates smoothly between two edges.
   * * @param edge0 The lower edge of the interpolation.
   * @param edge1 The upper edge of the interpolation.
   * @param x The value to interpolate.
   * @return The smoothed value.
   */
  public static function smoothStep(edge0:Float, edge1:Float, x:Float):Float
  {
    var t:Float = FlxMath.bound((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  /**
   * Exponential decay interpolation.
   *
   * @param base The starting or current value.
   * @param target The value this function approaches.
   * @param deltaTime The change in time along the function in seconds.
   * @param halfLife Time in seconds to reach halfway to `target`.
   * @return The interpolated value.
   */
  public static function smoothLerpDecay(base:Float, target:Float, deltaTime:Float, halfLife:Float):Float
  {
    if (deltaTime == 0) return base;
    if (base == target) return target;
    return lerp(target, base, exp2(-deltaTime / halfLife));
  }

  /**
   * Exponential decay interpolation with precision.
   *
   * @param base The starting or current value.
   * @param target The value this function approaches.
   * @param deltaTime The change in time along the function in seconds.
   * @param duration Time in seconds to reach `target` within `precision`.
   * @param precision Relative target precision of the interpolation. Defaults to 1% distance remaining.
   * @return The interpolated value.
   */
  public static function smoothLerpPrecision(base:Float, target:Float, deltaTime:Float, duration:Float, precision:Float = 1 / 100):Float
  {
    if (deltaTime == 0) return base;
    if (base == target) return target;
    return lerp(target, base, Math.pow(precision, deltaTime / duration));
  }

  /**
   * Snap a value to another if it's within a certain distance (inclusive).
   *
   * @param base The base value to conditionally snap.
   * @param target The target value to snap to.
   * @param threshold Maximum distance between the two for snapping to occur.
   * @return `target` if `base` is within `threshold` of it, otherwise `base`.
   */
  public static inline function snap(base:Float, target:Float, threshold:Float):Float
  {
    return Math.abs(base - target) <= threshold ? target : base;
  }

  /**
   * Circular Ease In/Out.
   * * @param x The interpolation progress.
   * @return The eased value.
   */
  public static function easeInOutCirc(x:Float):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    return (x < 0.5) 
      ? (1 - Math.sqrt(1 - 4 * x * x)) / 2 
      : (Math.sqrt(1 - 4 * (1 - x) * (1 - x)) + 1) / 2;
  }

  /**
   * Back Ease In/Out.
   * * @param x The interpolation progress.
   * @param c The overshoot amount.
   * @return The eased value.
   */
  public static function easeInOutBack(x:Float, c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    if (x < 0.5) {
      return (2 * x * x * ((c + 1) * 2 * x - c)) / 2;
    } else {
      var invX:Float = 1 - x;
      return (1 - 2 * invX * invX * ((c + 1) * 2 * invX - c)) / 2;
    }
  }

  /**
   * Back Ease In.
   * * @param x The interpolation progress.
   * @param c The overshoot amount.
   * @return The eased value.
   */
  public static function easeInBack(x:Float, c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    return (1 + c) * x * x * x - c * x * x;
  }

  /**
   * Back Ease Out.
   * * @param x The interpolation progress.
   * @param c The overshoot amount.
   * @return The eased value.
   */
  public static function easeOutBack(x:Float, c:Float = 1.70158):Float
  {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;
    var invX:Float = x - 1;
    return 1 + (c + 1) * (invX * invX * invX) + c * (invX * invX);
  }

  /**
   * GCD stands for Greatest Common Divisor.
   * Used in FullScreenScaleMode to prevent weird window resolutions from being counted as wide screen.
   * * @param m First integer.
   * @param n Second integer.
   * @return Int the common divisor between m and n.
   */
  public static function gcd(m:Int, n:Int):Int
  {
    m = m < 0 ? -m : m;
    n = n < 0 ? -n : n;
    
    var temp:Int;
    while (n != 0)
    {
      temp = m % n;
      m = n;
      n = temp;
    }
    return m;
  }

  /**
   * Least Common Multiple (LCM). Pairs with GCD.
   * * @param m First integer.
   * @param n Second integer.
   * @return Int the least common multiple of m and n.
   */
  public static inline function lcm(m:Int, n:Int):Int
  {
    if (m == 0 || n == 0) return 0;
    return Std.int(Math.abs(m * n) / gcd(m, n));
  }

  /**
   * Perform linear interpolation between the base and the target, based on the current framerate.
   * * @param base The starting value, when `progress <= 0`.
   * @param target The ending value, when `progress >= 1`.
   * @param ratio Value used to interpolate between `base` and `target`.
   * @return The interpolated value.
   */
  @:deprecated('Use smoothLerpPrecision instead')
  public static inline function coolLerp(base:Float, target:Float, ratio:Float):Float
  {
    return base + cameraLerp(ratio) * (target - base);
  }

  /**
   * Perform linear interpolation based on the current framerate.
   * * @param lerp Value used to interpolate between `base` and `target`.
   * @return The interpolated value.
   */
  @:deprecated('Use smoothLerpPrecision instead')
  public static inline function cameraLerp(lerp:Float):Float
  {
    return lerp * (FlxG.elapsed / (1 / 60));
  }

  /**
   * Backwards compatibility for `smoothLerpPrecision`.
   *
   * @param current The current value.
   * @param target The target value.
   * @param elapsed The time elapsed since the last frame.
   * @param duration The total duration of the interpolation.
   * @param precision The target precision of the interpolation. Defaults to 1% of distance remaining.
   * @return A value between the current value and the target value.
   */
  @:deprecated('Use smoothLerpPrecision instead')
  public static function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float
  {
    if (current == target) return target;
    var result:Float = lerp(current, target, 1 - Math.pow(precision, elapsed / duration));
    if (Math.abs(result - target) < (precision * target)) result = target;
    return result;
  }
}
