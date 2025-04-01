package;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import haxe.PosInfos;
import massive.munit.Assert;

using flixel.util.FlxArrayUtil;

/**
 * @see https://github.com/HaxeFlixel/flixel/tree/dev/tests/unit
 */
@:nullSafety
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
  public static function areNear(expected:Float, ?actual:Float, margin:Float = 0.001, ?info:PosInfos):Void
  {
    if (actual == null) Assert.fail('Value [$actual] is null, and cannot be compared to [$expected]', info);
    if (areNearHelper(expected, actual)) Assert.assertionCount++;
    else
      Assert.fail('Value [$actual] is not within [$margin] of [$expected]', info);
  }

  public static function rectsNear(expected:FlxRect, ?actual:FlxRect, margin:Float = 0.001, ?info:PosInfos):Void
  {
    if (actual == null) Assert.fail('Value [$actual] is null, and cannot be compared to [$expected]', info);
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

  public static function arraysEqual<T>(expected:Array<T>, ?actual:Array<T>, ?info:PosInfos):Void
  {
    if (actual == null) Assert.fail('Value [$actual] is null, and cannot be compared to [$expected]', info);
    if (expected.equals(actual)) Assert.assertionCount++;
    else
      Assert.fail('\nExpected\n   ${expected}\nbut was\n   ${actual}\n', info);
  }

  public static function arraysNotEqual<T>(expected:Array<T>, ?actual:Array<T>, ?info:PosInfos):Void
  {
    if (actual == null) Assert.fail('Value [$actual] is null, and cannot be compared to [$expected]', info);
    if (!expected.equals(actual)) Assert.assertionCount++;
    else
      Assert.fail('\nValue\n   ${actual}\nwas equal to\n   ${expected}\n', info);
  }

  public static function pointsEqual(expected:FlxPoint, ?actual:FlxPoint, ?msg:String, ?info:PosInfos)
  {
    if (actual == null) Assert.fail('Value [$actual] is null, and cannot be compared to [$expected]', info);
    if (expected.equals(actual)) Assert.assertionCount++;
    else if (msg != null) Assert.fail(msg, info);
    else
      Assert.fail("Value [" + actual + "] was not equal to expected value [" + expected + "]", info);
  }

  public static function pointsNotEqual(expected:FlxPoint, ?actual:FlxPoint, ?msg:String, ?info:PosInfos)
  {
    if (actual == null) Assert.fail('Value [$actual] is null, and cannot be compared to [$expected]', info);
    if (!expected.equals(actual)) Assert.assertionCount++;
    else if (msg != null) Assert.fail(msg, info);
    else
      Assert.fail("Value [" + actual + "] was equal to value [" + expected + "]", info);
  }

  /**
   * Execute `targetFunc`, expecting it to throw an exception.
   * If it doesn't, or if the exception doesn't validate against the provided `predicate`, fail.
   */
  public static function validateThrows(targetFunc:Void->Void, predicate:Dynamic->Bool, ?info:PosInfos)
  {
    try
    {
      targetFunc();
      Assert.fail("Expected exception to be thrown, got no failure.", info);
    }
    catch (e:Dynamic)
    {
      if (predicate(e))
      {
        Assert.assertionCount++;
      }
      else
      {
        Assert.fail('Expected exception to match predicate, but failed (got ${e})', info);
      }
    }
  }

  /**
   * Execute `targetFunc`, expecting it to throw a `json2object.Error.CustomFunctionException` with a message matching `expected`.
   * I made this its own function since it's the most common specific use case of `validateThrows`.
   */
  public static function validateThrowsJ2OCustom(targetFunc:Void->Void, expected:String, ?info:PosInfos)
  {
    var predicate:Dynamic->Bool = function(err:Dynamic):Bool {
      if (!Std.isOfType(err, json2object.Error)) Assert.fail('Expected error of type json2object.Error, got ${Type.typeof(err)}');

      switch (err)
      {
        case json2object.Error.CustomFunctionException(msg, pos):
          if (msg != expected) Assert.fail('Expected message [${expected}], got [${msg}].');
        default:
          Assert.fail('Expected error of type CustomFunctionException, got [${err}].');
      }

      return true;
    };
    validateThrows(targetFunc, predicate, info);
  }

  static var capturedTraces:Array<String> = [];

  public static function initAssertTrace():Void
  {
    var oldTrace = haxe.Log.trace;
    haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
      onTrace(v, infos);
      // oldTrace(v, infos);
    };
  }

  public static function clearTraces():Void
  {
    capturedTraces = [];
  }

  @:nullSafety(Off) // Why isn't haxe.std null-safe?
  static function onTrace(v:Dynamic, ?infos:haxe.PosInfos)
  {
    // var str:String = haxe.Log.formatOutput(v, infos);
    var str:String = Std.string(v);
    capturedTraces.push(str);

    #if (sys && echo_traces)
    Sys.println('[TESTLOG] $str');
    #end
  }

  /**
   * Check the first string that was traced and validate it.
   * @param expected
   */
  public static inline function assertTrace(expected:String):Void
  {
    var actual:Null<String> = capturedTraces.shift();
    Assert.isNotNull(actual);
    Assert.areEqual(expected, actual);
  }

  /**
   * Check the first string that was traced and validate it.
   * @param expected
   */
  public static inline function assertLastTrace(expected:String):Void
  {
    var actual:Null<String> = capturedTraces.pop();
    Assert.isNotNull(actual);
    Assert.areEqual(expected, actual);
  }
}
