package funkin.play.components;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;

class ScrollSpeedChanger extends FlxSpriteGroup
{
  var bg:FunkinSprite;
  var scrollSpeedLabel:FlxText;
  var scrollSpeedValue:FlxText;

  public function new(x:Float, y:Float, ?initialSpeed:Float)
  {
    super(x, y);

    initialSpeed = initialSpeed ?? Constants.DEFAULT_SCROLLSPEED;

    bg = new FunkinSprite(0, 0);
    bg.makeGraphic(200, 60, FlxColor.BLACK);
    bg.alpha = 0.6;
    add(bg);

    scrollSpeedLabel = new FlxText(10, 10, "Scroll Speed");
    scrollSpeedLabel.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(scrollSpeedLabel);

    scrollSpeedValue = new FlxText(10, 30, Std.string(FlxMath.roundDecimal(initialSpeed, 2)) + "x");
    scrollSpeedValue.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(scrollSpeedValue);

    scrollFactor.set();
  }

  public function updateSpeed(speed:Float):Void
  {
    scrollSpeedValue.text = Std.string(FlxMath.roundDecimal(speed, 2)) + "x";
  }
}

enum abstract ScrollSpeedMode(Int) from Int to Int
{
  var OFF:Int = 0;

  var STATIC:Int = 1;

  var ADAPTIVE:Int = 2;
}
