package funkin.data.story.level;

import funkin.util.SortUtil;
import funkin.ui.story.Level;
import funkin.data.story.level.LevelData;
import funkin.ui.story.ScriptedLevel;

class LevelRegistry extends BaseRegistry<Level, LevelData>
{
  /**
   * The current version string for the level data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateLevelData()` function.
   */
  public static final LEVEL_DATA_VERSION:thx.semver.Version = "1.0.1";

  public static final LEVEL_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

  public static var instance(get, never):LevelRegistry;
  static var _instance:Null<LevelRegistry> = null;

  static function get_instance():LevelRegistry
  {
    if (_instance == null) _instance = new LevelRegistry();
    return _instance;
  }

  public function new()
  {
    super('LEVEL', 'levels', LEVEL_DATA_VERSION_RULE);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<LevelData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<LevelData>();
    parser.ignoreUnknownVariables = false;

    switch (loadEntryFile(id))
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

  /**
   * Parse and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class.
   * @param contents The JSON as a string.
   * @param fileName An optional file name for error reporting.
   */
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<LevelData>
  {
    var parser = new json2object.JsonParser<LevelData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):Level
  {
    return ScriptedLevel.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedLevel.listScriptClasses();
  }

  /**
   * A list of all the story weeks from the base game, in order.
   * TODO: Should this be hardcoded?
   */
  public function listBaseGameLevelIds():Array<String>
  {
    return [
      "tutorial",
      "week1",
      "week2",
      "week3",
      "week4",
      "week5",
      "week6",
      "week7",
      "weekend1"
    ];
  }

  public function listSortedLevelIds():Array<String>
  {
    var result = listEntryIds();
    result.sort(SortUtil.defaultsThenAlphabetically.bind(listBaseGameLevelIds()));
    return result;
  }

  /**
   * A list of all installed story weeks that are not from the base game.
   */
  public function listModdedLevelIds():Array<String>
  {
    return listEntryIds().filter(function(id:String):Bool {
      return listBaseGameLevelIds().indexOf(id) == -1;
    });
  }
}
