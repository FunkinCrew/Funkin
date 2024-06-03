package funkin.mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;

class Backspace extends FlxSprite
{
  public var backButtonCam:FunkinCamera;

  public function new(?xPos:Float = 0, ?yPos:Float = 0, ?theColor:FlxColor = FlxColor.WHITE)
  {
    super(xPos, yPos);
    backButtonCam = new FunkinCamera('backButton');
    backButtonCam.bgColor.alpha = 0.00001;
    FlxG.cameras.add(backButtonCam, false);

    frames = Paths.getSparrowAtlas("backspace");
    animation.addByPrefix("idle", "backspace to exit white0");
    animation.play("idle");
    color = theColor;
    cameras = [backButtonCam];
  }
}
