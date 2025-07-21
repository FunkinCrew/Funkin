package funkin.graphics.video;

#if hxvlc
import hxvlc.flixel.FlxVideoSprite;
import funkin.Preferences;

/**
 * Not to be confused with FlxVideo, this is a hxvlc based video class
 * We override it simply to correct/control our volume easier.
 */
@:nullSafety
class FunkinVideoSprite extends FlxVideoSprite
{
  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);
    // null safety fucking SUCKS
    if (bitmap != null)
    {
      bitmap.onOpening.add(function():Void {
        if (bitmap != null) bitmap.audioDelay = Preferences.globalOffset * 1000; // Microseconds
      });
    }
  }
}
#end
