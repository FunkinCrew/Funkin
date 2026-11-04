package funkin.ui.debug.charting.handlers;

#if FEATURE_CHART_EDITOR
import flixel.system.FlxAssets.FlxSoundAsset;
import funkin.audio.VoicesGroup;
import funkin.audio.FunkinSound;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.ui.debug.charting.components.ChartEditorWaveformSprite;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.util.FileUtil;
import funkin.util.assets.SoundUtil;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.audio.waveform.WaveformSprite;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import haxe.io.Path;

/**
 * Functions for loading audio for the chart editor.
 * Handlers split up the functionality of the Chart Editor into different classes based on focus to limit the amount of code in each class.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorAudioHandler
{
  /**
   * Loads and stores byte data for a vocal track from an absolute file path
   *
   * @param path The absolute path to the audio file.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  public static function loadVocalsFromPath(state:ChartEditorState, path:Path, charId:String, instId:String = '', wipeFirst:Bool = false):Bool
  {
    #if sys
    var fileBytes:Bytes = sys.io.File.getBytes(path.toString());
    return loadVocalsFromBytes(state, fileBytes, charId, instId, wipeFirst);
    #else
    trace(" WARNING '.bold().bg_yellow() + ' This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads and stores byte data for a vocal track
   *
   * @param bytes The audio byte data.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   * @param wipeFirst Whether to wipe the existing vocal data before loading.
   */
  public static function loadVocalsFromBytes(state:ChartEditorState, bytes:Bytes, charId:String, instId:String = '', wipeFirst:Bool = false):Bool
  {
    var trackId:String = '${charId}${instId == '' ? '' : '-${instId}'}';
    if (wipeFirst) wipeVocalData(state);
    state.audioVocalTrackData.set(trackId, bytes);
    state.audioWaveformDataCache.remove(trackId);
    return true;
  }

  /**
   * Loads and stores byte data for an instrumental track from an absolute file path
   *
   * @param path The absolute path to the audio file.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  public static function loadInstFromPath(state:ChartEditorState, path:Path, instId:String = '', wipeFirst:Bool = false):Bool
  {
    #if sys
    var fileBytes:Bytes = sys.io.File.getBytes(path.toString());
    return loadInstFromBytes(state, fileBytes, instId, wipeFirst);
    #else
    trace(" WARNING '.bold().bg_yellow() + ' This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads and stores byte data for a vocal track
   *
   * @param bytes The audio byte data.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   */
  public static function loadInstFromBytes(state:ChartEditorState, bytes:Bytes, instId:String = '', wipeFirst:Bool = false):Bool
  {
    if (instId == '') instId = 'default';
    if (wipeFirst) wipeInstrumentalData(state);
    state.audioInstTrackData.set(instId, bytes);
    state.audioWaveformDataCache.remove(ChartEditorState.INSTRUMENTAL_WAVEFORM_CACHE_PREFIX + instId);
    return true;
  }

  /**
   * Switches to a specific instrumental track, and the corresponding vocal tracks for each character, if they exist.
   *
   * @param state The chart editor state.
   * @param instId The instrumental track to switch to.
   * @return `true` if the switch was successful, `false` otherwise.
   */
  public static function switchToInstrumental(state:ChartEditorState, instId:String = ''):Bool
  {
    var result:Bool = playInstrumental(state, instId);
    if (!result) return false;

    stopExistingVocals(state);

    // We assume that the `currentSongMetadata` is correctly loaded.
    result = playVocals(state, BF, instId);
    result = playVocals(state, DAD, instId);

    state.postLoadVocals();
    state.hardRefreshOffsetsToolbox();
    state.hardRefreshFreeplayToolbox();
    state.loadSubtitles();

    return true;
  }

  /**
   * Tell the Chart Editor to select a specific instrumental track, that is already loaded.
   */
  public static function playInstrumental(state:ChartEditorState, instId:String = ''):Bool
  {
    if (instId == '') instId = Constants.DEFAULT_VARIATION;
    var instTrackData:Null<Bytes> = state.audioInstTrackData.get(instId);
    var instTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(instTrackData);
    if (instTrack == null) return false;

    stopExistingInstrumental(state);
    state.audioInstTrack = instTrack;
    state.postLoadInstrumental();
    // Workaround for a bug where FlxG.sound.music.update() was being called twice.
    FlxG.sound.list.remove(instTrack);
    return true;
  }

  public static function stopExistingInstrumental(state:ChartEditorState):Void
  {
    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.stop();
      state.audioInstTrack.destroy();
      state.audioInstTrack = null;
    }
  }

  /**
   * Tell the Chart Editor to select a specific set of vocal tracks, that is already loaded.
   *
   * @param state The chart editor state.
   * @param charType The character type to play vocals for.
   * @param variation The variation this vocal track will be for.
   *
   * @return `true` if the vocal track(s) were successfully loaded and played, `false` otherwise.
   */
  public static function playVocals(state:ChartEditorState, charType:CharacterType, variation:String = ''):Bool
  {
    var vocalTrackIds:Array<String> = [];
    var oppositeVocalTracksIds:Array<String> = [];

    // We assume that the `currentSongMetadata` is correctly loaded to retrieve info about what vocal tracks to play.
    switch (charType)
    {
      case BF:
        vocalTrackIds = state.currentSongMetadata.playData.characters.playerVocals ?? [];
        oppositeVocalTracksIds = state.currentSongMetadata.playData.characters.opponentVocals ?? [];
      case DAD:
        vocalTrackIds = state.currentSongMetadata.playData.characters.opponentVocals ?? [];
        oppositeVocalTracksIds = state.currentSongMetadata.playData.characters.playerVocals ?? [];
      default:
        // Do nothing.
    }

    var totalVoicesCount = (vocalTrackIds.length + oppositeVocalTracksIds.length);
    var shouldUseLegacyVocals = totalVoicesCount == 0 && state.audioVocalTrackData.exists(''); // Setup for Voices.ogg
    // we set up legacy vocals as the bf side for ease of use
    var setUpLegacyVocals = shouldUseLegacyVocals && charType == BF;

    if (vocalTrackIds.length == 0 && !setUpLegacyVocals)
    {
      // Didn't play vocals because there are no vocal tracks for this character type on this variation.
      // state.warning('Failed to play vocals', 'No vocal tracks found in chart data for character type $charType.');
      return false;
    }

    if (state.audioVocalTrackGroup == null) state.audioVocalTrackGroup = new VoicesGroup();

    var vocalTracks:Array<FunkinSound> = [];
    var firstVocalTrackKey:Null<String> = null;

    if (setUpLegacyVocals)
    {
      var vocalTrackData:Null<Bytes> = state.audioVocalTrackData.get('');
      var vocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalTrackData);

      if (vocalTrack != null)
      {
        vocalTracks.push(vocalTrack);
        firstVocalTrackKey = '';
      }
    }

    for (trackBaseKey in vocalTrackIds)
    {
      var trackKeySuffix:String = (variation.isBlank() || variation == Constants.DEFAULT_VARIATION) ? '' : '-${variation}';
      var trackKey:String = '$trackBaseKey$trackKeySuffix';
      // For example, for voice ID "bf" on variation "pico", the file name would be "Voices-bf-pico.ogg"

      trace('CHART EDITOR: Switching vocals to "$trackKey"');

      var vocalTrackData:Null<Bytes> = state.audioVocalTrackData.get(trackKey);

      if (vocalTrackData == null)
      {
        state.warning('Failed to play vocals', 'Failed to load vocal track "$trackKey" for character type $charType.');
        continue;
      }

      var vocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalTrackData);

      if (vocalTrack == null)
      {
        state.warning('Failed to play vocals', 'Failed to parse vocal track "$trackKey" for character type $charType.');
        continue;
      }

      vocalTracks.push(vocalTrack);
      if (firstVocalTrackKey == null) firstVocalTrackKey = trackKey;
    }

    var firstVocalTrack:Null<FunkinSound> = vocalTracks[0];
    if (firstVocalTrack == null) return false;

    var waveformData:Null<WaveformData> = getCachedWaveformData(state, firstVocalTrackKey ?? '', firstVocalTrack);

    if (totalVoicesCount < 2 && vocalTracks.length != totalVoicesCount)
    {
      state.audioVocalTrackGroup.legacyVoiceSystem = true;
      state.audioVocalTrackGroup.legacyVoiceUsesPlayer = charType == BF;
    }

    switch (charType)
    {
      case BF:
        for (vocalTrack in vocalTracks)
        {
          state.audioVocalTrackGroup.addPlayerVoice(vocalTrack);
        }

        if (waveformData != null)
        {
          addWaveformSprite(state, waveformData, charType, firstVocalTrack);
        }
        else
        {
          trace(' WARNING '.warning() + ' Failed to parse waveform data for vocal track.');
        }

        state.audioVocalTrackGroup.playerVoicesOffset = state.currentVocalOffsetPlayer;
        return true;

      case DAD:
        for (vocalTrack in vocalTracks)
        {
          state.audioVocalTrackGroup.addOpponentVoice(vocalTrack);
        }

        if (waveformData != null)
        {
          addWaveformSprite(state, waveformData, charType, firstVocalTrack);
        }
        else
        {
          trace(' WARNING '.warning() + ' Failed to parse waveform data for vocal track.');
        }

        state.audioVocalTrackGroup.opponentVoicesOffset = state.currentVocalOffsetOpponent;

        return true;

      default:
        // Fallthrough
    }

    return false;
  }

  static function addWaveformSprite(state:ChartEditorState, waveformData:WaveformData, charType:CharacterType, track:FunkinSound):Void
  {
    var waveformSprite:ChartEditorWaveformSprite = new ChartEditorWaveformSprite(state, waveformData, charType);
    @:privateAccess waveformSprite.audioBuffer = track._source?.buffer;
    state.audioWaveforms.add(waveformSprite);
    state.waveformsDirty = true;
    state.queueWaveformFilterUpdate();
  }

  /**
   * Parsing waveform data reads every sample of the track, so keep it per track key until the track's audio is replaced.
   */
  static function getCachedWaveformData(state:ChartEditorState, trackKey:String, track:FunkinSound):Null<WaveformData>
  {
    var cached:Null<WaveformData> = state.audioWaveformDataCache.get(trackKey);
    if (cached != null) return cached;

    // Parse the waveform data for the given track if it hasn't been cached already.
    var waveformData:Null<WaveformData> = WaveformDataParser.interpretFlxSound(track, ChartEditorState.WAVEFORM_SAMPLES_PER_POINT, true);
    if (waveformData == null)
    {
      trace(' WARNING '.warning() + ' Failed to parse waveform data for vocal track.');
      return null;
    }
    state.audioWaveformDataCache.set(trackKey, waveformData);
    return waveformData;
  }

  public static function stopExistingVocals(state:ChartEditorState):Void
  {
    state.audioVocalTrackGroup.clear();
    if (state.audioWaveforms != null)
    {
      for (waveform in state.audioWaveforms.members)
      {
        if (waveform != null) waveform.destroy();
      }
      state.audioWaveforms.clear();
    }
  }

  /**
   * Play a sound effect.
   * Automatically cleans up after itself and recycles previous FlxSound instances if available, for performance.
   * @param path The path to the sound effect. Use `Paths` to build this.
   */
  public static function playSound(_state:ChartEditorState, path:String, volume:Float = 1.0):Void
  {
    var asset:Null<FlxSoundAsset> = FlxG.sound.cache(path);
    if (asset == null)
    {
      trace('WARN: Failed to play sound $path, asset not found.');
      return;
    }
    var snd:Null<FunkinSound> = FunkinSound.load(asset);
    if (snd == null) return;
    snd.autoDestroy = true;
    snd.play(true);
    snd.volume = volume;
  }

  /**
   * Play one of two stretchy sounds.
   * Since some configurations can play this frequently, we limit to one of each of the two alternating sounds at a time.
   * @param state
   * @param volume
   */
  public static function playStretchySound(state:ChartEditorState, volume:Float = 1.0):Void
  {
    if (state.stretchySounds)
    {
      if (state.stretchySound1 == null) state.stretchySound1 = FunkinSound.load(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-1'));
      if (state.stretchySound1 == null) return;

      // Prevent spam playing that could cause issues.
      if (state.stretchySound1?.isPlaying ?? false || state.stretchySound2?.isPlaying ?? false) return;

      state.stretchySounds = !state.stretchySounds;
      state.stretchySound1.play(true);
      state.stretchySound1.volume = volume;
    }
    else
    {
      if (state.stretchySound2 == null) state.stretchySound2 = FunkinSound.load(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-2'));
      if (state.stretchySound2 == null) return;

      // Prevent spam playing that could cause issues.
      if (state.stretchySound1?.isPlaying ?? false || state.stretchySound2?.isPlaying ?? false) return;

      state.stretchySounds = !state.stretchySounds;
      state.stretchySound2.play(true);
      state.stretchySound2.volume = volume;
    }
  }

  public static function wipeInstrumentalData(state:ChartEditorState):Void
  {
    state.audioInstTrackData.clear();
    for (key in [for (k in state.audioWaveformDataCache.keys()) k])
    {
      if (key.startsWith(ChartEditorState.INSTRUMENTAL_WAVEFORM_CACHE_PREFIX)) state.audioWaveformDataCache.remove(key);
    }
    stopExistingInstrumental(state);
  }

  public static function wipeVocalData(state:ChartEditorState):Void
  {
    state.audioVocalTrackData.clear();
    state.audioWaveformDataCache.clear();
    stopExistingVocals(state);
  }
}
#end
