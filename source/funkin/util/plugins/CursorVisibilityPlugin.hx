package funkin.util.plugins;

import openfl.events.MouseEvent;
import funkin.input.Cursor;
import flixel.FlxBasic;

/**
 * A plugin which shows the mouse cursor whenever it moves.
 * Using `Cursor.show()` will force the cursor to stay visible.
 */
class CursorVisibilityPlugin extends FlxBasic
{
  public static var showTimer:Float = 0;
  public static var hideTimer:Float = 0;

  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new CursorVisibilityPlugin());

    FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
  }

  public override function update(elapsed:Float):Void
  {
    if (Cursor.visible)
    {
      showTimer = 0;
      hideTimer = 1;
    }
    else
    {
      showTimer = Math.max(0, showTimer - elapsed);

      if (showTimer == 0) hideTimer = Math.max(0, hideTimer - elapsed * 5);
    }

    FlxG.mouse.cursor.alpha = hideTimer;
    FlxG.mouse.visible = hideTimer > 0;

    super.update(elapsed);
  }

  static function onMouseMove(_):Void
  {
    showTimer = 1;
    hideTimer = 1;
  }
}
