package funkin.ui.debug.cameraeditor.data;

#if FEATURE_CAMERA_EDITOR
import flixel.util.FlxSignal;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.importer.ChartManifestData;
import haxe.io.Bytes;

using StringTools;

/**
 *
 * Holds all chart-related data (metadata, chart data per variation, audio bytes,
 * manifest, working file path, dirty flag) in one place, decoupled from the
 * camera-editor UI shell (`CameraEditorState`).
 * (can probably be easily generalized to ChartEditor too)
 *
 * Mutations to file-path / `saved` / `previousWorkingFilePaths` fire signals so
 * the UI shell can react (window title, recent-files menu, autosave timer).
 * The signals are zero-payload — listeners read current values back off the
 * document.
 */
@:nullSafety
class ChartDocument
{
  public var currentVariation:String = Constants.DEFAULT_VARIATION;

  public var currentDifficulty:String = 'hard';

  public var songDatas:Map<String, SongChartData> = new Map<String, SongChartData>();

  public var songMetadatas:Map<String, SongMetadata> = new Map<String, SongMetadata>();

  public var audioInstTrackData:Map<String, Bytes> = new Map();

  public var audioVocalTrackData:Map<String, Bytes> = new Map();

  public var songManifestData(get, set):ChartManifestData;

  var _songManifestData:Null<ChartManifestData> = null;

  function get_songManifestData():ChartManifestData
  {
    if (_songManifestData != null) return _songManifestData;
    var defaultSongId:String = (currentSongMetadata?.songName ?? 'New Song').trim().toLowerKebabCase().sanitize();
    if (defaultSongId == '') defaultSongId = 'new-song';
    _songManifestData = new ChartManifestData(defaultSongId);
    return _songManifestData;
  }

  function set_songManifestData(value:ChartManifestData):ChartManifestData
  {
    return _songManifestData = value;
  }

  public var previousWorkingFilePaths(default, set):Array<Null<String>> = [null];

  function set_previousWorkingFilePaths(value:Array<Null<String>>):Array<Null<String>>
  {
    previousWorkingFilePaths = value;
    recentsChanged.dispatch();
    return value;
  }

  public var currentWorkingFilePath(get, set):Null<String>;

  function get_currentWorkingFilePath():Null<String>
  {
    return previousWorkingFilePaths[0];
  }

  function set_currentWorkingFilePath(value:Null<String>):Null<String>
  {
    if (value == previousWorkingFilePaths[0]) return value;

    if (previousWorkingFilePaths.contains(null))
    {
      previousWorkingFilePaths = previousWorkingFilePaths.filter((x:Null<String>) -> x != null);
    }
    if (previousWorkingFilePaths.contains(value))
    {
      previousWorkingFilePaths.remove(value);
      previousWorkingFilePaths.unshift(value);
    }
    else
    {
      previousWorkingFilePaths.unshift(value);
    }
    while (previousWorkingFilePaths.length > Constants.MAX_PREVIOUS_WORKING_FILES)
    {
      previousWorkingFilePaths.pop();
    }

    workingFileChanged.dispatch();
    return value;
  }

  public var saved(default, set):Bool = true;

  function set_saved(value:Bool):Bool
  {
    if (saved == value) return value;
    saved = value;
    savedChanged.dispatch();
    return value;
  }

  public var currentSongMetadata(get, never):Null<SongMetadata>;

  inline function get_currentSongMetadata():Null<SongMetadata>
    return songMetadatas.get(currentVariation);

  public var currentSongChartData(get, never):Null<SongChartData>;

  inline function get_currentSongChartData():Null<SongChartData>
    return songDatas.get(currentVariation);

  public var currentNotes(get, never):Array<SongNoteData>;

  function get_currentNotes():Array<SongNoteData>
  {
    var chartData:Null<SongChartData> = currentSongChartData;
    if (chartData == null) return [];
    var notes:Null<Array<SongNoteData>> = chartData.notes.get(currentDifficulty);
    if (notes == null) return [];
    return notes;
  }

  public final savedChanged:FlxSignal = new FlxSignal();

  public final workingFileChanged:FlxSignal = new FlxSignal();

  public final recentsChanged:FlxSignal = new FlxSignal();

  public function new() {}
}
#end
