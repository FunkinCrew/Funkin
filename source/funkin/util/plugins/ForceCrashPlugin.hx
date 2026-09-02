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

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Ctrl + Alt + Shift + L = Crash the game for debugging purposes
    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, L]))
    {
      // TODO: Make this message 87% funnier.
      throw 'DEBUG: Crashing the game via debug keybind!';
    }

    #if cpp
    // Ctrl + Alt + Shift + N = Force a native crash to test the native crash handler
    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, N]))
    {
      funkin.external.crash.NativeCrash.forceCrash();
    }
    #end
  }

  override public function destroy():Void
  {
    super.destroy();
  }
}
