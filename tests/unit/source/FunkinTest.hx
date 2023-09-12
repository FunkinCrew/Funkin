package;

import openfl.utils.Assets;
import openfl.errors.Error;
import flixel.FlxG;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import massive.munit.Assert;

/**
 * @see https://github.com/HaxeFlixel/flixel/tree/dev/tests/unit
 */
@:nullSafety
class FunkinTest
{
  public static final MS_PER_STEP:Float = 1.0 / 60.0 * 1000;

  // approx. amount of ticks at 60 fps
  static inline var TICKS_PER_FRAME:UInt = 25;
  static var totalSteps:UInt = 0;

  var destroyable:Null<IFlxDestroyable> = null;

  public function new() {}

  @After
  @:access(flixel)
  function after()
  {
    // Redefine how the game gets the time during tests.
    FlxG.game.getTimer = function() {
      return totalSteps * TICKS_PER_FRAME;
    }

    // make sure we have the same starting conditions for each test
    resetGame();
  }

  /**
   * Advance the game simulation.
   * @param steps The amount to advance the game by.
   * @param callback A function to call after each step.
   */
  @:access(flixel)
  function step(steps:UInt = 1, ?callback:Void->Void)
  {
    for (i in 0...steps)
    {
      FlxG.game.step();
      if (callback != null) callback();
      totalSteps++;
    }
  }

  function resetGame()
  {
    FlxG.resetGame();
    step();
  }

  function switchState(nextState:FlxState)
  {
    FlxG.switchState(nextState);
    step();
  }

  function resetState()
  {
    FlxG.resetState();
    step();
  }

  @Test
  public function testAssert()
  {
    Assert.areEqual(4, 2 + 2);
  }

  @Test
  function testDestroy()
  {
    if (destroyable == null)
    {
      return;
    }

    try
    {
      destroyable.destroy();
      destroyable.destroy();
    }
    catch (e:Error)
    {
      Assert.fail(e.message);
    }
  }

  function finishTween(tween:FlxTween)
  {
    while (!tween.finished)
    {
      step();
    }
  }
}
