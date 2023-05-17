package funkin.data.level;

import funkin.ui.story.Level;
import funkin.data.level.LevelData;
import funkin.ui.story.ScriptedLevel;

class LevelRegistry extends BaseRegistry<Level, LevelData>
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final LEVEL_DATA_VERSION:String = "1.0.0";

  public static final instance:LevelRegistry = new LevelRegistry();

  public function new()
  {
    super('LEVEL', 'levels');
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<LevelData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<LevelData>();
    var jsonStr:String = loadEntryFile(id);

    parser.fromJson(jsonStr);

    if (parser.errors.length > 0)
    {
      trace('Failed to parse entry data: ${id}');
      for (error in parser.errors)
      {
        trace(error);
      }
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
   * A list of all the story weeks, in order.
   * TODO: Should this be hardcoded?
   */
  public function listDefaultLevelIds():String
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
    ]
  }
}
