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

    FlxG.watch.addQuick("songPosition", Conductor.instance.songPosition);
    FlxG.watch.addQuick("songPositionNoOffset", Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
    FlxG.watch.addQuick("musicTime", FlxG.sound?.music?.time ?? 0.0);
    FlxG.watch.addQuick("bpm", Conductor.instance.bpm);
    FlxG.watch.addQuick("currentMeasureTime", Conductor.instance.currentMeasureTime);
    FlxG.watch.addQuick("currentBeatTime", Conductor.instance.currentBeatTime);
    FlxG.watch.addQuick("currentStepTime", Conductor.instance.currentStepTime);
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
