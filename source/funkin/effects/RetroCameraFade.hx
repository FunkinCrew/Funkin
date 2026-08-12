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

    new FlxTimer().start(time / stepsTotal, _ ->
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

    var matrixDerp = [
      1, 0, 0, 0, 1.0 * 255,
      0, 1, 0, 0, 1.0 * 255,
      0, 0, 1, 0, 1.0 * 255,
      0, 0, 0, 1,         0
    ];
    camera.filters = [new ColorMatrixFilter(matrixDerp)];

    new FlxTimer().start(time / stepsTotal, _ ->
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

    new FlxTimer().start(time / stepsTotal, _ ->
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

    var matrixDerp = [
      1, 0, 0, 0, -1.0 * 255,
      0, 1, 0, 0, -1.0 * 255,
      0, 0, 1, 0, -1.0 * 255,
      0, 0, 0, 1,          0
    ];
    camera.filters = [new ColorMatrixFilter(matrixDerp)];

    new FlxTimer().start(time / stepsTotal, _ ->
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
    }, camSteps + 1);
  }
}
