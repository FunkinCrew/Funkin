package funkin.data.story.level;

import funkin.util.SortUtil;
import funkin.ui.story.Level;
import funkin.data.story.level.LevelData;
import funkin.ui.story.ScriptedLevel;
import funkin.data.DefaultRegistryImpl;

class LevelRegistry extends BaseRegistry<Level, LevelData> implements DefaultRegistryImpl
{
  /**
   * The current version string for the level data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateLevelData()` function.
   */
  public static final LEVEL_DATA_VERSION:thx.semver.Version = "1.0.1";

  public static final LEVEL_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

  public function new()
  {
    super('LEVEL', 'levels', LEVEL_DATA_VERSION_RULE);
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
