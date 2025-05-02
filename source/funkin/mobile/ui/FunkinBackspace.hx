package funkin.mobile.ui;

import flixel.FlxG;
import flixel.util.FlxColor;

class FunkinBackspace extends FunkinButton
{
  /**
   * Creates a new FunkinBackspace instance.
   *
   * @param xPos The x position of the object.
   * @param yPos The y position of the object.
   * @param theColor Button's optional color.
   * @param onClick An optional callback function that will be triggered when the object is clicked.
   */
  public function new(?xPos:Float = 0, ?yPos:Float = 0, ?theColor:FlxColor = FlxColor.WHITE, ?onClick:Void->Void):Void
  {
    super(xPos, yPos);

    frames = Paths.getSparrowAtlas("backspace");
    animation.addByPrefix("idle", "backspace to exit white0");
    animation.play("idle");
    color = theColor;
    isBackButton = true;

    if (onClick != null) onDown.add(onClick);
  }
}
