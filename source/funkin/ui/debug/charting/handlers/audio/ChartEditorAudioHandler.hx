package funkin.ui.debug.charting.handlers.audio;

#if FEATURE_CHART_EDITOR
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.util.FlxColor;
import funkin.assets.Paths;
import funkin.audio.VoicesGroup;
import funkin.audio.FunkinSound;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.ui.debug.charting.components.grid.ChartEditorWaveformSprite;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.util.FileUtil;
import funkin.util.assets.SoundUtil;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.audio.waveform.WaveformSprite;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import haxe.io.Path;
import funkin.util.Constants;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorWaveformFilter;
import funkin.ui.debug.charting.ChartEditorState.WaveformFilterResult;
import funkin.ui.debug.charting.ChartEditorState.WaveformLoadResult;
import funkin.ui.debug.charting.handlers.editor.ChartEditorThemeHandler;

/**
 * Functions for loading audio for the chart editor.
 * Handlers split up the functionality of the Chart Editor into different classes based on focus to limit the amount of code in each class.
 */
@:nullSafety
@:access(funkin.audio.VoicesGroup)
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorAudioHandler
{
  /**
   * Whether to stream audio tracks instead of loading them fully into memory.
   */
  static final STREAM_TRACKS:Bool = #if FEATURE_STREAMED_AUDIO true #else false #end;

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
    var instTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(instTrackData, STREAM_TRACKS);
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
    var trackKeySuffix:String = (variation.isBlank() || variation == Constants.DEFAULT_VARIATION) ? '' : '-${variation}';

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

    var totalVoiceTracks = vocalTrackIds.concat(oppositeVocalTracksIds);
    var validVoiceTracks = totalVoiceTracks.filter((trackBaseKey:String) ->
    {
      var trackKey:String = '$trackBaseKey$trackKeySuffix';
      var vocalTrackData:Null<Bytes> = state.audioVocalTrackData.get(trackKey);
      if (vocalTrackData == null) return false;
      var vocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalTrackData, STREAM_TRACKS);
      if (vocalTrack == null) return false;
      vocalTrack.destroy();
      vocalTrack = null;
      return true;
    }).length;
    var totalVoicesCount = totalVoiceTracks.length;
    var shouldUseLegacyVocals = validVoiceTracks == 0 && state.audioVocalTrackData.exists(''); // Setup for Voices.ogg
    // we set up legacy vocals as the bf side for ease of use
    var setUpLegacyVocals = shouldUseLegacyVocals && charType == BF;

    if (validVoiceTracks == 0 && !setUpLegacyVocals)
    {
      // Didn't play vocals because there are no vocal tracks for this character type on this variation.
      // state.warning('Failed to play vocals', 'No vocal tracks found in chart data for character type $charType.');
      return false;
    }

    if (state.audioVocalTrackGroup == null) state.audioVocalTrackGroup = new VoicesGroup();

    var vocalTracks:Array<FunkinSound> = [];
    var firstVocalTrackKey:Null<String> = null;
    var firstVocalTrackBytes:Null<Bytes> = null;

    if (setUpLegacyVocals)
    {
      var vocalTrackData:Null<Bytes> = state.audioVocalTrackData.get('');
      var vocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalTrackData, STREAM_TRACKS);

      if (vocalTrack != null)
      {
        vocalTracks.push(vocalTrack);
        firstVocalTrackKey = '';
        firstVocalTrackBytes = vocalTrackData;
      }
    }
    else
    {
      for (trackBaseKey in vocalTrackIds)
      {
        var trackKey:String = '$trackBaseKey$trackKeySuffix';
        // For example, for voice ID "bf" on variation "pico", the file name would be "Voices-bf-pico.ogg"

        trace('CHART EDITOR: Switching vocals to "$trackKey"');

        var vocalTrackData:Null<Bytes> = state.audioVocalTrackData.get(trackKey);

        if (vocalTrackData == null)
        {
          state.warning('Failed to play vocals', 'Failed to load vocal track "$trackKey" for character type $charType.');
          continue;
        }

        var vocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalTrackData, STREAM_TRACKS);

        if (vocalTrack == null)
        {
          state.warning('Failed to play vocals', 'Failed to parse vocal track "$trackKey" for character type $charType.');
          continue;
        }

        vocalTracks.push(vocalTrack);
        if (firstVocalTrackKey == null)
        {
          firstVocalTrackKey = trackKey;
          firstVocalTrackBytes = vocalTrackData;
        }
      }
    }

    var firstVocalTrack:Null<FunkinSound> = vocalTracks[0];
    if (firstVocalTrack == null) return false;

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

        if (firstVocalTrackBytes != null) addWaveformSprite(state, firstVocalTrackKey ?? '', firstVocalTrackBytes, charType);

        state.audioVocalTrackGroup.playerVoicesOffset = state.currentVocalOffsetPlayer;
        return true;

      case DAD:
        for (vocalTrack in vocalTracks)
        {
          state.audioVocalTrackGroup.addOpponentVoice(vocalTrack);
        }

        if (firstVocalTrackBytes != null) addWaveformSprite(state, firstVocalTrackKey ?? '', firstVocalTrackBytes, charType);

        state.audioVocalTrackGroup.opponentVoicesOffset = state.currentVocalOffsetOpponent;

        return true;

      default:
        // Fallthrough
    }

    return false;
  }

  static function addWaveformSprite(state:ChartEditorState, cacheKey:String, bytes:Bytes, charType:CharacterType):ChartEditorWaveformSprite
  {
    var waveformSprite:ChartEditorWaveformSprite = new ChartEditorWaveformSprite(state, requestWaveformData(state, cacheKey, bytes), charType);
    waveformSprite.audioBytes = bytes;
    state.audioWaveforms.add(waveformSprite);
    state.waveformsDirty = true;
    state.queueWaveformFilterUpdate();
    return waveformSprite;
  }

  /**
   * Builds or retrieves cached waveform data for a track, and returns it.
   *
   * @return The cached waveform data, or `null` if it is still being built.
   */
  static function requestWaveformData(state:ChartEditorState, cacheKey:String, bytes:Bytes):Null<WaveformData>
  {
    var cached:Null<WaveformData> = state.audioWaveformDataCache.get(cacheKey);
    if (cached != null) return cached;

    #if target.threaded
    if (state.waveformLoadsPending.contains(bytes)) return null;
    state.waveformLoadsPending.push(bytes);

    var results = state.waveformLoadResults;
    sys.thread.Thread.create(() ->
    {
      var data:Null<WaveformData> = WaveformDataParser.interpretBytes(bytes, ChartEditorState.WAVEFORM_SAMPLES_PER_POINT, true);
      data?.mipLevelCount();
      results.add({
        cacheKey: cacheKey,
        bytes: bytes,
        data: data
      });
    });
    return null;
    #else
    var data:Null<WaveformData> = WaveformDataParser.interpretBytes(bytes, ChartEditorState.WAVEFORM_SAMPLES_PER_POINT, true);
    if (data == null)
    {
      trace(' WARNING '.warning() + ' Failed to parse waveform data for track "$cacheKey".');
      return null;
    }
    state.audioWaveformDataCache.set(cacheKey, data);
    return data;
    #end
  }

  /**
   * The bytes currently loaded for the track with the given `audioWaveformDataCache` key.
   */
  static function getTrackBytes(state:ChartEditorState, cacheKey:String):Null<Bytes>
  {
    if (cacheKey.startsWith(ChartEditorState.INSTRUMENTAL_WAVEFORM_CACHE_PREFIX))
    {
      return state.audioInstTrackData.get(cacheKey.substr(ChartEditorState.INSTRUMENTAL_WAVEFORM_CACHE_PREFIX.length));
    }
    return state.audioVocalTrackData.get(cacheKey);
  }

  public static function stopExistingVocals(state:ChartEditorState):Void
  {
    var oldVoices:Array<FunkinSound> = state.audioVocalTrackGroup.members.copy();
    state.audioVocalTrackGroup.clear();
    for (voice in oldVoices)
    {
      if (voice == null) continue;
      FlxG.sound.list.remove(voice, true);
      voice.destroy();
    }
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
    var snd:Null<FunkinSound> = new FunkinSound();
    snd.loadAudio(path);
    if (snd == null) return;
    snd.autoDestroy = true;
    FlxG.sound.list.add(snd);
    FlxG.sound.defaultSoundGroup.add(snd);
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
      if (state.stretchySound1 == null) state.stretchySound1 = FunkinSound.loadSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-1'));
      if (state.stretchySound1 == null) return;

      // Prevent spam playing that could cause issues.
      if (state.stretchySound1?.isPlaying ?? false || state.stretchySound2?.isPlaying ?? false) return;

      state.stretchySounds = !state.stretchySounds;
      state.stretchySound1.play(true);
      state.stretchySound1.volume = volume;
    }
    else
    {
      if (state.stretchySound2 == null) state.stretchySound2 = FunkinSound.loadSound(Paths.sound('ui/editors/chart-editor/charting-sounds/stretch-2'));
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
    for (key in[for (k in state.audioWaveformDataCache.keys()) k])
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

  @:nullSafety(Off)
  public static function handleWaveformFilter(state:ChartEditorState, elapsed:Float):Void
  {
    #if target.threaded
    var loadResult:Null<WaveformLoadResult> = state.waveformLoadResults.pop(false);
    while (loadResult != null)
    {
      state.waveformLoadsPending.remove(loadResult.bytes);
      if (loadResult.data == null)
      {
        trace(' WARNING '.warning() + ' Failed to parse waveform data for track "${loadResult.cacheKey}".');
      }
      else
      {
        // Only cache it if the track wasn't replaced while it was being built.
        if (getTrackBytes(state, loadResult.cacheKey) == loadResult.bytes) state.audioWaveformDataCache.set(loadResult.cacheKey, loadResult.data);
        for (waveform in state.audioWaveforms.members)
        {
          if (waveform != null && waveform.exists && waveform.audioBytes == loadResult.bytes) waveform.waveformData = loadResult.data;
        }
        state.waveformsDirty = true;
      }
      loadResult = state.waveformLoadResults.pop(false);
    }

    var result:Null<WaveformFilterResult> = state.waveformFilterResults.pop(false);
    while (result != null)
    {
      if (result.generation == state.waveformFilterGeneration && result.waveform.exists)
      {
        result.waveform.overlayData = result.data;
        state.waveformsDirty = true;
      }
      result = state.waveformFilterResults.pop(false);
    }
    #end

    if (state.waveformFilterDelay < 0) return;
    state.waveformFilterDelay -= elapsed;
    if (state.waveformFilterDelay > 0) return;
    state.waveformFilterDelay = -1;

    state.waveformFilterGeneration++;
    var generation:Int = state.waveformFilterGeneration;

    for (waveform in state.audioWaveforms.members)
    {
      // Hidden waveforms get their overlay when shown again, since switching waveforms queues another update.
      if (waveform == null || !waveform.visible) continue;
      var bytes:Null<Bytes> = waveform.audioBytes;
      if (state.waveformFilter == ChartEditorWaveformFilter.None || bytes == null)
      {
        waveform.overlayData = null;
        state.waveformsDirty = true;
        continue;
      }

      var highPass:Bool = state.waveformFilter == ChartEditorWaveformFilter.HighPass;

      var cutoffHz:Float = highPass ? 20 * Math.pow(250, state.waveformFilterStrength) : 20000 * Math.pow(0.005, state.waveformFilterStrength);

      #if target.threaded
      var results = state.waveformFilterResults;
      sys.thread.Thread.create(() ->
      {
        var data = funkin.audio.waveform.WaveformDataParser.interpretBytesFiltered(bytes, ChartEditorState.WAVEFORM_SAMPLES_PER_POINT, highPass, cutoffHz);
        data?.mipLevelCount();
        results.add({
          generation: generation,
          waveform: waveform,
          data: data
        });
      });
      #else
      waveform.overlayData = funkin.audio.waveform.WaveformDataParser.interpretBytesFiltered(
        bytes,
        ChartEditorState.WAVEFORM_SAMPLES_PER_POINT,
        highPass,
        cutoffHz
      );
      state.waveformsDirty = true;
      #end
    }
  }

  /**
   * Update the instrumental waveform sprite to match the current setting and instrumental.
   */
  @:nullSafety(Off)
  public static function updateInstrumentalWaveform(state:ChartEditorState):Void
  {
    var needed:Bool = state.usingInstrumentalWaveform && state.audioInstTrack != null;

    var current:Null<ChartEditorWaveformSprite> = state.instrumentalWaveform;
    if (current != null && (!needed || !current.exists || state.instrumentalWaveformTrack != state.audioInstTrack))
    {
      if (current.exists)
      {
        state.audioWaveforms.remove(current, true);
        current.destroy();
      }
      state.instrumentalWaveform = null;
      state.instrumentalWaveformTrack = null;
      state.waveformsDirty = true;
    }

    var track:Null<FunkinSound> = state.audioInstTrack;
    if (!needed || state.instrumentalWaveform != null || track == null) return;

    var instId:String = (state.currentInstrumentalId == '') ? Constants.DEFAULT_VARIATION : state.currentInstrumentalId;
    var bytes:Null<Bytes> = state.audioInstTrackData.get(instId);
    if (bytes == null) return;

    // Super secret GF key
    var waveform:ChartEditorWaveformSprite = addWaveformSprite(state, ChartEditorState.INSTRUMENTAL_WAVEFORM_CACHE_PREFIX + instId, bytes, GF);
    state.instrumentalWaveform = waveform;
    state.instrumentalWaveformTrack = track;
  }

  /**
   * Handle waveforms aligning based on the health icons position.
   */
  @:nullSafety(Off)
  public static function handleWaveforms(state:ChartEditorState)
  {
    state.updateInstrumentalWaveform();
    if (!state.waveformsDirty) return;

    for (waveform in state.audioWaveforms.members)
    {
      if (waveform == null) continue;

      waveform.overlayColor = ChartEditorThemeHandler.getWaveformFilterColor(state.currentTheme);

      if (waveform.iconId == GF)
      {
        waveform.visible = true;
        waveform.waveformWidth = ChartEditorState.GRID_SIZE * ChartEditorState.STRUMLINE_SIZE;
        waveform.baseColor = ChartEditorThemeHandler.getWaveformOverlayColor(state.currentTheme);
        waveform.coreColor = ChartEditorThemeHandler.getWaveformCoreColor(state.currentTheme);
        waveform.alpha = ChartEditorThemeHandler.WAVEFORM_OVERLAY_ALPHA;
        waveform.audioOffsetMs = 0;
        waveform.x = state.gridTiledSprite.x + ChartEditorState.GRID_SIZE * ChartEditorState.STRUMLINE_SIZE / 2;
        waveform.markDirty();
        waveform.refresh();
        continue;
      }

      waveform.visible = !state.usingInstrumentalWaveform;
      waveform.waveformWidth = (state.currentWaveformPos == Overlay) ? (ChartEditorState.GRID_SIZE * 4) : (ChartEditorState.GRID_SIZE * 2);
      // Colors are drawn into the bitmap, so the base and the filtered overlay can differ.
      waveform.baseColor = (state.currentWaveformPos == Overlay) ? ChartEditorThemeHandler.getWaveformOverlayColor(state.currentTheme) : FlxColor.WHITE;
      waveform.coreColor = (state.currentWaveformPos == Overlay) ? ChartEditorThemeHandler.getWaveformCoreColor(state.currentTheme) : null;
      waveform.alpha = (state.currentWaveformPos == Overlay) ? ChartEditorThemeHandler.WAVEFORM_OVERLAY_ALPHA : 1.0;

      waveform.audioOffsetMs = (waveform.iconId == DAD) ? state.currentVocalOffsetOpponent : state.currentVocalOffsetPlayer;
      waveform.markDirty();

      switch (waveform.iconId)
      {
        case BF:
          if (state.currentWaveformPos == Overlay)
          {
            waveform.x = state.gridTiledSprite.x + (ChartEditorState.GRID_SIZE * 4);
          }
          else if (state.healthIconBF != null)
          {
            waveform.x = state.healthIconBF.x;
          }
          else
          {
            waveform.x = 840 + FullScreenScaleMode.gameCutoutSize.x * 0.5;
          }
        case DAD:
          if (state.currentWaveformPos == Overlay)
          {
            waveform.x = state.gridTiledSprite.x;
          }
          else if (state.healthIconDad != null)
          {
            waveform.x = state.healthIconDad.x;
          }
          else
          {
            waveform.x = 360 + FullScreenScaleMode.gameCutoutSize.x * 0.5;
          }
        default:
          waveform.x = 0;
      }

      waveform.refresh();
    }

    state.waveformsDirty = false;
  }

  @:nullSafety(Off)
  public static function switchToCurrentInstrumental(state:ChartEditorState):Void
  {
    // ChartEditorAudioHandler
    state.switchToInstrumental(state.currentInstrumentalId);
  }

  @:nullSafety(Off)
  public static function postLoadInstrumental(state:ChartEditorState):Void
  {
    // Reapply the volume and playback rate.
    var instTargetVolume:Float = ((state.preferencesVolumeInstrumental.value / 100) ?? 1.0);
    var playbackRate:Float = ((state.menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
    playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%
    if (state.audioInstTrack != null)
    {
      // Prevent the time from skipping back to 0 when the song ends.
      state.audioInstTrack.onComplete = function()
      {
        if (state.audioInstTrack != null)
        {
          state.audioInstTrack.pause();
          // Keep the track at the end.
          state.audioInstTrack.time = state.audioInstTrack.length;
        }
        state.audioVocalTrackGroup.pause();
      };
      state.audioInstTrack.volume = instTargetVolume;
      state.audioInstTrack.pitch = playbackRate;
      state.audioInstTrack.muted = state.instrumentalMuted;
    }
    else
    {
      trace('ERROR: Instrumental track is null!');
    }
    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);
    state.removeSubBeatsOnSnap();
    state.pruneSubBeatSnaps();
    state.updateTimeSignature();
    @:privateAccess state.measureTicks?.updateMeasureNumbers(true);

    state.songLengthInMs = (state.audioInstTrack?.length ?? 1000.0) + Conductor.instance.instrumentalOffset;
    Conductor.instance.update(0, false);

    // Many things get reset when song length changes.
    state.healthIconsDirty = true;
    state.playerPreviewDirty = true;
    state.opponentPreviewDirty = true;
  }

  @:nullSafety(Off)
  public static function loadSubtitles(state:ChartEditorState):Void
  {
    var subtitlesFile:String = 'gameplay/songs/${state.currentSongId}/subtitles/song-lyrics';
    if (state.selectedVariation != Constants.DEFAULT_VARIATION)
    {
      subtitlesFile += '-${state.selectedVariation}';
    }
    state.subtitles.assignSubtitles(subtitlesFile, state.audioInstTrack);
  }

  @:nullSafety(Off)
  public static function postLoadVocals(state:ChartEditorState):Void
  {
    // Reapply the volume and playback rate.
    var vocalPlayerTargetVolume:Float = (state.preferencesVolumeVocalsPlayer.value / 100.0) ?? 1.0;
    var vocalOpponentTargetVolume:Float = (state.preferencesVolumeVocalsOpponent.value / 100.0) ?? 1.0;
    var playbackRate:Float = ((state.menubarItemPlaybackSpeed.value / 100.0) ?? 0.5) * 2.0;
    playbackRate = playbackRate.clamp(0.05, 2.0); // Clamp to 5% to 200%

    if (state.audioVocalTrackGroup != null)
    {
      state.audioVocalTrackGroup.playerVolume = vocalPlayerTargetVolume;
      state.audioVocalTrackGroup.opponentVolume = vocalOpponentTargetVolume;
      state.audioVocalTrackGroup.pitch = playbackRate;
    }
    // Newly loaded tracks start unmuted.
    state.applyVocalMutes();
  }

  @:nullSafety(Off)
  public static function applyVocalMutes(state:ChartEditorState):Void
  {
    if (state.audioVocalTrackGroup == null) return;
    // A legacy shared Voices file is added as the player's track, so it follows the player toggle.
    state.audioVocalTrackGroup.playerVoices?.forEach(voice -> voice.muted = state.playerVocalsMuted);
    state.audioVocalTrackGroup.opponentVoices?.forEach(voice -> voice.muted = state.opponentVocalsMuted);
  }

  /**
   * Clear the voices group.
   */
  @:nullSafety(Off)
  public static function clearVocals(state:ChartEditorState):Void
  {
    state.audioVocalTrackGroup.clear();
  }
}
#end
