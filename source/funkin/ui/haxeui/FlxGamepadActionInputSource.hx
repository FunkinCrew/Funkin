package funkin.ui.haxeui;

import flixel.FlxBasic;
import flixel.input.gamepad.FlxGamepad;

/**
 * Receives button presses from the Flixel gamepad and emits HaxeUI events.
 */
class FlxGamepadActionInputSource extends FlxBasic
{
  public static var instance(get, null):FlxGamepadActionInputSource;

  static function get_instance():FlxGamepadActionInputSource
  {
    if (instance == null) instance = new FlxGamepadActionInputSource();
    return instance;
  }

  public function new()
  {
    super();
  }

  public function start():Void
  {
    FlxG.plugins.addPlugin(this);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.gamepads.firstActive != null)
    {
      updateGamepad(elapsed, FlxG.gamepads.firstActive);
    }
  }

  function updateGamepad(elapsed:Float, gamepad:FlxGamepad):Void
  {
    if (gamepad.justPressed.BACK)
    {
      //
    }
  }

  public override function destroy():Void
  {
    super.destroy();
    FlxG.plugins.remove(this);
  }
}
