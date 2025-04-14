package funkin.mobile.ui;

import flixel.FlxG;
import flixel.util.FlxColor;
import funkin.mobile.ui.FunkinButton;

class FunkinBackspace extends FunkinButton
{
  public function new(?xPos:Float = 0, ?yPos:Float = 0, ?theColor:FlxColor = FlxColor.WHITE, ?onClick:Void->Void = null):Void
  {
    super(xPos, yPos);

    frames = Paths.getSparrowAtlas("backspace");
    animation.addByPrefix("idle", "backspace to exit white0");
    animation.play("idle");
    color = theColor;

    if (onClick != null) onDown.add(onClick);
  }
}
