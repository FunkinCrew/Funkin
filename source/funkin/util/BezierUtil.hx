package funkin.util;

import flixel.math.FlxPoint;

/**
 * Utilities for performing math with bezier curves.
 */
@:nullSafety
class BezierUtil
{
  /**
   * Linearly interpolate between two values.
   * Depending on p, 0 = a, 1 = b, 0.5 = halfway between a and b.
   */
  static inline function mix2(p:Float, a:Float, b:Float):Float
  {
    return a * (1 - p) + (b * p);
  }

  /**
   * Linearly interpolate between three values.
   * Depending on p, 0 = a, 0.5 = b, 1 = c, 0.25 = halfway between a and b, etc.
   */
  static inline function mix3(p:Float, a:Float, b:Float, c:Float):Float
  {
    return mix2(p, mix2(p, a, b), mix2(p, b, c));
  }

  static inline function mix4(p:Float, a:Float, b:Float, c:Float, d:Float):Float
  {
    return mix2(p, mix3(p, a, b, c), mix3(p, b, c, d));
  }

  static inline function mix5(p:Float, a:Float, b:Float, c:Float, d:Float, e:Float):Float
  {
    return mix2(p, mix4(p, a, b, c, d), mix4(p, b, c, d, e));
  }

  /**
   * A bezier curve with two points.
   * This is really just linear interpolation but whatever.
   * @param p The percentage of the way through the curve, 0.0 to 1.0
   * @param a The start point
   * @param b The control point
   * @return FlxPoint
   */
  public static function bezier2(p:Float, a:FlxPoint, b:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix2(p, a.x, b.x), mix2(p, a.y, b.y));
  }

  /**
   * A bezier curve with three points.
   *
   * @param p The percentage of the way through the curve.
   * @param a The start point.
   * @param b The control point.
   * @param c The end point.
   * @return FlxPoint
   */
  public static function bezier3(p:Float, a:FlxPoint, b:FlxPoint, c:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix3(p, a.x, b.x, c.x), mix3(p, a.y, b.y, c.y));
  }

  /**
   * A bezier curve with four points.
   *
   * @param p The percentage of the way through the curve.
   * @param a The start point.
   * @param b The first control point.
   * @param c The second control point.
   * @param d The end point.
   * @return FlxPoint
   */
  public static function bezier4(p:Float, a:FlxPoint, b:FlxPoint, c:FlxPoint, d:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix4(p, a.x, b.x, c.x, d.x), mix4(p, a.y, b.y, c.y, d.y));
  }

  /**
   * A bezier curve with four points.
   *
   * @param p The percentage of the way through the curve.
   * @param a The start point.
   * @param b The first control point.
   * @param c The second control point.
   * @param c The third control point.
   * @param d The fourth control point.
   * @param e The end point.
   * @return FlxPoint
   */
  public static function bezier5(p:Float, a:FlxPoint, b:FlxPoint, c:FlxPoint, d:FlxPoint, e:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix5(p, a.x, b.x, c.x, d.x, e.x), mix5(p, a.y, b.y, c.y, d.y, e.y));
  }

  /**
   * Calculate the X coordinate of a cubic bezier curve at parameter t.
   * For easing, this is used with control points (0,0), (x1, y1), (x2, y2), (1,1).
   *
   * @param t Parameter value (0 to 1)
   * @param x1 X coordinate of first control point
   * @param x2 X coordinate of second control point
   * @return X coordinate at parameter t
   */
  public static inline function calcCubicBezierX(t:Float, x1:Float, x2:Float):Float
  {
    // Formula: 3(1-t)²t·x1 + 3(1-t)t²·x2 + t³
    var t2:Float = t * t;
    var t3:Float = t2 * t;
    var mt:Float = 1.0 - t;
    var mt2:Float = mt * mt;

    return 3.0 * mt2 * t * x1 + 3.0 * mt * t2 * x2 + t3;
  }

  /**
   * Calculate the Y coordinate of a cubic bezier curve at parameter t.
   * For easing, this is used with control points (0,0), (x1, y1), (x2, y2), (1,1).
   *
   * @param t Parameter value (0 to 1)
   * @param y1 Y coordinate of first control point
   * @param y2 Y coordinate of second control point
   * @return Y coordinate at parameter t
   */
  public static inline function calcCubicBezierY(t:Float, y1:Float, y2:Float):Float
  {
    // Formula: 3(1-t)²t·y1 + 3(1-t)t²·y2 + t³
    var t2:Float = t * t;
    var t3:Float = t2 * t;
    var mt:Float = 1.0 - t;
    var mt2:Float = mt * mt;

    return 3.0 * mt2 * t * y1 + 3.0 * mt * t2 * y2 + t3;
  }

  /**
   * Calculate the derivative of the X coordinate with respect to t.
   * This is used in Newton-Raphson iteration for solving the bezier curve.
   *
   * @param t Parameter value (0 to 1)
   * @param x1 X coordinate of first control point
   * @param x2 X coordinate of second control point
   * @return Derivative dX/dt at parameter t
   */
  public static inline function calcCubicBezierXDerivative(t:Float, x1:Float, x2:Float):Float
  {
    // Derivative: 3(1-t)²·x1 + 6(1-t)t·(x2-x1) + 3t²·(1-x2)
    var t2:Float = t * t;
    var mt:Float = 1.0 - t;
    var mt2:Float = mt * mt;

    return 3.0 * mt2 * x1 + 6.0 * mt * t * (x2 - x1) + 3.0 * t2 * (1.0 - x2);
  }

  /**
   * Solve for parameter t where the X coordinate equals targetX using Newton-Raphson method.
   * This is the core of proper cubic-bezier easing - we find which parameter gives us
   * the desired X (time) value, then use that parameter to get the Y (eased) value.
   *
   * @param targetX The X coordinate we want to find (typically the input time, 0-1)
   * @param x1 X coordinate of first control point
   * @param x2 X coordinate of second control point
   * @param epsilon Convergence threshold (default 0.001)
   * @return Parameter t where X(t) ≈ targetX
   */
  public static function solveCubicBezierX(targetX:Float, x1:Float, x2:Float, epsilon:Float = 0.001):Float
  {
    // Handle edge cases
    if (targetX <= 0.0) return 0.0;
    if (targetX >= 1.0) return 1.0;

    // Initial guess: assume t ≈ x for a reasonably shaped curve
    var t:Float = targetX;

    // Newton-Raphson iteration
    // Formula: t_new = t_old - f(t)/f'(t)
    // where f(t) = X(t) - targetX
    for (i in 0...8)
    {
      var currentX:Float = calcCubicBezierX(t, x1, x2);
      var error:Float = currentX - targetX;

      // Check if we're close enough
      if (Math.abs(error) < epsilon)
      {
        return t;
      }

      // Calculate derivative (slope)
      var slope:Float = calcCubicBezierXDerivative(t, x1, x2);

      // Avoid division by zero
      if (Math.abs(slope) < 1e-6)
      {
        break;
      }

      // Newton-Raphson step
      t = t - (error / slope);

      // Clamp to valid range
      t = Math.max(0.0, Math.min(1.0, t));
    }

    // If Newton-Raphson didn't converge well, fall back to binary search
    // This is more robust but slower
    return binarySearchBezierX(targetX, x1, x2, epsilon);
  }

  /**
   * Binary search fallback for solving bezier X coordinate.
   * More robust than Newton-Raphson but slightly slower.
   *
   * @param targetX The X coordinate we want to find
   * @param x1 X coordinate of first control point
   * @param x2 X coordinate of second control point
   * @param epsilon Convergence threshold
   * @return Parameter t where X(t) ≈ targetX
   */
  static function binarySearchBezierX(targetX:Float, x1:Float, x2:Float, epsilon:Float):Float
  {
    var low:Float = 0.0;
    var high:Float = 1.0;
    var mid:Float = 0.5;

    // Binary search
    for (i in 0...20)
    {
      mid = (low + high) * 0.5;
      var currentX:Float = calcCubicBezierX(mid, x1, x2);
      var error:Float = currentX - targetX;

      if (Math.abs(error) < epsilon)
      {
        return mid;
      }

      if (currentX < targetX)
      {
        low = mid;
      }
      else
      {
        high = mid;
      }
    }

    return mid;
  }
}
