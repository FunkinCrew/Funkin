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
   * The fade currently running on each camera.
   */
  static var fadeTimers:Map<FlxCamera, FlxTimer> = [];

  /**
   * Stops the fade running on the given camera, if there is one.
   * @return Whether a fade was interrupted.
   */
  static function cancelFade(camera:FlxCamera):Bool
  {
    // Drop fades whose timers were cleared elsewhere, like on a state switch.
    var staleCameras:Array<FlxCamera> = [];
    for (otherCamera => otherTimer in fadeTimers)
    {
      if (otherCamera != camera && (otherTimer.finished || !otherTimer.active)) staleCameras.push(otherCamera);
    }
    for (staleCamera in staleCameras)
    {
      fadeTimers.remove(staleCamera);
    }

    var fadeTimer:Null<FlxTimer> = fadeTimers.get(camera);
    if (fadeTimer == null) return false;

    fadeTimer.cancel();
    fadeTimer.destroy();
    fadeTimers.remove(camera);

    return true;
  }

  static function finishFade(camera:FlxCamera, timer:FlxTimer):Void
  {
    if (timer.loopsLeft >= 1) return;

    if (fadeTimers.get(camera) == timer) fadeTimers.remove(camera);
  }

  /**
   * Fades the camera to white.
   *
   * @param camera The target camera that the effect should happen on.
   * @param camSteps The amount of steps it should take before finishing the effect.
   * @param time The duration it takes for the fade to finish.
   */
  public static function fadeWhite(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = 0;
    var stepsTotal:Int = camSteps;

    if (cancelFade(camera)) camera.filters = [];

    fadeTimers.set(camera, new FlxTimer().start(time / stepsTotal, (timer:FlxTimer) ->
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

      finishFade(camera, timer);
    }, stepsTotal + 1));
  }

  /**
   * Fades the camera from white.
   *
   * @param camera The target camera that the effect should happen on.
   * @param camSteps The amount of steps it should take before finishing the effect.
   * @param time The duration it takes for the fade to finish.
   */
  public static function fadeFromWhite(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = camSteps;
    var stepsTotal:Int = camSteps;

    cancelFade(camera);

    var matrixDerp = [
      1, 0, 0, 0, 1.0 * 255,
      0, 1, 0, 0, 1.0 * 255,
      0, 0, 1, 0, 1.0 * 255,
      0, 0, 0, 1,         0
    ];
    camera.filters = [new ColorMatrixFilter(matrixDerp)];

    fadeTimers.set(camera, new FlxTimer().start(time / stepsTotal, (timer:FlxTimer) ->
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

      finishFade(camera, timer);
    }, camSteps));
  }

  /**
   * Fades the camera to black.
   *
   * @param camera The target camera that the effect should happen on.
   * @param camSteps The amount of steps it should take before finishing the effect.
   * @param time The duration it takes for the fade to finish.
   */
  public static function fadeToBlack(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = 0;
    var stepsTotal:Int = camSteps;

    if (cancelFade(camera)) camera.filters = [];

    fadeTimers.set(camera, new FlxTimer().start(time / stepsTotal, (timer:FlxTimer) ->
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

      finishFade(camera, timer);
    }, camSteps));
  }

  /**
   * Fades the camera black.
   *
   * @param camera The target camera that the effect should happen on.
   * @param camSteps The amount of steps it should take before finishing the effect.
   * @param time The duration it takes for the fade to finish.
   */
  public static function fadeBlack(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = camSteps;
    var stepsTotal:Int = camSteps;

    if (cancelFade(camera)) camera.filters = [];

    var matrixDerp = [
      1, 0, 0, 0, -1.0 * 255,
      0, 1, 0, 0, -1.0 * 255,
      0, 0, 1, 0, -1.0 * 255,
      0, 0, 0, 1,          0
    ];
    camera.filters = [new ColorMatrixFilter(matrixDerp)];

    fadeTimers.set(camera, new FlxTimer().start(time / stepsTotal, (timer:FlxTimer) ->
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

      finishFade(camera, timer);
    }, camSteps + 1));
  }
}
