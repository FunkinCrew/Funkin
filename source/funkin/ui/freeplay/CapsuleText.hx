package funkin.ui.freeplay;

import openfl.filters.BitmapFilterQuality;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import funkin.graphics.shaders.GaussianBlurShader;

class CapsuleText extends FlxSpriteGroup
{
  public var blurredText:FlxText;

  var whiteText:FlxText;

  public var text(default, set):String;

  public function new(x:Float, y:Float, songTitle:String, size:Float)
  {
    super(x, y);

    blurredText = initText(songTitle, size);
    blurredText.shader = new GaussianBlurShader(1);
    whiteText = initText(songTitle, size);
    // whiteText.shader = new GaussianBlurShader(0.3);
    text = songTitle;

    blurredText.color = 0xFF00ccff;
    whiteText.color = 0xFFFFFFFF;
    add(blurredText);
    add(whiteText);
  }

  function initText(songTitle, size:Float):FlxText
  {
    var text:FlxText = new FlxText(0, 0, 0, songTitle, Std.int(size));
    text.font = "5by7";
    return text;
  }

  function set_text(value:String):String
  {
    if (value == null) return value;
    if (blurredText == null || whiteText == null)
    {
      trace('WARN: Capsule not initialized properly');
      return text = value;
    }

    blurredText.text = value;
    whiteText.text = value;
    whiteText.textField.filters = [
      new openfl.filters.GlowFilter(0x00ccff, 1, 5, 5, 210, BitmapFilterQuality.MEDIUM),
      // new openfl.filters.BlurFilter(5, 5, BitmapFilterQuality.LOW)
    ];
    return text = value;
  }
}
