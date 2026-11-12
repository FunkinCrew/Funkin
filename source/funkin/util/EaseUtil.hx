package funkin.util;

/**
 * Utility functions for working with easing and interpolation.
 */
@:nullSafety
class EaseUtil
{
  /**
   * Constructs an ease function that eases via steps.
   * Useful for "retro" style fades (week 6!)
   * @param steps how many steps to ease over
   * @param ease The underlying easing function to use. Defaults to `linear`.
   * @return The new stepped easing function.
   */
  public static function stepped(steps:Int, ?ease:Float->Float):Float->Float
  {
    if (ease == null) ease = (t:Float) -> t;

    return function(t:Float):Float
    {
      var base = ease(t);
      return Math.floor(base * steps) / steps;
    }
  }

  /**
   * Constructs an ease function that eases via steps,
   * at a fixed frame rate over a given duration.
   * @param duration The duration of the ease in seconds.
   * @param fps The frame rate to step the ease at.
   * @param eaese The underlying easing function to use. Defaults to `linear`.
   * @return The new stepped easing function.
   */
  public static function steppedFPS(duration:Float, fps:Int, ?ease:Float->Float):Float->Float
  {
    var stepCount:Int = Math.round(duration * fps);

    return stepped(stepCount, ease);
  }

  /**
   * Like steppedFPS, but quantizes TIME instead of the eased value, so the result
   * looks like hand-keyed animation played at the given fps (Like "on twos" at 15fps).
   * @param duration The duration of the tween in seconds.
   * @param fps The frame rate to sample the ease at.
   * @param ease The underlying easing function. Defaults to `linear
   */
  public static function steppedTime(duration:Float, fps:Float, ?ease:Float->Float):Float->Float
  {
    if (ease == null) ease = (t:Float) -> t;
    var steps:Float = Math.max(1, Math.round(duration * fps));

    return (t:Float) -> ease(Math.floor(t * steps) / steps);
  }

  /**
   * A back-out ease with an adjustable overshoot.
   * The peak overshoot (as a fraction of the distance travelled) is "4c^3 / (27(c+1)^2)".
   * So we get..
   * c = 1.70158 -> 10%, c = 2.6 -> 20%, c = 3.0 -> 25%, c = 4.9 -> 50%, c = 7.3 -> 83%.
   * @param overshoot Overshoot
   */
  public static function backOut(overshoot:Float = 1.70158):Float->Float
  {
    return (t:Float) -> MathUtil.easeOutBack(t, overshoot);
  }

  /**
   * A back-in-out ease with an adjustable overshoot. The anticipation and overshoot
   * are each half of what backOut would give for the same "c" (5% at the default).
   * @param overshoot Overshoot
   */
  public static function backInOut(overshoot:Float = 1.70158):Float->Float
  {
    return (t:Float) ->
    {
      if (t <= 0.0) return 0.0;
      if (t >= 1.0) return 1.0;
      return t < 0.5 ? MathUtil.easeInBack(t * 2, overshoot) / 2 : 0.5 + MathUtil.easeOutBack(t * 2 - 1, overshoot) / 2;
    };
  }

  /**
   * An ease that's meant to replicate flash's nice easy ease curve editor.
   * This implements proper CSS-style cubic-bezier easing with X-inversion.
   *
   * The control points define a curve where:
   * - X axis represents time (input)
   * - Y axis represents the eased value (output)
   *
   * Refer to https://cubic-bezier.com/ for a nice reference of what the input values -> output easing
   *
   * This function solves for the parameter where X equals the input time,
   * then returns the corresponding Y value.
   *
   * @param x1 X coordinate of first control point (0-1 recommended)
   * @param y1 Y coordinate of first control point
   * @param x2 X coordinate of second control point (0-1 recommended)
   * @param y2 Y coordinate of second control point
   * @return Float->Float An easing function that takes time (0-1) and returns eased value
   */
  public static inline function bezier(x1:Float, y1:Float, x2:Float, y2:Float):Float->Float
  {
    return (t:Float) ->
    {
      // Handle edge cases for performance
      if (t <= 0.0) return 0.0;
      if (t >= 1.0) return 1.0;

      // Solve for parameter u where X(u) = t
      var u:Float = BezierUtil.solveCubicBezierX(t, x1, x2);

      // Return Y(u) - the eased value
      return BezierUtil.calcCubicBezierY(u, y1, y2);
    }
  }
}
