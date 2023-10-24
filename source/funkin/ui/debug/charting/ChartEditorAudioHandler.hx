package funkin.ui.debug.charting;

import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import flixel.system.FlxSound;
import funkin.audio.VoicesGroup;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.util.FileUtil;
import haxe.io.Bytes;
import haxe.io.Path;
import openfl.utils.Assets;

/**
 * Functions for loading audio for the chart editor.
 */
@:nullSafety
@:allow(funkin.ui.debug.charting.ChartEditorState)
@:allow(funkin.ui.debug.charting.ChartEditorDialogHandler)
@:allow(funkin.ui.debug.charting.ChartEditorImportExportHandler)
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
  static function loadVocalsFromPath(state:ChartEditorState, path:Path, charId:String, instId:String = ''):Bool
  {
    #if sys
    var fileBytes:Bytes = sys.io.File.getBytes(path.toString());
    return loadVocalsFromBytes(state, fileBytes, charId, instId);
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads and stores byte data for a vocal track from an asset
   *
   * @param path The path to the asset. Use `Paths` to build this.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  static function loadVocalsFromAsset(state:ChartEditorState, path:String, charId:String, instId:String = ''):Bool
  {
    var trackData:Null<Bytes> = Assets.getBytes(path);
    if (trackData != null)
    {
      return loadVocalsFromBytes(state, trackData, charId, instId);
    }
    return false;
  }

  /**
   * Loads and stores byte data for a vocal track
   *
   * @param bytes The audio byte data.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   */
  static function loadVocalsFromBytes(state:ChartEditorState, bytes:Bytes, charId:String, instId:String = ''):Bool
  {
    var trackId:String = '${charId}${instId == '' ? '' : '-${instId}'}';
    state.audioVocalTrackData.set(trackId, bytes);
    return true;
  }

  /**
   * Loads and stores byte data for an instrumental track from an absolute file path
   *
   * @param path The absolute path to the audio file.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  static function loadInstFromPath(state:ChartEditorState, path:Path, instId:String = ''):Bool
  {
    #if sys
    var fileBytes:Bytes = sys.io.File.getBytes(path.toString());
    return loadInstFromBytes(state, fileBytes, instId);
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads and stores byte data for an instrumental track from an asset
   *
   * @param path The path to the asset. Use `Paths` to build this.
   * @param instId The instrumental this vocal track will be for.
   * @return Success or failure.
   */
  static function loadInstFromAsset(state:ChartEditorState, path:String, instId:String = ''):Bool
  {
    var trackData:Null<Bytes> = Assets.getBytes(path);
    if (trackData != null)
    {
      return loadInstFromBytes(state, trackData, instId);
    }
    return false;
  }

  /**
   * Loads and stores byte data for a vocal track
   *
   * @param bytes The audio byte data.
   * @param charId The character this vocal track will be for.
   * @param instId The instrumental this vocal track will be for.
   */
  static function loadInstFromBytes(state:ChartEditorState, bytes:Bytes, instId:String = ''):Bool
  {
    if (instId == '') instId = 'default';
    state.audioInstTrackData.set(instId, bytes);
    return true;
  }

  public static function switchToInstrumental(state:ChartEditorState, instId:String = '', playerId:String, opponentId:String):Bool
  {
    var result:Bool = playInstrumental(state, instId);
    if (!result) return false;

    stopExistingVocals(state);
    result = playVocals(state, BF, playerId, instId);
    if (!result) return false;
    result = playVocals(state, DAD, opponentId, instId);
    if (!result) return false;

    return true;
  }

  /**
   * Tell the Chart Editor to select a specific instrumental track, that is already loaded.
   */
  static function playInstrumental(state:ChartEditorState, instId:String = ''):Bool
  {
    if (instId == '') instId = 'default';
    var instTrackData:Null<Bytes> = state.audioInstTrackData.get(instId);
    var instTrack:Null<FlxSound> = buildFlxSoundFromBytes(instTrackData);
    if (instTrack == null) return false;

    stopExistingInstrumental(state);
    state.audioInstTrack = instTrack;
    state.postLoadInstrumental();
    return true;
  }

  static function stopExistingInstrumental(state:ChartEditorState):Void
  {
    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.stop();
      state.audioInstTrack.destroy();
      state.audioInstTrack = null;
    }
  }

  /**
   * Tell the Chart Editor to select a specific vocal track, that is already loaded.
   */
  static function playVocals(state:ChartEditorState, charType:CharacterType, charId:String, instId:String = ''):Bool
  {
    var trackId:String = '${charId}${instId == '' ? '' : '-${instId}'}';
    var vocalTrackData:Null<Bytes> = state.audioVocalTrackData.get(trackId);
    var vocalTrack:Null<FlxSound> = buildFlxSoundFromBytes(vocalTrackData);

    if (state.audioVocalTrackGroup == null) state.audioVocalTrackGroup = new VoicesGroup();

    if (vocalTrack != null)
    {
      switch (charType)
      {
        case BF:
          state.audioVocalTrackGroup.addPlayerVoice(vocalTrack);
          return true;
        case DAD:
          state.audioVocalTrackGroup.addOpponentVoice(vocalTrack);
          return true;
        case OTHER:
          state.audioVocalTrackGroup.add(vocalTrack);
          return true;
        default:
          // Do nothing.
      }
    }
    return false;
  }

  static function stopExistingVocals(state:ChartEditorState):Void
  {
    if (state.audioVocalTrackGroup != null)
    {
      state.audioVocalTrackGroup.clear();
    }
  }

  /**
   * Play a sound effect.
   * Automatically cleans up after itself and recycles previous FlxSound instances if available, for performance.
   * @param path The path to the sound effect. Use `Paths` to build this.
   */
  public static function playSound(path:String):Void
  {
    var snd:FlxSound = FlxG.sound.list.recycle(FlxSound) ?? new FlxSound();
    var asset:Null<FlxSoundAsset> = FlxG.sound.cache(path);
    if (asset == null)
    {
      trace('WARN: Failed to play sound $path, asset not found.');
      return;
    }
    snd.loadEmbedded(asset);
    snd.autoDestroy = true;
    FlxG.sound.list.add(snd);
    snd.play();
  }

  public static function wipeInstrumentalData(state:ChartEditorState):Void
  {
    state.audioInstTrackData.clear();
    stopExistingInstrumental(state);
  }

  public static function wipeVocalData(state:ChartEditorState):Void
  {
    state.audioVocalTrackData.clear();
    stopExistingVocals(state);
  }

  /**
   * Convert byte data into a playable sound.
   *
   * @param input The byte data.
   * @return The playable sound, or `null` if loading failed.
   */
  public static function buildFlxSoundFromBytes(input:Null<Bytes>):Null<FlxSound>
  {
    if (input == null) return null;

    var openflSound:openfl.media.Sound = new openfl.media.Sound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(input), input.length);
    var output:FlxSound = FlxG.sound.load(openflSound, 1.0, false);
    return output;
  }

  static function makeZIPEntriesFromInstrumentals(state:ChartEditorState):Array<haxe.zip.Entry>
  {
    var zipEntries = [];

    var instTrackIds = state.audioInstTrackData.keys().array();
    for (key in instTrackIds)
    {
      if (key == 'default')
      {
        var data:Null<Bytes> = state.audioInstTrackData.get('default');
        if (data == null)
        {
          trace('[WARN] Failed to access inst track ($key)');
          continue;
        }
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst.ogg', data));
      }
      else
      {
        var data:Null<Bytes> = state.audioInstTrackData.get(key);
        if (data == null)
        {
          trace('[WARN] Failed to access inst track ($key)');
          continue;
        }
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst-${key}.ogg', data));
      }
    }

    return zipEntries;
  }

  static function makeZIPEntriesFromVocals(state:ChartEditorState):Array<haxe.zip.Entry>
  {
    var zipEntries = [];

    var vocalTrackIds = state.audioVocalTrackData.keys().array();
    for (key in state.audioVocalTrackData.keys())
    {
      var data:Null<Bytes> = state.audioVocalTrackData.get(key);
      if (data == null)
      {
        trace('[WARN] Failed to access vocal track ($key)');
        continue;
      }
      zipEntries.push(FileUtil.makeZIPEntryFromBytes('Voices-${key}.ogg', data));
    }

    return zipEntries;
  }
}
