package funkin.data.song;

import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.song.migrator.SongData_v2_0_0.SongMetadata_v2_0_0;
import funkin.data.song.migrator.SongData_v2_1_0.SongMetadata_v2_1_0;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongMusicData;
import funkin.play.song.Song;
import funkin.util.VersionUtil;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedMap;
#end

using funkin.data.song.migrator.SongDataMigrator;

@:nullSafety
class SongRegistry extends BaseRegistry<Song, SongMetadata, SongEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final SONG_METADATA_VERSION:thx.semver.Version = '2.2.8';

  public static final SONG_METADATA_VERSION_RULE:thx.semver.VersionRule = '2.2.x';
  public static final SONG_CHART_DATA_VERSION:thx.semver.Version = '2.0.0';
  public static final SONG_CHART_DATA_VERSION_RULE:thx.semver.VersionRule = '2.0.x';
  public static final SONG_MUSIC_DATA_VERSION:thx.semver.Version = '2.0.0';
  public static final SONG_MUSIC_DATA_VERSION_RULE:thx.semver.VersionRule = '2.0.x';
  public static var DEFAULT_GENERATEDBY(get, never):String;

  #if FEATURE_MULTITHREADING
  public var scriptedSongVariations:SynchronizedMap<String, Song> = SynchronizedMap.newStringMap(); // Use a thread safe map when needed.
  #else
  public var scriptedSongVariations:Map<String, Song> = new Map<String, Song>();
  #end

  static function get_DEFAULT_GENERATEDBY():String
  {
    return '${Constants.TITLE} - ${Constants.VERSION}';
  }

  public function new()
  {
    super({
      registryId: 'SONG',
      dataFilePath: 'gameplay/songs/',
      // nestedEntries: true, // This registry uses custom parsing.
      versionRule: SONG_METADATA_VERSION_RULE
    });
  }

  override function onScriptedEntryLoaded(clsName:String, entry:Song):Void
  {
    if (entry.variation != null)
    {
      scriptedSongVariations.set('${entry.id}:${entry.variation}', entry);
      log('Successfully created scripted entry (${clsName} = ${entry.id}, ${entry.variation})');
    }
    else
    {
      entries.set(entry.id, entry);
      scriptedEntryIds.set(entry.id, clsName);
      log('Successfully created scripted entry (${clsName} = ${entry.id})');
    }
  }

  override function countEntries():Int
  {
    // Account for song variations.
    return entries.size() + scriptedSongVariations.size();
  }

  override function clearEntries():Void
  {
    log('Destroying ${countEntries()} entries in registry...');

    for (entry in entries)
    {
      entry.destroy();
    }

    // Override to clear song variations.
    for (entry in scriptedSongVariations)
    {
      entry.destroy();
    }

    entries.clear();
    scriptedEntryIds.clear();
    scriptedSongVariations.clear();
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

  override public function isScriptedEntry(id:String, ?params:Null<SongEntryParams>)
  {
    var variation:String = params?.variation ?? Constants.DEFAULT_VARIATION;
    if (variation != Constants.DEFAULT_VARIATION)
    {
      return scriptedSongVariations.exists('${id}:${variation}');
    }
    return super.isScriptedEntry(id, params);
  }

  override public function getScriptedEntryClassName(id:String, ?params:Null<SongEntryParams>):Null<String>
  {
    var variation:String = params?.variation ?? Constants.DEFAULT_VARIATION;
    if (variation != Constants.DEFAULT_VARIATION)
    {
      var variationSong:Null<Song> = cast scriptedSongVariations.get('${id}:${variation}');
      @:privateAccess
      if (variationSong != null && variationSong._asc != null)
      {
        @:privateAccess
        var path:String = variationSong._asc.fullyQualifiedName;
        return path;
      }
    }
    return super.getScriptedEntryClassName(id, params);
  }

  /**
   * We override `fetchEntry` to handle song variations!
   */
  override public function fetchEntry(id:String, ?params:SongEntryParams):Null<Song>
  {
    var variation:String = params?.variation ?? Constants.DEFAULT_VARIATION;

    if (scriptedSongVariations.exists('${id}:${variation}'))
    {
      var variationSongScript:Null<Song> = scriptedSongVariations.get('${id}:${variation}');
      if (variationSongScript != null)
      {
        return variationSongScript;
      }
    }

    return super.fetchEntry(id, params);
  }

  public function parseEntryMetadata(id:String, ?variation:String):Null<SongMetadata>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongMetadata>({
      ignoreUnknownVariables: true
    });

    switch (loadEntryMetadataFile(id, variation))
    {
      case {
        fileName: fileName,
        contents: contents
      }:
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

    var parser = new json2object.JsonParser<SongMetadata>({
      ignoreUnknownVariables: true
    });
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
    variation = variation ?? Constants.DEFAULT_VARIATION;

    // If a version rule is not specified, do not check against it.
    if (SONG_METADATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_METADATA_VERSION_RULE))
    {
      return parseEntryMetadata(id, variation);
    }
    else if (VersionUtil.validateVersion(version, '2.1.x'))
    {
      return parseEntryMetadata_v2_1_0(id, variation);
    }
    else if (VersionUtil.validateVersion(version, '2.0.x'))
    {
      return parseEntryMetadata_v2_0_0(id, variation);
    }
    else
    {
      throw '[${registryId}] Metadata entry ${id}:${variation} does not support migration to version ${SONG_METADATA_VERSION_RULE}.';
    }
  }

  public function parseEntryMetadataRawWithMigration(contents:String, ?fileName:String = 'raw', version:thx.semver.Version, ?variation:String):Null<SongMetadata>
  {
    // If a version rule is not specified, do not check against it.
    if (SONG_METADATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_METADATA_VERSION_RULE))
    {
      return parseEntryMetadataRaw(contents, fileName, variation);
    }
    else if (VersionUtil.validateVersion(version, '2.1.x'))
    {
      return parseEntryMetadataRaw_v2_1_0(contents, fileName);
    }
    else if (VersionUtil.validateVersion(version, '2.0.x'))
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

    var parser = new json2object.JsonParser<SongMetadata_v2_1_0>({
      ignoreUnknownVariables: true
    });

    switch (loadEntryMetadataFile(id, variation))
    {
      case {
        fileName: fileName,
        contents: contents
      }:
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

    var parser = new json2object.JsonParser<SongMetadata_v2_0_0>({
      ignoreUnknownVariables: true
    });

    switch (loadEntryMetadataFile(id, variation))
    {
      case {
        fileName: fileName,
        contents: contents
      }:
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
    var parser = new json2object.JsonParser<SongMetadata_v2_1_0>({
      ignoreUnknownVariables: true
    });
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
    var parser = new json2object.JsonParser<SongMetadata_v2_0_0>({
      ignoreUnknownVariables: true
    });
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

    var parser = new json2object.JsonParser<SongMusicData>({
      ignoreUnknownVariables: true
    });

    switch (loadMusicDataFile(id, variation))
    {
      case {
        fileName: fileName,
        contents: contents
      }:
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
    var parser = new json2object.JsonParser<SongMusicData>({
      ignoreUnknownVariables: true
    });
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
      throw '[${registryId}] Chart entry ${id}:${variation} does not support migration to version ${SONG_MUSIC_DATA_VERSION_RULE}.';
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
      throw '[${registryId}] Chart entry "$fileName" does not support migration to version ${SONG_MUSIC_DATA_VERSION_RULE}.';
    }
  }

  public function parseEntryChartData(id:String, ?variation:String):Null<SongChartData>
  {
    variation = variation == null ? Constants.DEFAULT_VARIATION : variation;

    var parser = new json2object.JsonParser<SongChartData>({
      ignoreUnknownVariables: true
    });

    switch (loadEntryChartFile(id, variation))
    {
      case {
        fileName: fileName,
        contents: contents
      }:
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

    var parser = new json2object.JsonParser<SongChartData>({
      ignoreUnknownVariables: true
    });
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

  public function parseEntryChartDataRawWithMigration(contents:String, ?fileName:String = 'raw', version:thx.semver.Version, ?variation:String):Null<SongChartData>
  {
    // If a version rule is not specified, do not check against it.
    if (SONG_CHART_DATA_VERSION_RULE == null || VersionUtil.validateVersion(version, SONG_CHART_DATA_VERSION_RULE))
    {
      return parseEntryChartDataRaw(contents, fileName, variation);
    }
    else
    {
      throw '[${registryId}] Chart entry "${fileName}" does not support migration to version ${SONG_CHART_DATA_VERSION_RULE}.';
    }
  }

  override function fetchEntryIdsFromFiles():Array<String>
  {
    return funkin.modding.compat.RegistryData.listEntryIds(dataFilePath, '-metadata', true);
  }

  function loadEntryMetadataFile(id:String, ?variation:String):Null<JsonFile>
  {
    try
    {
      variation ??= Constants.DEFAULT_VARIATION;
      var suffix = '-metadata${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}';
      return funkin.modding.compat.RegistryData.loadEntryData(id, suffix, dataFilePath, true);
    }
    catch (e)
    {
      log(' WARNING '.bold().bg_yellow() + ' Could not locate song metadata $id-$variation');
      log(' WARNING '.bold().bg_yellow() + '   $e');
      // throw e;
      return null;
    }
  }

  function loadMusicDataFile(id:String, ?variation:String):Null<JsonFile>
  {
    variation ??= Constants.DEFAULT_VARIATION;
    var entryFilePath:String = Paths.musicMetadata('$id', variation == Constants.DEFAULT_VARIATION ? '' : '-$variation');
    if (!openfl.Assets.exists(entryFilePath))
    {
      trace('  WARNING '.bold().bg_yellow() + ' Could not locate file $entryFilePath');
      return null;
    }
    var rawJson:String = openfl.Assets.getText(entryFilePath);
    if (rawJson == null) return null;
    rawJson = rawJson.trim();
    return {
      fileName: entryFilePath,
      contents: rawJson
    };
  }

  function loadEntryChartFile(id:String, ?variation:String):Null<JsonFile>
  {
    try
    {
      variation ??= Constants.DEFAULT_VARIATION;
      var suffix = '-chart${variation == Constants.DEFAULT_VARIATION ? '' : '-$variation'}';
      return funkin.modding.compat.RegistryData.loadEntryData(id, suffix, dataFilePath, true);
    }
    catch (e)
    {
      log(' WARNING '.bold().bg_yellow() + ' Could not locate song chart data $id-$variation');
      log(' WARNING '.bold().bg_yellow() + '   $e');
      // throw e;
      return null;
    }
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
   * A list of all difficulties for a specific character.
   */
  public function listAllDifficulties(characterId:String):Array<String>
  {
    var allDifficulties:Array<String> = Constants.DEFAULT_DIFFICULTY_LIST.copy();
    var character = PlayerRegistry.instance.fetchEntry(characterId);

    if (character == null)
    {
      trace('  WARNING '.bold().bg_yellow() + ' Could not locate character $characterId');
      return allDifficulties;
    }

    allDifficulties = [];
    for (songId in listEntryIds())
    {
      var song = fetchEntry(songId);
      if (song == null) continue;

      for (diff in song.listDifficulties(null, song.getVariationsByCharacter(character)))
      {
        if (!allDifficulties.contains(diff)) allDifficulties.push(diff);
      }
    }

    allDifficulties.sort(funkin.util.SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));

    if (allDifficulties.length == 0)
    {
      trace('  WARNING '.bold().bg_yellow() + ' No difficulties found. Returning default difficulty list.');
      allDifficulties = Constants.DEFAULT_DIFFICULTY_LIST.copy();
    }

    return allDifficulties;
  }
}

typedef SongEntryParams =
{
  /**
   * The variation ID for the song.
   */
  var variation:String;
}
