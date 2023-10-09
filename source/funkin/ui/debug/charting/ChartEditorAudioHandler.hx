package funkin.ui.debug.charting;

import openfl.utils.Assets;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import funkin.play.character.BaseCharacter.CharacterType;
import flixel.system.FlxSound;
import haxe.io.Path;

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
   * Loads a vocal track from an absolute file path.
   * @param path The absolute path to the audio file.
   * @param charKey The character to load the vocal track for.
   * @return Success or failure.
   */
  static function loadVocalsFromPath(state:ChartEditorState, path:Path, charKey:String = 'default'):Bool
  {
    #if sys
    var fileBytes:haxe.io.Bytes = sys.io.File.getBytes(path.toString());
    return loadVocalsFromBytes(state, fileBytes, charKey);
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Load a vocal track for a given song and character and add it to the voices group.
   *
   * @param path ID of the asset.
   * @param charKey Character to load the vocal track for.
   * @return Success or failure.
   */
  static function loadVocalsFromAsset(state:ChartEditorState, path:String, charType:CharacterType = OTHER):Bool
  {
    var vocalTrack:FlxSound = FlxG.sound.load(path, 1.0, false);
    if (vocalTrack != null)
    {
      switch (charType)
      {
        case CharacterType.BF:
          if (state.audioVocalTrackGroup != null) state.audioVocalTrackGroup.addPlayerVoice(vocalTrack);
          state.audioVocalTrackData.set(state.currentSongCharacterPlayer, Assets.getBytes(path));
        case CharacterType.DAD:
          if (state.audioVocalTrackGroup != null) state.audioVocalTrackGroup.addOpponentVoice(vocalTrack);
          state.audioVocalTrackData.set(state.currentSongCharacterOpponent, Assets.getBytes(path));
        default:
          if (state.audioVocalTrackGroup != null) state.audioVocalTrackGroup.add(vocalTrack);
          state.audioVocalTrackData.set('default', Assets.getBytes(path));
      }

      return true;
    }
    return false;
  }

  /**
   * Loads a vocal track from audio byte data.
   */
  static function loadVocalsFromBytes(state:ChartEditorState, bytes:haxe.io.Bytes, charKey:String = ''):Bool
  {
    var openflSound:openfl.media.Sound = new openfl.media.Sound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(bytes), bytes.length);
    var vocalTrack:FlxSound = FlxG.sound.load(openflSound, 1.0, false);
    if (state.audioVocalTrackGroup != null) state.audioVocalTrackGroup.add(vocalTrack);
    state.audioVocalTrackData.set(charKey, bytes);
    return true;
  }

  /**
   * Loads an instrumental from an absolute file path, replacing the current instrumental.
   *
   * @param path The absolute path to the audio file.
   *
   * @return Success or failure.
   */
  static function loadInstrumentalFromPath(state:ChartEditorState, path:Path):Bool
  {
    #if sys
    // Validate file extension.
    if (path.ext != null && !ChartEditorState.SUPPORTED_MUSIC_FORMATS.contains(path.ext))
    {
      return false;
    }

    var fileBytes:haxe.io.Bytes = sys.io.File.getBytes(path.toString());
    return loadInstrumentalFromBytes(state, fileBytes, '${path.file}.${path.ext}');
    #else
    trace("[WARN] This platform can't load audio from a file path, you'll need to fetch the bytes some other way.");
    return false;
    #end
  }

  /**
   * Loads an instrumental from audio byte data, replacing the current instrumental.
   * @param bytes The audio byte data.
   * @param fileName The name of the file, if available. Used for notifications.
   * @return Success or failure.
   */
  static function loadInstrumentalFromBytes(state:ChartEditorState, bytes:haxe.io.Bytes, fileName:String = null):Bool
  {
    if (bytes == null)
    {
      return false;
    }

    var openflSound:openfl.media.Sound = new openfl.media.Sound();
    openflSound.loadCompressedDataFromByteArray(openfl.utils.ByteArray.fromBytes(bytes), bytes.length);
    state.audioInstTrack = FlxG.sound.load(openflSound, 1.0, false);
    state.audioInstTrack.autoDestroy = false;
    state.audioInstTrack.pause();

    state.audioInstTrackData = bytes;

    state.postLoadInstrumental();

    return true;
  }

  /**
   * Loads an instrumental from an OpenFL asset, replacing the current instrumental.
   * @param path The path to the asset. Use `Paths` to build this.
   * @return Success or failure.
   */
  static function loadInstrumentalFromAsset(state:ChartEditorState, path:String):Bool
  {
    var instTrack:FlxSound = FlxG.sound.load(path, 1.0, false);
    if (instTrack != null)
    {
      state.audioInstTrack = instTrack;

      state.audioInstTrackData = Assets.getBytes(path);

      state.postLoadInstrumental();
      return true;
    }

    return false;
  }

  /**
   * Play a sound effect.
   * Automatically cleans up after itself and recycles previous FlxSound instances if available, for performance.
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
}
