package funkin.audio;

#if flash11
import flash.media.Sound;
import flash.utils.ByteArray;
#end
import flixel.sound.FlxSound;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxSoundAsset;
import funkin.util.tools.ICloneable;
import openfl.Assets;
#if (openfl >= "8.0.0")
import openfl.utils.AssetType;
#end

/**
 * A FlxSound which adds additional functionality:
 * - Delayed playback via negative song position.
 */
@:nullSafety
class FunkinSound extends FlxSound implements ICloneable<FunkinSound>
{
  static var cache(default, null):FlxTypedGroup<FunkinSound> = new FlxTypedGroup<FunkinSound>();

  public var paused(get, never):Bool;

  function get_paused():Bool
  {
    return this._paused;
  }

  public var isPlaying(get, never):Bool;

  function get_isPlaying():Bool
  {
    return this.playing || this._shouldPlay;
  }

  /**
   * Are we in a state where the song should play but time is negative?
   */
  var _shouldPlay:Bool = false;

  /**
   * For debug purposes.
   */
  var _label:String = "unknown";

  public function new()
  {
    super();
  }

  public override function update(elapsedSec:Float)
  {
    if (!playing && !_shouldPlay) return;

    if (_time < 0)
    {
      var elapsedMs = elapsedSec * Constants.MS_PER_SEC;
      _time += elapsedMs;
      if (_time >= 0)
      {
        super.play();
        _shouldPlay = false;
      }
    }
    else
    {
      super.update(elapsedSec);
    }
  }

  public function togglePlayback():FunkinSound
  {
    if (playing)
    {
      pause();
    }
    else
    {
      resume();
    }
    return this;
  }

  public override function play(forceRestart:Bool = false, startTime:Float = 0, ?endTime:Float):FunkinSound
  {
    if (!exists) return this;

    if (forceRestart)
    {
      cleanup(false, true);
    }
    else if (playing)
    {
      return this;
    }

    if (startTime < 0)
    {
      this.active = true;
      this._shouldPlay = true;
      this._time = startTime;
      this.endTime = endTime;
      return this;
    }
    else
    {
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
  }

  public override function pause():FunkinSound
  {
    super.pause();
    this._shouldPlay = false;
    return this;
  }

  /**
   * Called when the user clicks to focus on the window.
   */
  override function onFocus():Void
  {
    if (!_alreadyPaused && this._shouldPlay)
    {
      resume();
    }
  }

  /**
   * Called when the user tabs away from the window.
   */
  override function onFocusLost():Void
  {
    _alreadyPaused = _paused;
    pause();
  }

  public override function resume():FunkinSound
  {
    if (this._time < 0)
    {
      this._shouldPlay = true;
    }
    else
    {
      super.resume();
    }
    return this;
  }

  public function clone():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();

    // Clone the sound by creating one with the same data buffer.
    // Reusing the `Sound` object directly causes issues with playback.
    @:privateAccess
    sound._sound = openfl.media.Sound.fromAudioBuffer(this._sound.__buffer);

    // Call init to ensure the FlxSound is properly initialized.
    sound.init(this.looped, this.autoDestroy, this.onComplete);

    return sound;
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

    if (embeddedSound is String)
    {
      sound._label = embeddedSound;
    }

    sound.volume = volume;
    sound.group = FlxG.sound.defaultSoundGroup;
    sound.persist = true;
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
