package funkin.audio;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.data.song.SongData.SongMusicData;
import funkin.data.song.SongRegistry;
import funkin.util.tools.ICloneable;
import funkin.util.flixel.sound.FlxPartialSound;
import funkin.Paths.PathsFunction;
import lime.app.Promise;
import lime.media.AudioSource;
import openfl.events.Event;
import openfl.media.SoundChannel;
import openfl.media.SoundMixer;

/**
 * A FlxSound which adds additional functionality:
 * - Delayed playback via negative song position.
 * - Easy functions for immediate playback and recycling.
 */
@:nullSafety
class FunkinSound extends FlxSound implements ICloneable<FunkinSound>
{
  /**
   * Using `FunkinSound.load` will override a dead instance from here rather than creating a new one, if possible!
   */
  static var pool(default, null):FlxTypedGroup<FunkinSound> = new FlxTypedGroup<FunkinSound>();

  /**
   * All audio currently in the process of loading with `loadPartialSound()`.
   * Use `emptyPartialQueue()` to cancel currently loading partial sounds.
   */
  static var partialQueue:Array<Promise<Null<FunkinSound>>> = [];

  /**
   * Set this to `true` to mute this sound,
   * making it inaudible without overriding the sound's volume.
   */
  public var muted(default, set):Bool = false;

  /**
   * Set this to `true` to mute this sound,
   * making it inaudible without overriding the sound's volume.
   */
  public var paused(get, never):Bool;

  /**
   * Whether this sound is currently playing.
   * Returns `true` even if the current timestamp is negative (i.e. the sound is waiting to play).
   */
  public var isPlaying(get, never):Bool;

  /**
   * Waveform data for this sound.
   * This is lazily loaded, so it will be built the first time it is accessed.
   */
  public var waveformData(get, never):WaveformData;

  var _waveformData:Null<WaveformData> = null;
  var _label:String = 'unknown';

  public function clone():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();

    // Clone the sound by creating one with the same data buffer.
    // Reusing the `Sound` object directly causes issues with playback.
    @:privateAccess
    sound._sound = openfl.media.Sound.fromAudioBuffer(this._sound.__buffer);

    // Call init to ensure the FlxSound is properly initialized.
    sound.init(this.looped, this.autoDestroy, this.onComplete);

    // Oh yeah, the waveform data is the same too!
    @:privateAccess
    sound._waveformData = this._waveformData;

    return sound;
  }

  @:nullSafety(Off)
  override public function destroy():Void
  {
    super.destroy();

    FlxTween.cancelTweensOf(this);
    this._label = 'unknown';
    this._waveformData = null;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  override public function toString():String
  {
    return 'FunkinSound(${this._label})';
  }

  /**
   * Creates a new `FunkinSound` object and loads it as the current music track.
   *
   * @param key The key of the music you want to play. Music should be at `music/<key>/<key>.ogg`.
   * @param params A set of additional optional parameters.
   *   Data should be at `music/<key>/<key>-metadata.json`.
   * @return Whether the music was started. `false` if music was already playing or could not be started
   */
  public static function playMusic(key:String,
    params:FunkinSoundPlayMusicParams):Bool
  {
    if (!(params.overrideExisting ?? false) && (FlxG.sound.music?.exists ?? false) && FlxG.sound.music.playing) return false;

    var pathsFunction = params.pathsFunction ?? MUSIC;
    var suffix = params.suffix ?? '';
    var pathToUse = switch (pathsFunction)
    {
      case MUSIC:
        Paths.music('$key');
      case INST:
        Paths.inst('$key', suffix);
      default:
        Paths.music('$key');
    }

    if (!(params.restartTrack ?? false) && FlxG.sound.music?.playing)
    {
      if (FlxG.sound.music != null && Std.isOfType(FlxG.sound.music, FunkinSound))
      {
        var existingSound:FunkinSound = cast FlxG.sound.music;
        // Stop here if we would play a matching music track.
        if (existingSound._label == pathToUse)
        {
          return false;
        }
      }
    }

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.fadeTween?.cancel();
      FlxG.sound.music.stop();
      FlxG.sound.music.kill();
    }

    if (params?.mapTimeChanges ?? true)
    {
      var songMusicData:Null<SongMusicData> = SongRegistry.instance.parseMusicData(key);
      // Will fall back and return null if the metadata doesn't exist or can't be parsed.
      if (songMusicData != null)
      {
        Conductor.instance.mapTimeChanges(songMusicData.timeChanges);

        if (songMusicData.looped != null && params.loop == null) params.loop = songMusicData.looped;
      }
      else
      {
        FlxG.log.warn('Tried and failed to find music metadata for $key');
      }
    }

    var shouldLoadPartial = params.partialParams?.loadPartial ?? false;

    // even if we arent' trying to partial load a song, we want to error out any songs in progress,
    // so we don't get overlapping music if someone were to load a new song while a partial one is loading!

    emptyPartialQueue();

    if (shouldLoadPartial)
    {
      var music = FunkinSound.loadPartial(
        pathToUse,
        params.partialParams?.start ?? 0.0,
        params.partialParams?.end ?? 1.0,
        params?.startingVolume ?? 1.0,
        params.loop ?? true,
        false,
        false,
        params.onComplete
      );

      if (music != null)
      {
        partialQueue.push(music);

        @:nullSafety(Off)
        music.future.onComplete(function(partialMusic:Null<FunkinSound>)
        {
          FlxG.sound.music = partialMusic;
          FlxG.sound.list.remove(FlxG.sound.music);

          if (FlxG.sound.music != null && params.onLoad != null) params.onLoad();
        });

        return true;
      }
      else
      {
        return false;
      }
    }
    else
    {
      var music = FunkinSound.load(pathToUse, params?.startingVolume ?? 1.0, params.loop ?? true, false, true, params.persist ?? false, params.onComplete);
      if (music != null)
      {
        setMusic(music);

        if (FlxG.sound.music != null && params.onLoad != null) params.onLoad();

        return true;
      }
      else
      {
        return false;
      }
    }
  }

  /**
   * Replaces the Flixel current music object with the given `FunkinSound` object.
   * @param newMusic The new music to be set as the current music.
   */
  public static function setMusic(newMusic:FunkinSound):Void
  {
    FlxG.sound.music = newMusic;

    // Prevent repeat update() and onFocus() calls.
    FlxG.sound.list.remove(FlxG.sound.music);
  }

  /**
   * Creates a new `FunkinSound` object synchronously.
   *
   * @param embeddedSound   The embedded sound resource you want to play.  To stream, use the optional URL parameter instead.
   * @param volume          How loud to play it (0 to 1).
   * @param looped          Whether to loop this sound.
   * @param group           The group to add this sound to.
   * @param autoDestroy     Whether to destroy this sound when it finishes playing.
   *                          Leave this value set to `false` if you want to re-use this `FunkinSound` instance.
   * @param autoPlay        Whether to play the sound immediately or wait for a `play()` call.
   * @param persist         Whether to keep this `FunkinSound` between states, or destroy it.
   * @param onComplete      Called when the sound finished playing.
   * @param onLoad          Called when the sound finished loading.  Called immediately for successfully loaded embedded sounds.
   * @return A `FunkinSound` object, or `null` if the sound could not be loaded.
   */
  public static function load(embeddedSound:FlxSoundAsset,
    volume:Float = 1.0,
    looped:Bool = false,
    autoDestroy:Bool = false,
    autoPlay:Bool = false,
    persist:Bool = false,
    ?onComplete:Void->Void,
    ?onLoad:Void->Void):Null<FunkinSound>
  {
    var sound:FunkinSound = FunkinSound.recycle();

    if (Std.isOfType(embeddedSound, String))
    {
      embeddedSound = funkin.modding.compat.Sound.cleanupSoundPath(embeddedSound);

      var assetPath:funkin.assets.Paths.AssetPath = funkin.assets.Paths.sound(embeddedSound);
      var soundAsset:openfl.media.Sound = funkin.assets.Assets.getSound(assetPath);

      // Load the sound.
      // Sets `exists = true` as a side effect.
      sound.loadEmbedded(soundAsset, looped, autoDestroy, onComplete);
    }
    else
    {
      // If the embeddedSound is a sound, load it directly.
      // TODO: This should probably be a separate function.
      sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
    }

    if (embeddedSound is String)
    {
      embeddedSound = Paths.stripLibrary(embeddedSound);
      sound._label = embeddedSound;
    }
    else
    {
      sound._label = 'unknown';
    }

    if (autoPlay) sound.play();
    sound.volume = volume;
    FlxG.sound.defaultSoundGroup.add(sound);
    sound.persist = persist;

    // Make sure to add the sound to the list.
    // If it's already in, it won't get re-added.
    // If it's not in the list (it gets removed by FunkinSound.playMusic()),
    // it will get re-added (then if this was called by playMusic(), removed again)
    FlxG.sound.list.add(sound);

    // Call onLoad() because the sound already loaded
    if (onLoad != null && sound._sound != null) onLoad();

    return sound;
  }

  /**
   * Will load a section of a sound file, useful for Freeplay where we don't want to load all the bytes of a song
   * @param path The path to the sound file
   * @param start The start time of the sound file
   * @param end The end time of the sound file
   * @param volume Volume to start at
   * @param looped Whether the sound file should loop
   * @param autoDestroy Whether the sound file should be destroyed after it finishes playing
   * @param autoPlay Whether the sound file should play immediately
   * @param onComplete Callback when the sound finishes playing
   * @param onLoad Callback when the sound finishes loading
   * @return A FunkinSound object
   */
  public static function loadPartial(path:String,
    start:Float = 0,
    end:Float = 1,
    volume:Float = 1.0,
    looped:Bool = false,
    autoDestroy:Bool = false,
    autoPlay:Bool = true,
    ?onComplete:Void->Void,
    ?onLoad:Void->Void):Promise<Null<FunkinSound>>
  {
    var promise:lime.app.Promise<Null<FunkinSound>> = new lime.app.Promise<Null<FunkinSound>>();

    // split the path and get only after first :
    // we are bypassing the openfl/lime asset library fuss on web only
    #if web
    path = Paths.stripLibrary(path);
    #end

    var soundRequest = FlxPartialSound.partialLoadFromFile(path, start, end);

    if (soundRequest == null)
    {
      promise.complete(null);
    }
    else
    {
      promise.future.onError(function(e)
      {
        soundRequest.error('Sound loading was errored or cancelled');
      });

      soundRequest.future.onComplete(function(partialSound)
      {
        var snd = FunkinSound.load(partialSound, volume, looped, autoDestroy, autoPlay, false, onComplete, onLoad);
        promise.complete(snd);
      });
    }

    return promise;
  }

  /**
   * Cancel loading of all partial sounds that are currently being processed.
   */
  public static function emptyPartialQueue():Void
  {
    while (partialQueue.length > 0)
    {
      @:nullSafety(Off)
      partialQueue.pop().error('Cancel loading partial sound');
    }
  }

  /**
   * Play a sound effect once, then destroy it.
   * @param key
   * @param volume
   * @return A `FunkinSound` object, or `null` if the sound could not be loaded.
   */
  public static function playOnce(key:String, volume:Float = 1.0, ?onComplete:Void->Void, ?onLoad:Void->Void):Null<FunkinSound>
  {
    var result:Null<FunkinSound> = FunkinSound.load(key, volume, false, true, true, false, onComplete, onLoad);
    return result;
  }

  /**
   * Stop all sounds in the pool and allow them to be recycled.
   */
  public static function stopAllAudio(musicToo:Bool = false, persistToo:Bool = false):Void
  {
    for (sound in pool)
    {
      if (sound == null) continue;
      if (!persistToo && sound.persist) continue;
      if (!musicToo && sound == FlxG.sound.music) continue;
      sound.destroy();
    }
  }

  /**
   * Reuse an existing FunkinSound object from the pool, or create a new one if none are available.
   *
   * @return The recycled/new `FunkinSound` object.
   */
  static function recycle():FunkinSound
  {
    return pool.recycle(() ->
    {
      // Construct a new sound
      var sound:FunkinSound = new FunkinSound();
      pool.add(sound);
      FlxG.sound.list.add(sound);
      return sound;
    });
  }

  function set_muted(value:Bool):Bool
  {
    if (value == muted) return value;
    muted = value;
    updateTransform();
    return value;
  }

  function get_paused():Bool
  {
    return this._paused;
  }

  function get_isPlaying():Bool
  {
    return this.playing;
  }

  function get_waveformData():WaveformData
  {
    if (_waveformData == null)
    {
      _waveformData = WaveformDataParser.interpretFlxSound(this);
      if (_waveformData == null) throw 'Could not interpret waveform data!';
    }
    return _waveformData;
  }
}

/**
 * Additional parameters for `FunkinSound.playMusic()`
 */
typedef FunkinSoundPlayMusicParams =
{
  /**
   * The volume you want the music to start at.
   * @default `1.0`
   */
  var ?startingVolume:Float;

  /**
   * The suffix of the music file to play. Usually for "-erect" tracks when loading an INST file
   * @default ``
   */
  var ?suffix:String;

  /**
   * Whether to override music if a different track is already playing.
   * @default `false`
   */
  var ?overrideExisting:Bool;

  /**
   * Whether to override music if the same track is already playing.
   * @default `false`
   */
  var ?restartTrack:Bool;

  /**
   * Whether the music should loop or play once.
   * @default `true`
   */
  var ?loop:Bool;

  /**
   * Whether to check for `SongMusicData` to update the Conductor with.
   * @default `true`
   */
  var ?mapTimeChanges:Bool;

  /**
   * Which Paths function to use to load a song
   * @default `MUSIC`
   */
  var ?pathsFunction:PathsFunction;

  var ?partialParams:PartialSoundParams;

  /**
   * Whether the sound should be destroyed on state switches
   */
  var ?persist:Bool;

  var ?onComplete:Void->Void;
  var ?onLoad:Void->Void;
}

typedef PartialSoundParams =
{
  var loadPartial:Bool;
  var start:Float;
  var end:Float;
}
