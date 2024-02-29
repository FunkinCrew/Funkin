package funkin.util.plugins;

import flixel.FlxBasic;

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
      var perfStart:Float = Sys.time();
      funkin.util.MemoryUtil.collect(true);
      var perfEnd:Float = Sys.time();
      trace("Memory GC took " + (perfEnd - perfStart) + " seconds");
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
