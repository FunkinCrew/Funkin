package funkin.effects;

import flixel.util.FlxTimer;
import flixel.FlxCamera;
import openfl.filters.ColorMatrixFilter;

@:nullSafety
class RetroCameraFade
{
  // im lazy, but we only use this for week 6
  // and also sorta yoinked for djflixel, lol !
  public static function fadeWhite(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = 0;
    var stepsTotal:Int = camSteps;

    new FlxTimer().start(time / stepsTotal, _ -> {
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

    new FlxTimer().start(time / stepsTotal, _ -> {
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

  public static function fadeToBlack(camera:FlxCamera, camSteps:Int = 5, time:Float = 1):Void
  {
    var steps:Int = 0;
    var stepsTotal:Int = camSteps;

    new FlxTimer().start(time / stepsTotal, _ -> {
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

    new FlxTimer().start(time / stepsTotal, _ -> {
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
