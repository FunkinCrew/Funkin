package;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import haxe.PosInfos;
import massive.munit.Assert;

using flixel.util.FlxArrayUtil;

/**
 * @see https://github.com/HaxeFlixel/flixel/tree/dev/tests/unit
 */
class FunkinAssert
{
  /**
   * Assert if `expected` is within `margin` of `actual`, and fail if not.
   * Useful for comparting Float values.
   *
   * @param expected The expected value of the test.
   * @param actual The actual value of the test.
   * @param margin The allowed margin of error between the expected and actual values.
   * @param info Info on the position this function was called from. Magic value, passed automatically.
   */
  public static function areNear(expected:Float, actual:Float, margin:Float = 0.001, ?info:PosInfos):Void
  {
    if (areNearHelper(expected, actual)) Assert.assertionCount++;
    else
      Assert.fail('Value [$actual] is not within [$margin] of [$expected]', info);
  }

  public static function rectsNear(expected:FlxRect, actual:FlxRect, margin:Float = 0.001, ?info:PosInfos):Void
  {
    var areNear = areNearHelper(expected.x, actual.x, margin)
      && areNearHelper(expected.y, actual.y, margin)
      && areNearHelper(expected.width, actual.width, margin)
      && areNearHelper(expected.height, actual.height, margin);

    if (areNear) Assert.assertionCount++;
    else
      Assert.fail('Value [$actual] is not within [$margin] of [$expected]', info);
  }

  static function areNearHelper(expected:Float, actual:Float, margin:Float = 0.001):Bool
  {
    return actual >= expected - margin && actual <= expected + margin;
  }

  public static function arraysEqual<T>(expected:Array<T>, actual:Array<T>, ?info:PosInfos):Void
  {
    if (expected.equals(actual)) Assert.assertionCount++;
    else
      Assert.fail('\nExpected\n   ${expected}\nbut was\n   ${actual}\n', info);
  }

  public static function arraysNotEqual<T>(expected:Array<T>, actual:Array<T>, ?info:PosInfos):Void
  {
    if (!expected.equals(actual)) Assert.assertionCount++;
    else
      Assert.fail('\nValue\n   ${actual}\nwas equal to\n   ${expected}\n', info);
  }

  public static function pointsEqual(expected:FlxPoint, actual:FlxPoint, ?msg:String, ?info:PosInfos)
  {
    if (expected.equals(actual)) Assert.assertionCount++;
    else if (msg != null) Assert.fail(msg, info);
    else
      Assert.fail("Value [" + actual + "] was not equal to expected value [" + expected + "]", info);
  }

  public static function pointsNotEqual(expected:FlxPoint, actual:FlxPoint, ?msg:String, ?info:PosInfos)
  {
    if (!expected.equals(actual)) Assert.assertionCount++;
    else if (msg != null) Assert.fail(msg, info);
    else
      Assert.fail("Value [" + actual + "] was equal to value [" + expected + "]", info);
  }
}
