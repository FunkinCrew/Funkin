package funkin.audio;

import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.Paths.PathsFunction;
import funkin.assets.Paths;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.data.song.SongData.SongMusicData;
import funkin.data.song.SongRegistry;
import funkin.util.tools.ICloneable;
import funkin.util.flixel.sound.FlxPartialSound;
import lime.app.Future;
import lime.app.Promise;
import openfl.media.Sound;

/**
 * A FlxSound, extended to add new functionality.
 *
 * - Easy functions for immediate playback.
 * - A priority system, to ensure sounds flagged as `important` are guaranteed to play.
 * - Delayed playback via negative song position.
 */
@:nullSafety
class FunkinSound extends FlxSound implements ICloneable<FunkinSound>
{
  /**
   * The maximum possible volume for a sound.
   */
  static final MAX_VOLUME:Float = 1.0;

  /**
   * Dispatched when the volume changes.
   */
  public static var onVolumeChanged(get, never):FlxTypedSignal<Float->Void>;

  static var _onVolumeChanged:Null<FlxTypedSignal<Float->Void>> = null;

  static function get_onVolumeChanged():FlxTypedSignal<Float->Void>
  {
    if (_onVolumeChanged == null)
    {
      _onVolumeChanged = new FlxTypedSignal<Float->Void>();
      FlxG.sound.onVolumeChange.add((volume:Float) ->
      {
        _onVolumeChanged.dispatch(volume);
      });
    }
    return _onVolumeChanged;
  }

  /**
   * All audio currently in the process of loading with `loadPartialSound()`.
   * Use `emptyPartialQueue()` to cancel currently loading partial sounds.
   */
  static var partialQueue:Array<Promise<Null<Sound>>> = [];

  /**
   * Whether this sound is currently playing.
   * Returns `true` even if the current timestamp is negative (i.e. the sound is waiting to play).
   */
  public var isPlaying(get, never):Bool;

  /**
   * Whether this sound is paused.
   */
  public var paused(get, never):Bool;

  /**
   * Set this to `true` to mute this sound,
   * making it inaudible without overriding the sound's volume.
   */
  public var muted(default, set):Bool = false;

  /**
   * Waveform data for this sound.
   * This is lazily loaded, so it will be built the first time it is accessed.
   */
  public var waveformData(get, never):WaveformData;

  var _waveformData:Null<WaveformData> = null;

  /**
   * Identifies this audio for the purposes of debugging.
   */
  var _label:String = 'unknown';

  public function new()
  {
    super();
  }

  /**
   * Creates a new `FunkinSound` object containing the same audio data as this one.
   *
   * @return The new `FunkinSound` object.
   */
  public function clone():FunkinSound
  {
    var sound:FunkinSound = new FunkinSound();
    FlxG.sound.list.add(sound);

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

  public var isStreaming(get, never):Bool;

  function get_isStreaming():Bool
  {
    #if NO_FEATURE_STREAMED_AUDIO
    return false;
    #else
    if (this == null) return false;
    @:privateAccess
    return this?._source?.buffer?.__srcMADecoder != null;
    #end
  }

  @:nullSafety(Off)
  override public function destroy():Void
  {
    var sound:Null<openfl.media.Sound> = this._sound;

    super.destroy();

    funkin.assets.FunkinAssetCache.FunkinAssetCache.instance.releaseSoundIfUnused(sound);

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
   * Construct a `FunkinSound` and ready it for playback.
   * NOTE: Loads the sound synchronously if it isn't cached.
   *
   * @param assetPath The asset path to the audio to play.
   * @param params (optional) Additional options for loading the sound.
   * @return The constructed `FunkinSound` object, or `null` if the sound failed to be loaded.
   */
  public static function loadSound(assetPath:AssetPath, ?params:FunkinSoundParams):Null<FunkinSound>
  {
    var volume:Float = params?.volume ?? MAX_VOLUME;
    var persist:Bool = params?.persist ?? false;
    var looped:Bool = params?.looped ?? false;
    var autoDestroy:Bool = params?.autoDestroy ?? true;
    var stream:Bool = params?.stream ?? false;

    #if NO_FEATURE_STREAMED_AUDIO
    stream = false;
    #end

    if (suppressOneShots && (params?.autoPlay ?? false) && !looped) return null;

    var sound:FunkinSound = new FunkinSound();

    // Load the sound.
    // Sets `exists = true` as a side effect.

    // todo: refine this lmao.
    if (stream)
    {
      sound.loadStreamed(assetPath.toString(), looped, autoDestroy, params?.onComplete);
    }
    else
      sound.loadEmbedded(funkin.assets.Assets.getSound(assetPath), looped, autoDestroy, params?.onComplete);

    sound._label = '${assetPath.toString()}';

    sound.volume = volume;
    sound.persist = persist;

    // Make sure to add the sound to the list.
    // If it's already in, it won't get re-added.
    // If it's not in the list (it gets removed by FunkinSound.playMusic()),
    // it will get re-added (then if this was called by playMusic(), removed again)
    FlxG.sound.list.add(sound);
    FlxG.sound.defaultSoundGroup.add(sound);

    // Call onLoad() because the sound loaded.
    if (params != null && params.onLoad != null && sound._sound != null) params.onLoad(sound);

    // Call this LAST so volume etc. get set properly.
    if (params?.autoPlay ?? false) sound.play();

    return sound;
  }

  /**
   * When set, one shot sounds (auto-played and not looped) started through `loadSound` are skipped.
   * This includes sounds started through `load`, `playOnce`, and `playSoundOnce`.
   */
  public static var suppressOneShots:Bool = false;

  /**
   * Load an audio file and prepare it for playback.
   * DEPRECATED: Use `loadSound(AssetPath)`
   *
   * @param embeddedSound The sound to play.
   * @param volume The starting volume for the sound.
   * @param looped Whether the sound should loop.
   * @param autoDestroy Whether the sound object should be destroyed when playback is finished.
   * @param autoPlay Whether the sound should start playing immediately, or wait until sound.play().
   * @param persist Whether the sound should persist between states.
   * @param onComplete A function to call when the sound is complete.
   * @param onLoad A function to call when the sound is loaded.
   * @return The constructed `FunkinSound` object, or `null` if the sound failed to be loaded.
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
    if (Std.isOfType(embeddedSound, String))
    {
      return FunkinSound.loadSound(Paths.sound(embeddedSound), {
        volume: volume,
        looped: looped,
        autoDestroy: autoDestroy,
        autoPlay: autoPlay,
        persist: persist,
        onComplete: onComplete,
        onLoad: (_) -> if (onLoad != null) onLoad(),
      });
    }
    else
    {
      // Backwards compatibility for `FunkinSound.load(openfl.media.Sound)`
      var sound:FunkinSound = new FunkinSound();
      FlxG.sound.list.add(sound);
      sound.loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);

      return sound;
    }
  }

  /**
   * Play a sound once, destroying it when it's finished.
   * NOTE: Loads the sound synchronously if it isn't cached.
   *
   * @param assetPath The asset path to the audio to play.
   * @param params (optional) Additional options for loading the sound.
   * @return The constructed `FunkinSound` object, or `null` if the sound failed to be loaded.
   */
  public static function playSoundOnce(assetPath:AssetPath, ?params:FunkinSoundParams):Null<FunkinSound>
  {
    // We're basically just calling loadSound() with different default parameters.
    return loadSound(assetPath, {
      // Default to playing once then destroying when we're done.
      autoDestroy: params?.autoDestroy ?? true,
      autoPlay: params?.autoPlay ?? true,
      looped: params?.looped ?? false,
      persist: params?.persist ?? false,

      volume: params?.volume ?? MAX_VOLUME,
      onComplete: params?.onComplete,
      onLoad: params?.onLoad,
    });
  }

  /**
   * Play a sound once, destroying it when it's finished.
   * DEPRECATED: Use `playSoundOnce(AssetPath)`
   *
   * @param assetKey The asset path to the audio to play.
   * @param volume The starting volume.
   * @param onComplete A function to call when the sound is finished playing.
   * @param onLoad A function to call when the sound is finished loading.
   * @return The constructed `FunkinSound` object, or `null` if the sound failed to be loaded.
   */
  public static function playOnce(assetKey:String, volume:Float = 1.0, ?onComplete:Void->Void, ?onLoad:Void->Void):Null<FunkinSound>
  {
    return FunkinSound.playSoundOnce(Paths.sound(assetKey), {
      volume: volume,
      onComplete: onComplete,
      onLoad: (_) -> if (onLoad != null) onLoad(),
    });
  }

  /**
   * Play a music track.
   *
   * @param musicAssetPath A music asset path. Use `Paths.music()` to construct one.
   * @param params (optional) Additional options for loading the sound.
   * @return `true` if the music track was loaded and started playing, `false` otherwise.
   */
  public static function playMusicTrack(musicAssetPath:MusicAssetPathBuilder,
    ?params:FunkinMusicParams):Bool
  {
    var overrideExisting:Bool = params?.overrideExisting ?? true;
    var forceRestart:Bool = params?.forceRestart ?? false;
    var mapTimeChanges:Bool = params?.mapTimeChanges ?? true;

    var isMusicTrackPlaying:Bool = FlxG.sound.music?.playing ?? false;

    if (isMusicTrackPlaying)
    {
      if (FlxG.sound.music != null && Std.isOfType(FlxG.sound.music, FunkinSound))
      {
        var existingSound:FunkinSound = cast FlxG.sound.music;
        var pathToUse:String = '${musicAssetPath.audio().toString()}';

        // If the track is the same and forceRestart is false, cancel playback.
        if (existingSound._label == pathToUse && !forceRestart) return false;
        // If the track is different and overrideExisting is false, cancel playback.
        if (existingSound._label != pathToUse && !overrideExisting) return false;
      }
    }

    if (mapTimeChanges)
    {
      var songMusicData:Null<SongMusicData> = SongRegistry.instance.parseMusicMetadata(musicAssetPath);

      // Will fall back and return null if the metadata doesn't exist or can't be parsed.
      if (songMusicData != null)
      {
        Conductor.instance.mapTimeChanges(songMusicData.timeChanges);

        if (params != null && params.looped == null)
        {
          // Override params.looped only if not specified by the caller.
          if (songMusicData.looped != null) params.looped = songMusicData.looped;
        }
      }
      else
      {
        FlxG.log.warn(
          'Failed to find music metadata for "${musicAssetPath.toString()}". Set `mapTimeChanges: false` to ignore music metadata and play music without BPM syncing.'
        );
      }
    }

    // Play the new music.
    emptyPartialQueue();
    var music:Null<FunkinSound> = loadSound(musicAssetPath.audio(), {
      looped: params?.looped ?? true,
      persist: params?.persist ?? false,

      autoDestroy: params?.autoDestroy ?? false,
      autoPlay: params?.autoPlay ?? true,
      volume: params?.volume ?? MAX_VOLUME,
      onComplete: params?.onComplete,
      onLoad: params?.onLoad,
    });

    if (music != null)
    {
      setMusic(music);

      return true;
    }
    else
    {
      return false;
    }
  }

  /**
   * Load a music track and starts playback.
   * DEPRECATED: Use `playMusicTrack(MusicAssetPathBuilder)`
   *
   * @param assetKey The asset path to the audio to play.
   * @param params A set of parameters for playback.
   * @return Whether the sound successfully played.
   */
  public static function playMusic(assetKey:String, ?params:FunkinMusicCompatParams):Bool
  {
    var usePartial:Bool = params?.partialParams?.loadPartial ?? false;

    // Convert the music path for compatibility.
    var baseMusicPath = assetKey;
    if (params?.pathsFunction == INST) baseMusicPath = Paths.inst(assetKey, params?.suffix ?? '').toString();
    @:privateAccess
    var musicPath:MusicAssetPathBuilder = new MusicAssetPathBuilder(baseMusicPath, false);

    if (usePartial)
    {
      FunkinSound.playPartialMusicTrack(musicPath, {
        forceRestart: params?.restartTrack,
        looped: params?.loop,
        mapTimeChanges: params?.mapTimeChanges,
        onComplete: params?.onComplete,
        onLoad: (_) -> if (params != null && params.onLoad != null) params.onLoad(),
        persist: params?.persist ?? false,
        volume: params?.startingVolume,

        autoPlay: true,

        // overrideExisting is ignored now.

        start: params?.partialParams?.start,
        end: params?.partialParams?.end
      });

      return true;
    }
    else
    {
      return FunkinSound.playMusicTrack(musicPath, {
        forceRestart: params?.restartTrack,
        looped: params?.loop,
        mapTimeChanges: params?.mapTimeChanges,
        onComplete: params?.onComplete,
        onLoad: (_) -> if (params != null && params.onLoad != null) params.onLoad(),
        persist: params?.persist ?? false,
        volume: params?.startingVolume,

        autoPlay: true,

        // overrideExisting is now ignored.
      });
    }
  }

  /**
   * Construct a `FunkinSound` that contains only part of a sound.
   * Useful for optimizing memory when you only want to play a small portion of a large audio file.
   *
   * @param assetPath The asset path of the audio to play.
   * @param params (optional) Additional options for loading the sound.
   * @return A future, which provides the `FunkinSound` once completed, or an error if loading fails.
   */
  public static function loadPartialSound(assetPath:AssetPath,
    ?params:FunkinPartialSoundParams):Future<FunkinSound>
  {
    var volume:Float = params?.volume ?? MAX_VOLUME;
    var persist:Bool = params?.persist ?? false;
    var looped:Bool = params?.looped ?? false;
    var autoDestroy:Bool = params?.autoDestroy ?? true;
    var autoPlay:Bool = params?.autoPlay ?? false;

    var result:Promise<FunkinSound> = new Promise<FunkinSound>();

    var partialSoundRequest:Promise<Sound> = FlxPartialSound.partialLoadFromFile(assetPath.toString(), params?.start, params?.end);

    partialQueue.push(partialSoundRequest);

    partialSoundRequest.future.onComplete((partialSound:Sound) ->
    {
      // Once the partial sound is loaded, create a FunkinSound that contains its sound data.
      var sound:FunkinSound = new FunkinSound();
      FlxG.sound.list.add(sound);

      // Load the sound.
      // Sets `exists = true` as a side effect.
      sound.loadEmbedded(partialSound, looped, autoDestroy, params?.onComplete);

      sound._label = '${assetPath.toString()}';

      sound.volume = volume;
      sound.persist = persist;

      // Make sure to add the sound to the list.
      // If it's already in, it won't get re-added.
      // If it's not in the list (it gets removed by FunkinSound.playMusic()),
      // it will get re-added (then if this was called by playMusic(), removed again)
      FlxG.sound.list.add(sound);
      FlxG.sound.defaultSoundGroup.add(sound);

      // Call onLoad() because the sound loaded.
      if (params != null && params.onLoad != null && sound._sound != null) params.onLoad(sound);

      // Call this LAST so volume etc. get set properly.
      if (autoPlay) sound.play();

      result.complete(sound);
    });

    partialSoundRequest.future.onError((error:Dynamic) ->
    {
      result.error(error);
    });

    return result.future;
  }

  /**
   * Play only part of a music track.
   * Useful for optimizing memory when you only want to play a small portion of a large music track.
   *
   * @param musicAssetPath A music asset path. Use `Paths.music()` to construct one.
   * @param params (optional) Additional options for loading the sound.
   * @return A future that resolves to `true` if the music was successfully loaded, or an error if it failed.
   */
  public static function playPartialMusicTrack(musicAssetPath:MusicAssetPathBuilder,
    ?params:FunkinPartialMusicParams):Future<Bool>
  {
    var forceRestart:Bool = params?.forceRestart ?? false;
    var mapTimeChanges:Bool = params?.mapTimeChanges ?? true;

    var isMusicTrackPlaying:Bool = FlxG.sound.music?.playing ?? false;

    if (isMusicTrackPlaying && !forceRestart)
    {
      if (FlxG.sound.music != null && Std.isOfType(FlxG.sound.music, FunkinSound))
      {
        var existingSound:FunkinSound = cast FlxG.sound.music;
        var pathToUse:String = '${musicAssetPath.audio().toString()}';

        // Stop here if we would restart a matching music track.
        if (existingSound._label == pathToUse) return Future.withValue(false);
      }
    }

    if (mapTimeChanges)
    {
      var songMusicData:Null<SongMusicData> = SongRegistry.instance.parseMusicMetadata(musicAssetPath);

      // Will fall back and return null if the metadata doesn't exist or can't be parsed.
      if (songMusicData != null)
      {
        Conductor.instance.mapTimeChanges(songMusicData.timeChanges);

        if (params != null && params.looped == null)
        {
          // Override params.looped only if not specified by the caller.
          if (songMusicData.looped != null) params.looped = songMusicData.looped;
        }
      }
      else
      {
        FlxG.log.warn(
          'Failed to find music metadata for "${musicAssetPath.toString()}". Set `mapTimeChanges: false` to ignore music metadata and play music without BPM syncing.'
        );
      }
    }

    // Play the new music.
    emptyPartialQueue();

    var promise:Promise<Bool> = new Promise<Bool>();

    var music:Future<FunkinSound> = loadPartialSound(musicAssetPath.audio(), {
      start: params?.start,
      end: params?.end,

      looped: params?.looped ?? true,
      persist: params?.persist ?? false,

      autoDestroy: params?.autoDestroy ?? false,
      autoPlay: params?.autoPlay ?? true,
      volume: params?.volume ?? MAX_VOLUME,
      onComplete: params?.onComplete,

      // Call onLoad after setMusic().
    });

    music.onComplete((music:FunkinSound) ->
    {
      // Called when the music finishes loading.
      setMusic(music);

      if (params != null && params.onLoad != null && music._sound != null) params.onLoad(music);

      promise.complete(true);
    });

    music.onError((err:Dynamic) ->
    {
      // Called when the music fails to load.
      promise.error(err);
    });

    return promise.future;
  }

  /**
   * Replaces the Flixel current music object with the given `FunkinSound` object.
   *
   * @param newMusic The new music to be assigned as the current music.
   * @param autoDestroyOldMusic Whether to destroy the old music as we exit.
   */
  public static function setMusic(newMusic:FunkinSound, autoDestroyOldMusic:Bool = true):Void
  {
    // Stop the current music track if it's already playing.
    if (autoDestroyOldMusic && FlxG.sound.music != null && FlxG.sound.music != newMusic)
    {
      FlxG.sound.music.destroy();
      @:nullSafety(Off)
      FlxG.sound.music = null;
    }

    FlxG.sound.music = newMusic;

    // Prevent repeat update() and onFocus() calls.
    FlxG.sound.list.remove(FlxG.sound.music);
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

  function set_muted(value:Bool):Bool
  {
    if (value == muted) return value;
    muted = value;
    updateVolume();
    return value;
  }

  /**
   * Calculate the volume of the sound, taking into account whether it is muted.
   */
  override function calcTransformVolume():Float
  {
    if (muted) return 0.0;
    return super.calcTransformVolume();
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
 * Parameters for building a FunkinSound.
 */
typedef FunkinSoundParams =
{
  /**
   * The starting volume for the sound.
   * @default `1.0`
   */
  @:optional
  var volume:Float;

  /**
   * Whether this sound should be looped, restarting it when it ends.
   * NOTE: Called `looped` not `loop` for consistency with Flixel. Get it right!
   *
   * @default `false` for `loadSound()`, `true` for `playMusicTrack()`
   */
  @:optional
  var looped:Bool;

  /**
   * Whether to stream this audio on runtime asynchronously.
   *
   * @default `false` for `loadSound()`, `true` for `playMusicTrack()`.
   */
  @:optional
  var stream:Bool;

  /**
   * Whether to automatically destroy the sound when it finishes playing,
   * preventing that instance from being replayed, but saving memory.
   *
   * @default `true` for `loadSound()`, `false` for `playMusicTrack()`
   */
  @:optional
  var autoDestroy:Bool;

  /**
   * Whether to automatically start playing the sound immediately.
   * If `false`, you have to call `play()` later to start it.
   *
   * @default `false` for `loadSound()`, `true` for `playMusicTrack()`
   */
  @:optional
  var autoPlay:Bool;

  /**
   * Whether to keep this sound playing between states.
   * If `false`, the sound will be stopped and destroyed when switching states.
   *
   * @default `false`
   */
  @:optional
  var persist:Bool;

  /**
   * An optional callback to run when the sound finishes loading.
   */
  @:optional
  var onLoad:FunkinSound->Void;

  /**
   * An optional callback to run when the sound finishes playing.
   */
  @:optional
  var onComplete:Void->Void;
};

/**
 * Parameters for building a FunkinSound, for playing music.
 */
typedef FunkinMusicParams =
{
  // Include all the parameters from FunkinSound.
  > FunkinSoundParams,

  /**
   * If `true`, force the music to restart even if the same track is already playing.
   * If `false`, the music will not restart if the same track is already playing.
   *
   * @default `false`
   */
  @:optional
  var forceRestart:Bool;

  /**
   * If `false`, and there is already a different music track playing, `playMusic()` will be ignored.
   * If `true`, the music will always be replaced.
   *
   * @default `true`
   */
  @:optional
  var overrideExisting:Bool;

  /**
   * If `true`, load this music's metadata and load it into the Conductor.
   * Used for tracking BPM changes and syncing `onBeatHit` functions.
   *
   * @default `true`
   */
  @:optional
  var mapTimeChanges:Bool;
};

/**
 * Parameters for building a FunkinSound, that loads only a portion of the sound data.
 */
typedef FunkinPartialSoundParams =
{
  // Include all the parameters from FunkinSound.
  > FunkinSoundParams,

  /**
   * The start time of the audio, in seconds.
   * @default The start of the audio file.
   */
  @:optional
  var start:Float;

  /**
   * The end time of the audio, in seconds.
   * @default The end of the audio file.
   */
  @:optional
  var end:Float;
}

/**
 * Parameters for building a FunkinSound, for playing music that loads only a portion of the sound data.
 */
typedef FunkinPartialMusicParams =
{
  // Include all the parameters from FunkinSound.
  > FunkinPartialSoundParams,

  /**
   * If `true`, force the music to restart even if the same track is already playing.
   * If `false`, the music will not restart if the same track is already playing.
   *
   * @default `false`
   */
  @:optional
  var forceRestart:Bool;

  /**
   * If `true`, load this music's metadata and load it into the Conductor.
   * Used for tracking BPM changes and syncing `onBeatHit` functions.
   *
   * @default `true`
   */
  @:optional
  var mapTimeChanges:Bool;
};

/**
 * Additional parameters for the deprecated `FunkinSound.playMusic()`
 */
typedef FunkinMusicCompatParams =
{
  var ?suffix:String;
  var ?pathsFunction:PathsFunction;
  var ?overrideExisting:Bool;
  var ?startingVolume:Float;
  var ?restartTrack:Bool;
  var ?loop:Bool;
  var ?mapTimeChanges:Bool;
  var ?partialParams:
    {loadPartial:Bool, start:Float, end:Float};
  var ?persist:Bool;
  var ?onComplete:Void->Void;
  var ?onLoad:Void->Void;
}
