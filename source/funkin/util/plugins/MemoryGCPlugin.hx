package funkin.util.plugins;

import flixel.FlxBasic;
import funkin.util.TimerUtil;

/**
 * A plugin which adds functionality to press `Ins` to immediately perform memory garbage collection.
 */
class MemoryGCPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new MemoryGCPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.INSERT)
    {
      var perfStart:Float = TimerUtil.start();
      funkin.util.MemoryUtil.collect(true);
      trace('Memory GC took: ${TimerUtil.seconds(perfStart)}');
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
