package funkin.data.story.level;

import funkin.util.SortUtil;
import funkin.ui.story.Level;
import funkin.ui.story.ScriptedLevel;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class LevelRegistry extends BaseRegistry<Level, LevelData> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the level data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateLevelData()` function.
   */
  public static final LEVEL_DATA_VERSION:thx.semver.Version = "1.0.1";

  public static final LEVEL_DATA_VERSION_RULE:thx.semver.VersionRule = ">=1.0.0 <1.1.0";

  public function new()
  {
    super('LEVEL', 'levels', LEVEL_DATA_VERSION_RULE);
  }

  /**
   * A list of all the story weeks from the base game, in order.
   * @return Array<String>
   */
  public function listBaseGameEntryIds():Array<String>
  {
    // This MUST be hard-coded (overriding the auto-generated method)
    // because the auto-generated method spits out values in alphabetical order.
    return [
      'tutorial',
      'week1',
      'week2',
      'week3',
      'week4',
      'week5',
      'week6',
      'week7',
      'weekend1'
    ];
  }

  /**
   * A list of all the story weeks in the game, in order.
   * Modded levels are in alphabetical order at the end of the list.
   * @return Array<String>
   */
  public function listSortedLevelIds():Array<String>
  {
    var result:Array<String> = listEntryIds();
    result.sort(SortUtil.defaultsThenAlphabetically.bind(listBaseGameEntryIds()));
    return result;
  }
}
