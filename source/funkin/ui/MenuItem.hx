package funkin.ui;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import funkin.util.MathUtil;
import flixel.util.FlxColor;

class MenuItem extends FlxSpriteGroup
{
  public var targetY:Float = 0;
  public var week:FlxSprite;
  public var flashingInt:Int = 0;

  public function new(x:Float, y:Float, weekNum:Int = 0, weekType:WeekType)
  {
    super(x, y);

    var weekStr:String = switch (weekType)
    {
      case WEEK:
        "week";
      case WEEKEND:
        "weekend";
    }

    week = new FlxSprite().loadGraphic(Paths.image('storymenu/' + weekStr + weekNum));
    add(week);
  }

  var isFlashing:Bool = false;

  public function startFlashing():Void
  {
    isFlashing = true;
  }

  // if it runs at 60fps, fake framerate will be 6
  // if it runs at 144 fps, fake framerate will be like 14, and will update the graphic every 0.016666 * 3 seconds still???
  // so it runs basically every so many seconds, not dependant on framerate??
  // I'm still learning how math works thanks whoever is reading this lol
  var fakeFramerate:Int = Math.round((1 / FlxG.elapsed) / 10);

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    y = MathUtil.coolLerp(y, (targetY * 120) + 480, 0.17);

    if (isFlashing) flashingInt += 1;

    if (flashingInt % fakeFramerate >= Math.floor(fakeFramerate / 2)) week.color = 0xFF33ffff;
    else
      week.color = FlxColor.WHITE;
  }
}

enum abstract WeekType(String) to String
{
  var WEEK;
  var WEEKEND;
}
