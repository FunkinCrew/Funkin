package funkin.audio;

import flash.media.Sound;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import openfl.Assets;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end

/**
 * a FlxSound that just overrides loadEmbedded to allow for "streamed" sounds to load with better performance!
 */
@:nullSafety
class FlxStreamSound extends FlxSound
{
  public function new()
  {
    super();
  }

  override public function loadEmbedded(EmbeddedSound:Null<FlxSoundAsset>, Looped:Bool = false, AutoDestroy:Bool = false, ?OnComplete:Void->Void):FlxSound
  {
    if (EmbeddedSound == null) return this;

    cleanup(true);

    if ((EmbeddedSound is Sound))
    {
      _sound = EmbeddedSound;
    }
    else if ((EmbeddedSound is Class))
    {
      _sound = Type.createInstance(EmbeddedSound, []);
    }
    else if ((EmbeddedSound is String))
    {
      if (Assets.exists(EmbeddedSound, AssetType.SOUND)
        || Assets.exists(EmbeddedSound, AssetType.MUSIC)) _sound = Assets.getMusic(EmbeddedSound);
      else
        FlxG.log.error('Could not find a Sound asset with an ID of \'$EmbeddedSound\'.');
    }

    // NOTE: can't pull ID3 info from embedded sound currently
    return init(Looped, AutoDestroy, OnComplete);
  }
}
