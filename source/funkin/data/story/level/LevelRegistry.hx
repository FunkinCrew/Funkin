package funkin.data.story.level;

import funkin.util.SortUtil;
import funkin.ui.story.Level;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class LevelRegistry extends BaseRegistry<Level, LevelData, LevelEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the level data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateLevelData()` function.
   */
  public static final LEVEL_DATA_VERSION:thx.semver.Version = '1.0.3';

  public static final LEVEL_DATA_VERSION_RULE:thx.semver.VersionRule = '>=1.0.0 <1.1.0';

  var reverseSongMap:Map<String, String> = [];

  public function new()
  {
    super({
      registryId: 'LEVEL',
      dataFilePath: 'ui/story-mode/levels/',
      nestedEntries: false,
      versionRule: LEVEL_DATA_VERSION_RULE
    });
  }

  override public function loadEntries():Void
  {
    super.loadEntries();

    populateReverseSongMap();
  }

  override public function loadEntriesAsync():lime.app.Future<BaseRegistry.LoadEntriesResult>
  {
    return super.loadEntriesAsync().then((result) ->
    {
      populateReverseSongMap();
      return lime.app.Future.withValue(result);
    });
  }

  /**
   * Create a `song => level` map for easy lookup.
   */
  function populateReverseSongMap():Void
  {
    for (id in this.listEntryIds())
    {
      var entry:Null<Level> = this.fetchEntry(id);

      if (entry == null) continue; // this is just for null safety i guess

      var songs:Array<String> = entry.getSongs();

      for (song in songs)
      {
        if (reverseSongMap.exists(song))
        {
          log('Song "$song" is in multiple levels! Make sure ${reverseSongMap.get(song)} and ${id} do not overlap!');
        }

        reverseSongMap.set(song, id);
      }
    }

    log('Loaded ${countEntries()} story levels with ${reverseSongMap.size()} associated songs.');
  }

  override function clearEntries():Void
  {
    super.clearEntries();
    reverseSongMap.clear();
  }

  /**
   * Fetch the data for the default level.
   * We assume `tutorial` always exists, and throw an error if it doesn't.
   *
   * @return The `tutorial` level.
   */
  public function fetchDefault():Level
  {
    var level:Null<Level> = fetchEntry(Constants.DEFAULT_LEVEL);
    if (level == null) throw 'Default level was null! This should not happen!';
    return level;
  }

  /**
   * Get the Level that contains the song with the given ID.
   *
   * @param songId The song ID to look up.
   * @return The Level that song is from.
   */
  public function fetchEntryBySongId(songId:String):Null<Level>
  {
    var targetId:Null<String> = reverseSongMap.get(songId);
    if (targetId == null) return null;

    return fetchEntry(targetId);
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
      'weekend1',
      'sserafim'
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

typedef LevelEntryParams =
{
}
