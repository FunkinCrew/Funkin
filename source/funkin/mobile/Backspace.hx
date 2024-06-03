package funkin.mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.ui.MusicBeatState;

class Backspace extends FlxSprite
{
  public var backButtonCam:FunkinCamera;

  public function new(?xPos:Float = 0, ?yPos:Float = 0, ?theColor:FlxColor = FlxColor.WHITE):Void
  {
    super(xPos, yPos);

    backButtonCam = new FunkinCamera('backButton');
    backButtonCam.bgColor.alpha = 0;
    FlxG.cameras.add(backButtonCam, false);

    frames = Paths.getSparrowAtlas("backspace");
    animation.addByPrefix("idle", "backspace to exit white0");
    animation.play("idle");
    color = theColor;
    cameras = [backButtonCam];
    zIndex = 100000;
  }
}
