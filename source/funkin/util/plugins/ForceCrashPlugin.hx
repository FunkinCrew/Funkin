package funkin.util.plugins;

import flixel.FlxBasic;

/**
 * A plugin which forcibly crashes the application.
 * TODO: Should we disable this in release builds?
 */
@:nullSafety
class ForceCrashPlugin extends FlxBasic
{
  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new ForceCrashPlugin());
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Ctrl + Alt + Shift + L = Crash the game for debugging purposes
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.L)
    {
      // TODO: Make this message 87% funnier.
      throw "DEBUG: Crashing the game via debug keybind!";
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
