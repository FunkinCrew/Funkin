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
   */
  public static function bezier2(p:Float, a:FlxPoint, b:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix2(p, a.x, b.x), mix2(p, a.y, b.y));
  }

  /**
   * A bezier curve with three points.
   * @param p The percentage of the way through the curve.
   * @param a The start point.
   * @param b The control point.
   * @param c The end point.
   */
  public static function bezier3(p:Float, a:FlxPoint, b:FlxPoint, c:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix3(p, a.x, b.x, c.x), mix3(p, a.y, b.y, c.y));
  }

  /**
   * A bezier curve with four points.
   * @param p The percentage of the way through the curve.
   * @param a The start point.
   * @param b The first control point.
   * @param c The second control point.
   * @param d The end point.
   */
  public static function bezier4(p:Float, a:FlxPoint, b:FlxPoint, c:FlxPoint, d:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix4(p, a.x, b.x, c.x, d.x), mix4(p, a.y, b.y, c.y, d.y));
  }

  /**
   * A bezier curve with four points.
   * @param p The percentage of the way through the curve.
   * @param a The start point.
   * @param b The first control point.
   * @param c The second control point.
   * @param c The third control point.
   * @param d The end point.
   */
  public static function bezier5(p:Float, a:FlxPoint, b:FlxPoint, c:FlxPoint, d:FlxPoint, e:FlxPoint):FlxPoint
  {
    return new FlxPoint(mix5(p, a.x, b.x, c.x, d.x, e.x), mix5(p, a.y, b.y, c.y, d.y, e.y));
  }
}
