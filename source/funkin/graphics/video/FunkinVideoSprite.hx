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

    #if FLX_SOUND_SYSTEM
    getCalculatedVolume = function():Float {
      return (FlxG.sound.muted ? 0 : 1) * FlxG.sound.logToLinear(FlxG.sound.volume);
    }
    #end
  }
}
#end
