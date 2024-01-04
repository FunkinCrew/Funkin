package funkin.util.plugins;

import flixel.FlxBasic;

/**
 * A plugin which adds functionality to display several universally important values
 * in the Flixel variable watch window.
 */
class WatchPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new WatchPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    FlxG.watch.addQuick("songPosition", Conductor.songPosition);
    FlxG.watch.addQuick("songPositionNoOffset", Conductor.songPosition + Conductor.instrumentalOffset);
    FlxG.watch.addQuick("musicTime", FlxG.sound?.music?.time ?? 0.0);
    FlxG.watch.addQuick("bpm", Conductor.bpm);
    FlxG.watch.addQuick("currentMeasureTime", Conductor.currentMeasureTime);
    FlxG.watch.addQuick("currentBeatTime", Conductor.currentBeatTime);
    FlxG.watch.addQuick("currentStepTime", Conductor.currentStepTime);
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
