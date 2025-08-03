package funkin.ui;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import funkin.util.MathUtil;
import flixel.util.FlxColor;

@:nullSafety
class MenuItem extends FlxSpriteGroup
{
  public var targetY:Float = 0;
  public var week:FlxSprite;

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
  var flashTick:Float = 0;
  final flashFramerate:Float = 20;

  public function startFlashing():Void
  {
    isFlashing = true;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    y = MathUtil.smoothLerpPrecision(y, (targetY * 120) + 480, elapsed, 0.451);

    if (isFlashing)
    {
      flashTick += elapsed;
      if (flashTick >= 1 / flashFramerate)
      {
        flashTick %= 1 / flashFramerate;
        week.color = (week.color == FlxColor.WHITE) ? 0xFF33ffff : FlxColor.WHITE;
      }
    }
  }
}

enum abstract WeekType(String) to String
{
  var WEEK;
  var WEEKEND;
}
