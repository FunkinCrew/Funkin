package funkin.graphics.video;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;

/**
 * Not to be confused with FlxVideo, this is a hxvlc based video class
 * We override it simply to correct/control our volume easier.
 */
class FunkinVideoSprite extends FlxVideoSprite
{
  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);

    autoPause = false;

    set_volume(1);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    set_volume(volume);
  }

  function set_volume(value:Float):Float
  {
    volume = value;
    bitmap.volume = Std.int((FlxG.sound.muted ? 0 : 1) * (FlxG.sound.logToLinear(FlxG.sound.volume) * 100) * volume);
    return volume;
  }
}
#end
