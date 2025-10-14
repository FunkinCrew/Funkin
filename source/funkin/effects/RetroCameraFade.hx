package funkin.effects;

import flixel.util.FlxTimer;
import flixel.FlxCamera;
import openfl.filters.ColorMatrixFilter;

@:nullSafety
class RetroCameraFade
{
  static var fadeTimer:Null<FlxTimer>;

  // im lazy, but we only use this for week 6
  // and also sorta yoinked for djflixel, lol !
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

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ -> {
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

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ -> {
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

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ -> {
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

    fadeTimer = new FlxTimer().start(time / stepsTotal, _ -> {
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
