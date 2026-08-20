package funkin.effects;

import flixel.util.FlxTimer;
import flixel.FlxCamera;
import openfl.filters.ColorMatrixFilter;

/**
 * A class that is used for creating a retro-styled fading effect.
 * This effect is used primarily in Week 6.
 */
@:nullSafety
class RetroCameraFade
{
  /**
   * The currently running fade timer.
   * Can be `null`!
   */
  static var fadeTimer:Null<FlxTimer>;

  /**
   * Fades the camera to white.
   *
   * @param	camera		The target camera that the effect should happen on.
   * @param camSteps		The amount of steps it should take before finishing the effect.
   * @param	time		The duration it takes for the fade to finish.
   */
  public static function fadeWhite(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = 0;
    var stepsTotal:Int = camSteps;

    if (fadeTimer != null)
    {
      fadeTimer.cancel();
      fadeTimer.destroy();
      fadeTimer = null;

      camera.filters = [];
    }

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ ->
    {
      var V:Float = (1 / stepsTotal) * steps;
      if (steps == stepsTotal) V = 1;

      var matrix = [
        1, 0, 0, 0, V * 255,
        0, 1, 0, 0, V * 255,
        0, 0, 1, 0, V * 255,
        0, 0, 0, 1,       0
      ];
      camera.filters = [new ColorMatrixFilter(matrix)];
      steps++;

      if (fadeTimer != null && fadeTimer.loopsLeft < 1)
      {
        fadeTimer.cancel();
        fadeTimer.destroy();
        fadeTimer = null;
      }
    }, stepsTotal + 1);
  }

  /**
   * Fades the camera from white.
   *
   * @param	camera		The target camera that the effect should happen on.
   * @param camSteps		The amount of steps it should take before finishing the effect.
   * @param	time		The duration it takes for the fade to finish.
   */
  public static function fadeFromWhite(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = camSteps;
    var stepsTotal:Int = camSteps;

    if (fadeTimer != null)
    {
      fadeTimer.cancel();
      fadeTimer.destroy();
      fadeTimer = null;
    }

    var matrixDerp = [
      1, 0, 0, 0, 1.0 * 255,
      0, 1, 0, 0, 1.0 * 255,
      0, 0, 1, 0, 1.0 * 255,
      0, 0, 0, 1,         0
    ];
    camera.filters = [new ColorMatrixFilter(matrixDerp)];

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ ->
    {
      var V:Float = (1 / stepsTotal) * steps;
      if (steps == stepsTotal) V = 1;

      var matrix = [
        1, 0, 0, 0, V * 255,
        0, 1, 0, 0, V * 255,
        0, 0, 1, 0, V * 255,
        0, 0, 0, 1,       0
      ];
      camera.filters = [new ColorMatrixFilter(matrix)];
      steps--;

      if (fadeTimer != null && fadeTimer.loopsLeft < 1)
      {
        fadeTimer.cancel();
        fadeTimer.destroy();
        fadeTimer = null;
      }
    }, camSteps);
  }

  /**
   * Fades the camera to black.
   *
   * @param	camera		The target camera that the effect should happen on.
   * @param camSteps		The amount of steps it should take before finishing the effect.
   * @param	time		The duration it takes for the fade to finish.
   */
  public static function fadeToBlack(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = 0;
    var stepsTotal:Int = camSteps;

    if (fadeTimer != null)
    {
      fadeTimer.cancel();
      fadeTimer.destroy();
      fadeTimer = null;

      camera.filters = [];
    }

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ ->
    {
      var V:Float = (1 / stepsTotal) * steps;
      if (steps == stepsTotal) V = 1;

      var matrix = [
        1, 0, 0, 0, -V * 255,
        0, 1, 0, 0, -V * 255,
        0, 0, 1, 0, -V * 255,
        0, 0, 0, 1,        0
      ];
      camera.filters = [new ColorMatrixFilter(matrix)];
      steps++;

      if (fadeTimer != null && fadeTimer.loopsLeft < 1)
      {
        fadeTimer.cancel();
        fadeTimer.destroy();
        fadeTimer = null;
      }
    }, camSteps);
  }

  /**
   * Fades the camera black.
   *
   * @param	camera		The target camera that the effect should happen on.
   * @param camSteps		The amount of steps it should take before finishing the effect.
   * @param	time		The duration it takes for the fade to finish.
   */
  public static function fadeBlack(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = camSteps;
    var stepsTotal:Int = camSteps;

    if (fadeTimer != null)
    {
      fadeTimer.cancel();
      fadeTimer.destroy();
      fadeTimer = null;

      camera.filters = [];
    }

    var matrixDerp = [
      1, 0, 0, 0, -1.0 * 255,
      0, 1, 0, 0, -1.0 * 255,
      0, 0, 1, 0, -1.0 * 255,
      0, 0, 0, 1,          0
    ];
    camera.filters = [new ColorMatrixFilter(matrixDerp)];

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ ->
    {
      var V:Float = (1 / stepsTotal) * steps;
      if (steps == stepsTotal) V = 1;

      var matrix = [
        1, 0, 0, 0, -V * 255,
        0, 1, 0, 0, -V * 255,
        0, 0, 1, 0, -V * 255,
        0, 0, 0, 1,        0
      ];
      camera.filters = [new ColorMatrixFilter(matrix)];
      steps--;

      if (fadeTimer != null && fadeTimer.loopsLeft < 1)
      {
        fadeTimer.cancel();
        fadeTimer.destroy();
        fadeTimer = null;
      }
    }, camSteps + 1);
  }
}
