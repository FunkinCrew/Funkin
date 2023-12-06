package funkin.audio;

#if flash11
import flash.media.Sound;
import flash.utils.ByteArray;
#end
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import openfl.Assets;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end

/**
 * A FlxSound which adds additional functionality:
 * - Delayed playback via negative song position.
 */
@:nullSafety
class FunkinSound extends FlxSound
{
  static var cache(default, null):FlxTypedGroup<FunkinSound> = new FlxTypedGroup<FunkinSound>();

  /**
   * Are we in a state where the song should play but time is negative?
   */
  var shouldPlay:Bool = false;

  public function new()
  {
    super();
  }

  public override function update(elapsedSec:Float)
  {
    if (!playing && !shouldPlay) return;

    if (_time < 0)
    {
      var elapsedMs = elapsedSec * Constants.MS_PER_SEC;
      _time += elapsedMs;
      if (_time >= 0)
      {
        _time = 0;
        shouldPlay = false;
        super.play();
      }
    }
    else
    {
      super.update(elapsedSec);
    }
  }

  public override function play(forceRestart:Bool = false, startTime:Float = 0, ?endTime:Float):FunkinSound
  {
    if (!exists) return this;

    if (forceRestart)
    {
      cleanup(false, true);
    }
    else if (playing || shouldPlay)
    {
      return this;
    }

    if (startTime < 0)
    {
      shouldPlay = true;
      _time = startTime;
      this.endTime = endTime;
      return this;
    }

    if (_paused)
    {
      resume();
    }
    else
    {
      startSound(startTime);
    }

    this.endTime = endTime;
    return this;
  }

  /**
   * Creates a new `FunkinSound` object.
   *
   * @param   embeddedSound   The embedded sound resource you want to play.  To stream, use the optional URL parameter instead.
   * @param   volume          How loud to play it (0 to 1).
   * @param   looped          Whether to loop this sound.
   * @param   group           The group to add this sound to.
   * @param   autoDestroy     Whether to destroy this sound when it finishes playing.
   *                          Leave this value set to `false` if you want to re-use this `FunkinSound` instance.
   * @param   autoPlay        Whether to play the sound immediately or wait for a `play()` call.
   * @param   onComplete      Called when the sound finished playing.
   * @param   onLoad          Called when the sound finished loading.  Called immediately for succesfully loaded embedded sounds.
   * @return  A `FunkinSound` object.
   */
  public static function load(embeddedSound:FlxSoundAsset, volume:Float = 1.0, looped:Bool = false, autoDestroy:Bool = false, autoPlay:Bool = false,
      ?onComplete:Void->Void, ?onLoad:Void->Void):FunkinSound
  {
    var sound:FunkinSound = cache.recycle(construct);

    sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);

    sound.volume = volume;
    sound.group = FlxG.sound.defaultSoundGroup;
    if (autoPlay) sound.play();

    // Call OnlLoad() because the sound already loaded
    if (onLoad != null && sound._sound != null) onLoad();

    return sound;
  }

  static function construct():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();

    cache.add(sound);
    FlxG.sound.list.add(sound);

    return sound;
  }
}
