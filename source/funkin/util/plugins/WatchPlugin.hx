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

    var stateClassName = Type.getClassName(Type.getClass(FlxG.state));
    FlxG.watch.addQuick("currentState", stateClassName);
    var subStateClassNames = [];
    var subState = FlxG.state.subState;
    while (subState != null)
    {
      subStateClassNames.push(Type.getClassName(Type.getClass(subState)));
      subState = subState.subState;
    }
    FlxG.watch.addQuick("currentSubStates", subStateClassNames.join(", "));

    FlxG.watch.addQuick("songPosition", Conductor.instance.songPosition);
    FlxG.watch.addQuick("songPositionNoOffset", Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);

    FlxG.watch.addQuick("musicLength", FlxG.sound?.music?.length ?? 0.0);
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
