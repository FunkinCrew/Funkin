package funkin.data.song;

import funkin.data.song.SongData;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.play.song.ScriptedSong;
import funkin.play.song.Song;
import funkin.util.assets.DataAssets;
import funkin.util.VersionUtil;

class SongRegistry extends BaseRegistry<Song, SongMetadata>
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final SONG_METADATA_VERSION:thx.semver.Version = "2.0.0";

  public static final SONG_METADATA_VERSION_RULE:thx.semver.VersionRule = "2.0.x";

  public static final SONG_CHART_DATA_VERSION:thx.semver.Version = "2.0.0";

  public static final SONG_CHART_DATA_VERSION_RULE:thx.semver.VersionRule = "2.0.x";

  public static var DEFAULT_GENERATEDBY(get, null):String;

  static function get_DEFAULT_GENERATEDBY():String
  {
    return '${Constants.TITLE} - ${Constants.VERSION}';
  }

  public static final instance:SongRegistry = new SongRegistry();

  public function new()
  {
    super('SONG', 'songs', SONG_METADATA_VERSION_RULE);
  }

  public override function loadEntries():Void
  {
    clearEntries();

    //
    // SCRIPTED ENTRIES
    //
    var scriptedEntryClassNames:Array<String> = getScriptedClassNames();
    log('Registering ${scriptedEntryClassNames.length} scripted entries...');

    for (entryCls in scriptedEntryClassNames)
    {
      var entry:Song = createScriptedEntry(entryCls);

      if (entry != null)
      {
        log('Successfully created scripted entry (${entryCls} = ${entry.id})');
        entries.set(entry.id, entry);
      }
      else
      {
        log('Failed to create scripted entry (${entryCls})');
      }
    }

    //
    // UNSCRIPTED ENTRIES
    //
    var entryIdList:Array<String> = DataAssets.listDataFilesInPath('songs/', '-metadata.json').map(function(songDataPath:String):String {
      return songDataPath.split('/')[0];
    });
    var unscriptedEntryIds:Array<String> = entryIdList.filter(function(entryId:String):Bool {
      return !entries.exists(entryId);
    });
    log('Fetching data for ${unscriptedEntryIds.length} unscripted entries...');
    for (entryId in unscriptedEntryIds)
    {
      try
      {
        var entry:Song = createEntry(entryId);
        if (entry != null)
        {
          trace('  Loaded entry data: ${entry}');
          entries.set(entry.id, entry);
        }
      }
      catch (e:Dynamic)
      {
        // Print the error.
        trace('  Failed to load entry data: ${entryId}');
        trace(e);
        continue;
      }
    }
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<SongMetadata>
  {
    return parseEntryMetadata(id);
  }

  public function parseEntryMetadata(id:String, variation:String = ""):Null<SongMetadata>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.

    var parser = new json2object.JsonParser<SongMetadata>();
    switch (loadEntryMetadataFile(id))
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, id);
      return null;
    }
    return parser.value;
  }

  public function parseEntryMetadataWithMigration(id:String, variation:String = '', version:thx.semver.Version):Null<SongMetadata>
  {
    // If a version rule is not specified, do not check against it.
    if (SONG_METADATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_METADATA_VERSION_RULE))
    {
      return parseEntryMetadata(id);
    }
    else
    {
      throw '[${registryId}] Metadata entry ${id}:${variation == '' ? 'default' : variation} does not support migration to version ${SONG_METADATA_VERSION_RULE}.';
    }
  }

  public function parseMusicData(id:String, variation:String = ""):Null<SongMusicData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.

    var parser = new json2object.JsonParser<SongMusicData>();
    switch (loadMusicDataFile(id))
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, id);
      return null;
    }
    return parser.value;
  }

  public function parseEntryChartData(id:String, variation:String = ''):Null<SongChartData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<SongChartData>();

    switch (loadEntryChartFile(id))
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, id);
      return null;
    }
    return parser.value;
  }

  public function parseEntryChartDataWithMigration(id:String, variation:String = '', version:thx.semver.Version):Null<SongChartData>
  {
    // If a version rule is not specified, do not check against it.
    if (SONG_CHART_DATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_CHART_DATA_VERSION_RULE))
    {
      return parseEntryChartData(id, variation);
    }
    else
    {
      throw '[${registryId}] Chart entry ${id}:${variation == '' ? 'default' : variation} does not support migration to version ${SONG_CHART_DATA_VERSION_RULE}.';
    }
  }

  function createScriptedEntry(clsName:String):Song
  {
    return ScriptedSong.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedSong.listScriptClasses();
  }

  function loadEntryMetadataFile(id:String, variation:String = ''):Null<BaseRegistry.JsonFile>
  {
    var entryFilePath:String = Paths.json('$dataFilePath/$id/$id${variation == '' ? '' : '-$variation'}-metadata');
    if (!openfl.Assets.exists(entryFilePath)) return null;
    var rawJson:Null<String> = openfl.Assets.getText(entryFilePath);
    if (rawJson == null) return null;
    rawJson = rawJson.trim();
    return {fileName: entryFilePath, contents: rawJson};
  }

  function loadMusicDataFile(id:String, variation:String = ''):Null<BaseRegistry.JsonFile>
  {
    var entryFilePath:String = Paths.file('music/$id/$id${variation == '' ? '' : '-$variation'}-metadata.json');
    if (!openfl.Assets.exists(entryFilePath)) return null;
    var rawJson:String = openfl.Assets.getText(entryFilePath);
    if (rawJson == null) return null;
    rawJson = rawJson.trim();
    return {fileName: entryFilePath, contents: rawJson};
  }

  function loadEntryChartFile(id:String, variation:String = ''):Null<BaseRegistry.JsonFile>
  {
    var entryFilePath:String = Paths.json('$dataFilePath/$id/$id${variation == '' ? '' : '-$variation'}-chart');
    if (!openfl.Assets.exists(entryFilePath)) return null;
    var rawJson:String = openfl.Assets.getText(entryFilePath);
    if (rawJson == null) return null;
    rawJson = rawJson.trim();
    return {fileName: entryFilePath, contents: rawJson};
  }

  public function fetchEntryMetadataVersion(id:String, variation:String = ''):Null<thx.semver.Version>
  {
    var entryStr:Null<String> = loadEntryMetadataFile(id, variation)?.contents;
    var entryVersion:thx.semver.Version = VersionUtil.getVersionFromJSON(entryStr);
    return entryVersion;
  }

  public function fetchEntryChartVersion(id:String, variation:String = ''):Null<thx.semver.Version>
  {
    var entryStr:String = loadEntryChartFile(id, variation).contents;
    var entryVersion:thx.semver.Version = VersionUtil.getVersionFromJSON(entryStr);
    return entryVersion;
  }

  /**
   * A list of all the story weeks from the base game, in order.
   * TODO: Should this be hardcoded?
   */
  public function listBaseGameSongIds():Array<String>
  {
    return [
      "tutorial", "bopeebo", "fresh", "dadbattle", "spookeez", "south", "monster", "pico", "philly-nice", "blammed", "satin-panties", "high", "milf", "cocoa",
      "eggnog", "winter-horrorland", "senpai", "roses", "thorns", "ugh", "guns", "stress", "darnell", "lit-up", "2hot", "blazin"
    ];
  }

  /**
   * A list of all installed story weeks that are not from the base game.
   */
  public function listModdedSongIds():Array<String>
  {
    return listEntryIds().filter(function(id:String):Bool {
      return listBaseGameSongIds().indexOf(id) == -1;
    });
  }
}
