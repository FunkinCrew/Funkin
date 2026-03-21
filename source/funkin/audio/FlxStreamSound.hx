package funkin.audio;

import lime.media.AudioBuffer;
import openfl.Assets;
import openfl.media.Sound;
import openfl.utils.AssetType;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;

/**
 * USE flixel.sound.FlxSoundData or FlxSound.loadStreamed instead!
 * 
 * a FlxSound that just overrides loadEmbedded to allow for "streamed" sounds to load with better performance!
 */
@:nullSafety
class FlxStreamSound extends FlxSound
{
  public function new()
  {
    super();
  }

  override public function loadEmbedded(asset:FlxSoundAsset, ?looped:Bool, ?loopTime:Float, ?endTime:Float, autoDestroy = false, ?onComplete:Void->Void):FlxStreamSound
  {
    if ((asset is String))
    {
      super.loadStreamed(asset, looped, loopTime, endTime, autoDestroy, onComplete);
    }
    else
    {
      super.loadEmbedded(asset, looped, loopTime, endTime, autoDestroy, onComplete);
    }
    return this;
  }
}
