package funkin.data.stage;

import funkin.data.stage.StageData;
import funkin.play.stage.Stage;
import funkin.play.stage.ScriptedStage;

class StageRegistry extends BaseRegistry<Stage, StageData>
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final STAGE_DATA_VERSION:thx.semver.Version = "1.0.2";

  public static final STAGE_DATA_VERSION_RULE:thx.semver.VersionRule = ">=1.0.0 <=1.0.2";

  public static var instance(get, never):StageRegistry;
  static var _instance:Null<StageRegistry> = null;

  static function get_instance():StageRegistry
  {
    if (_instance == null) _instance = new StageRegistry();
    return _instance;
  }

  public function new()
  {
    super('STAGE', 'stages', STAGE_DATA_VERSION_RULE);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<StageData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<StageData>();
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
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<StageData>
  {
    var parser = new json2object.JsonParser<StageData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):Stage
  {
    return ScriptedStage.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedStage.listScriptClasses();
  }

  /**
   * A list of all the stages from the base game, in order.
   * TODO: Should this be hardcoded?
   */
  public function listBaseGameStageIds():Array<String>
  {
    return [
      "mainStage", "mainStageErect", "spookyMansion", "phillyTrain", "phillyTrainErect", "limoRide", "limoRideErect", "mallXmas", "mallXmasErect", "mallEvil",
      "school", "schoolEvil", "tankmanBattlefield", "phillyStreets", "phillyStreetsErect", "phillyBlazin",
    ];
  }

  /**
   * A list of all installed story weeks that are not from the base game.
   */
  public function listModdedStageIds():Array<String>
  {
    return listEntryIds().filter(function(id:String):Bool {
      return listBaseGameStageIds().indexOf(id) == -1;
    });
  }
}
