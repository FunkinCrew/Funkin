package funkin.data.song;

import funkin.data.song.SongData;
import funkin.data.song.migrator.SongData_v2_0_0.SongMetadata_v2_0_0;
import funkin.data.song.migrator.SongData_v2_1_0.SongMetadata_v2_1_0;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.play.song.ScriptedSong;
import funkin.play.song.Song;
import funkin.util.assets.DataAssets;
import funkin.util.VersionUtil;

using funkin.data.song.migrator.SongDataMigrator;

@:nullSafety
class SongRegistry extends BaseRegistry<Song, SongMetadata>
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final SONG_METADATA_VERSION:thx.semver.Version = "2.2.4";

  public static final SONG_METADATA_VERSION_RULE:thx.semver.VersionRule = "2.2.x";

  public static final SONG_CHART_DATA_VERSION:thx.semver.Version = "2.0.0";

  public static final SONG_CHART_DATA_VERSION_RULE:thx.semver.VersionRule = "2.0.x";

  public static final SONG_MUSIC_DATA_VERSION:thx.semver.Version = "2.0.0";

  public static final SONG_MUSIC_DATA_VERSION_RULE:thx.semver.VersionRule = "2.0.x";

  public static var DEFAULT_GENERATEDBY(get, never):String;

  static function get_DEFAULT_GENERATEDBY():String
  {
    return '${Constants.TITLE} - ${Constants.VERSION}';
  }

  /**
   * TODO: What if there was a Singleton macro which automatically created the property for us?
   */
  public static var instance(get, never):SongRegistry;

  static var _instance:Null<SongRegistry> = null;

  static function get_instance():SongRegistry
  {
    if (_instance == null) _instance = new SongRegistry();
    return _instance;
  }

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
    log('Parsing ${scriptedEntryClassNames.length} scripted entries...');

    for (entryCls in scriptedEntryClassNames)
    {
      var entry:Song = createScriptedEntry(entryCls);

      if (entry != null)
      {
        log('Successfully created scripted entry (${entryCls} = ${entry.id})');
        entries.set(entry.id, entry);
        scriptedEntryIds.set(entry.id, entryCls);
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
    log('Parsing ${unscriptedEntryIds.length} unscripted entries...');
    for (entryId in unscriptedEntryIds)
    {
      try
      {
        var entry:Null<Song> = createEntry(entryId);
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

  /**
   * Parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryDataRaw(contents:String, ?fileName:String = 'raw'):Null<SongMetadata>
  {
    return parseEntryMetadataRaw(contents);
  }

  public function parseEntryMetadata(id:String, ?variation:String):Null<SongMetadata>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongMetadata>();
    parser.ignoreUnknownVariables = true;

    switch (loadEntryMetadataFile(id, variation))
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
    return cleanMetadata(parser.value, variation);
  }

  public function parseEntryMetadataRaw(contents:String, ?fileName:String = 'raw', ?variation:String):Null<SongMetadata>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongMetadata>();
    parser.ignoreUnknownVariables = true;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return cleanMetadata(parser.value, variation);
  }

  public function parseEntryMetadataWithMigration(id:String, variation:String, version:thx.semver.Version):Null<SongMetadata>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    // If a version rule is not specified, do not check against it.
    if (SONG_METADATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_METADATA_VERSION_RULE))
    {
      return parseEntryMetadata(id, variation);
    }
    else if (VersionUtil.validateVersion(version, "2.1.x"))
    {
      return parseEntryMetadata_v2_1_0(id, variation);
    }
    else if (VersionUtil.validateVersion(version, "2.0.x"))
    {
      return parseEntryMetadata_v2_0_0(id, variation);
    }
    else
    {
      throw '[${registryId}] Metadata entry ${id}:${variation} does not support migration to version ${SONG_METADATA_VERSION_RULE}.';
    }
  }

  public function parseEntryMetadataRawWithMigration(contents:String, ?fileName:String = 'raw', version:thx.semver.Version):Null<SongMetadata>
  {
    // If a version rule is not specified, do not check against it.
    if (SONG_METADATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_METADATA_VERSION_RULE))
    {
      return parseEntryMetadataRaw(contents, fileName);
    }
    else if (VersionUtil.validateVersion(version, "2.1.x"))
    {
      return parseEntryMetadataRaw_v2_1_0(contents, fileName);
    }
    else if (VersionUtil.validateVersion(version, "2.0.x"))
    {
      return parseEntryMetadataRaw_v2_0_0(contents, fileName);
    }
    else
    {
      throw '[${registryId}] Metadata entry "${fileName}" does not support migration to version ${SONG_METADATA_VERSION_RULE}.';
    }
  }

  function parseEntryMetadata_v2_1_0(id:String, ?variation:String):Null<SongMetadata>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongMetadata_v2_1_0>();
    parser.ignoreUnknownVariables = true;

    switch (loadEntryMetadataFile(id, variation))
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
    return cleanMetadata(parser.value.migrate(), variation);
  }

  function parseEntryMetadata_v2_0_0(id:String, ?variation:String):Null<SongMetadata>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongMetadata_v2_0_0>();
    parser.ignoreUnknownVariables = true;

    switch (loadEntryMetadataFile(id, variation))
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
    return cleanMetadata(parser.value.migrate(), variation);
  }

  function parseEntryMetadataRaw_v2_1_0(contents:String, ?fileName:String = 'raw'):Null<SongMetadata>
  {
    var parser = new json2object.JsonParser<SongMetadata_v2_1_0>();
    parser.ignoreUnknownVariables = true;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value.migrate();
  }

  function parseEntryMetadataRaw_v2_0_0(contents:String, ?fileName:String = 'raw'):Null<SongMetadata>
  {
    var parser = new json2object.JsonParser<SongMetadata_v2_0_0>();
    parser.ignoreUnknownVariables = true;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value.migrate();
  }

  public function parseMusicData(id:String, ?variation:String):Null<SongMusicData>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongMusicData>();
    parser.ignoreUnknownVariables = false;

    switch (loadMusicDataFile(id, variation))
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

  public function parseMusicDataRaw(contents:String, ?fileName:String = 'raw'):Null<SongMusicData>
  {
    var parser = new json2object.JsonParser<SongMusicData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  public function parseMusicDataWithMigration(id:String, ?variation:String, version:thx.semver.Version):Null<SongMusicData>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    // If a version rule is not specified, do not check against it.
    if (SONG_MUSIC_DATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_MUSIC_DATA_VERSION_RULE))
    {
      return parseMusicData(id, variation);
    }
    else
    {
      throw '[${registryId}] Chart entry ${id}:${variation} does not support migration to version ${SONG_CHART_DATA_VERSION_RULE}.';
    }
  }

  public function parseMusicDataRawWithMigration(contents:String, ?fileName:String = 'raw', version:thx.semver.Version):Null<SongMusicData>
  {
    // If a version rule is not specified, do not check against it.
    if (SONG_MUSIC_DATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_MUSIC_DATA_VERSION_RULE))
    {
      return parseMusicDataRaw(contents, fileName);
    }
    else
    {
      throw '[${registryId}] Chart entry "$fileName" does not support migration to version ${SONG_CHART_DATA_VERSION_RULE}.';
    }
  }

  public function parseEntryChartData(id:String, ?variation:String):Null<SongChartData>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongChartData>();
    parser.ignoreUnknownVariables = true;

    switch (loadEntryChartFile(id, variation))
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
    return cleanChartData(parser.value, variation);
  }

  public function parseEntryChartDataRaw(contents:String, ?fileName:String = 'raw', ?variation:String):Null<SongChartData>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongChartData>();
    parser.ignoreUnknownVariables = true;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return cleanChartData(parser.value, variation);
  }

  public function parseEntryChartDataWithMigration(id:String, ?variation:String, version:thx.semver.Version):Null<SongChartData>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    // If a version rule is not specified, do not check against it.
    if (SONG_CHART_DATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_CHART_DATA_VERSION_RULE))
    {
      return parseEntryChartData(id, variation);
    }
    else
    {
      throw '[${registryId}] Chart entry ${id}:${variation} does not support migration to version ${SONG_CHART_DATA_VERSION_RULE}.';
    }
  }

  public function parseEntryChartDataRawWithMigration(contents:String, ?fileName:String = 'raw', version:thx.semver.Version):Null<SongChartData>
  {
    // If a version rule is not specified, do not check against it.
    if (SONG_CHART_DATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_CHART_DATA_VERSION_RULE))
    {
      return parseEntryChartDataRaw(contents, fileName);
    }
    else
    {
      throw '[${registryId}] Chart entry "${fileName}" does not support migration to version ${SONG_CHART_DATA_VERSION_RULE}.';
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

  function loadEntryMetadataFile(id:String, ?variation:String):Null<JsonFile>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
    var entryFilePath:String = Paths.json('$dataFilePath/$id/$id-metadata${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}');
    if (!openfl.Assets.exists(entryFilePath))
    {
      trace('  [WARN] Could not locate file $entryFilePath');
      return null;
    }
    var rawJson:Null<String> = openfl.Assets.getText(entryFilePath);
    if (rawJson == null) return null;
    rawJson = rawJson.trim();
    return {fileName: entryFilePath, contents: rawJson};
  }

  function loadMusicDataFile(id:String, ?variation:String):Null<JsonFile>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
    var entryFilePath:String = Paths.file('music/$id/$id-metadata${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.json');
    if (!openfl.Assets.exists(entryFilePath)) return null;
    var rawJson:String = openfl.Assets.getText(entryFilePath);
    if (rawJson == null) return null;
    rawJson = rawJson.trim();
    return {fileName: entryFilePath, contents: rawJson};
  }

  function hasMusicDataFile(id:String, ?variation:String):Bool
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
    var entryFilePath:String = Paths.file('music/$id/$id-metadata${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}.json');
    return openfl.Assets.exists(entryFilePath);
  }

  function loadEntryChartFile(id:String, ?variation:String):Null<JsonFile>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
    var entryFilePath:String = Paths.json('$dataFilePath/$id/$id-chart${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}');
    if (!openfl.Assets.exists(entryFilePath)) return null;
    var rawJson:String = openfl.Assets.getText(entryFilePath);
    if (rawJson == null) return null;
    rawJson = rawJson.trim();
    return {fileName: entryFilePath, contents: rawJson};
  }

  public function fetchEntryMetadataVersion(id:String, ?variation:String):Null<thx.semver.Version>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
    var entryStr:Null<String> = loadEntryMetadataFile(id, variation)?.contents;
    var entryVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(entryStr);
    return entryVersion;
  }

  public function fetchEntryChartVersion(id:String, ?variation:String):Null<thx.semver.Version>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;
    var entryStr:Null<String> = loadEntryChartFile(id, variation)?.contents;
    var entryVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(entryStr);
    return entryVersion;
  }

  function cleanMetadata(metadata:SongMetadata, variation:String):SongMetadata
  {
    metadata.variation = variation;

    return metadata;
  }

  function cleanChartData(chartData:SongChartData, variation:String):SongChartData
  {
    chartData.variation = variation;

    return chartData;
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
