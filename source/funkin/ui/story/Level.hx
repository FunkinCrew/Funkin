package funkin.ui.story;

import funkin.util.SortUtil;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.play.song.Song;
import funkin.data.IRegistryEntry;
import funkin.data.song.SongRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.data.story.level.LevelData;

/**
 * An object used to retrieve data about a story mode level (also known as "weeks").
 * Can be scripted to override each function, for custom behavior.
 */
class Level implements IRegistryEntry<LevelData>
{
  /**
   * @param id The ID of the JSON file to parse.
   */
  public function new(id:String)
  {
    this.id = id;
    _data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse level data for id: $id';
    }
  }

  /**
   * Get the list of songs in this level, as an array of IDs.
   * @return Array<String>
   */
  public function getSongs():Array<String>
  {
    // Copy the array so that it can't be modified on accident
    return _data.songs.copy();
  }

  /**
   * Retrieve the title of the level for display on the menu.
   * @return Title of the level as a string
   */
  public function getTitle():String
  {
    // TODO: Maybe add localization support?
    return _data.name;
  }

  /**
   * Construct the title graphic for the level.
   * @return The constructed graphic as a sprite.
   */
  public function buildTitleGraphic():FlxSprite
  {
    var result:FlxSprite = new FlxSprite().loadGraphic(Paths.image(_data.titleAsset));

    return result;
  }

  /**
   * Get the list of songs in this level, as an array of names, for display on the menu.
   * @param difficulty The difficulty of the level being displayed
   * @return The display names of the songs in this level
   */
  public function getSongDisplayNames(difficulty:String):Array<String>
  {
    var songList:Array<String> = getSongs() ?? [];
    var songNameList:Array<String> = songList.map(function(songId:String) {
      return getSongDisplayName(songId, difficulty);
    });
    return songNameList;
  }

  static function getSongDisplayName(songId:String, difficulty:String):String
  {
    var song:Null<Song> = SongRegistry.instance.fetchEntry(songId);
    if (song == null) return 'Unknown';

    return song.songName;
  }

  /**
   * Whether this level is unlocked. If not, it will be greyed out on the menu and have a lock icon.
   * Override this in a script.
   * @default `true`
   * @return Whether this level is unlocked
   */
  public function isUnlocked():Bool
  {
    return true;
  }

  /**
   * Whether this level is visible. If not, it will not be shown on the menu at all.
   * Override this in a script.
   * @default `true`
   * @return Whether this level is visible in the menu
   */
  public function isVisible():Bool
  {
    return _data.visible;
  }

  /**
   * Build a sprite for the background of the level.
   * Can be overriden by ScriptedLevel. Not used if `isBackgroundSimple` returns true.
   * @return The constructed sprite
   */
  public function buildBackground():FlxSprite
  {
    if (!_data.background.startsWith('#'))
    {
      // Image specified
      return new FlxSprite().loadGraphic(Paths.image(_data.background));
    }

    // Color specified
    var result:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 400, FlxColor.WHITE);
    result.color = getBackgroundColor();
    return result;
  }

  /**
   * Returns true if the background is a solid color.
   * If you have a ScriptedLevel with a fancy background, you may want to override this to false.
   * @return Whether the background is a simple color
   */
  public function isBackgroundSimple():Bool
  {
    return _data.background.startsWith('#');
  }

  /**
   * Returns true if the background is a solid color.
   * If you have a ScriptedLevel with a fancy background, you may want to override this to false.
   * @return The background as a simple color. May not be valid if `isBackgroundSimple` returns false.
   */
  public function getBackgroundColor():FlxColor
  {
    return FlxColor.fromString(_data.background);
  }

  /**
   * The list of difficulties the player can select from for this level.
   * @return The difficulty IDs.
   */
  public function getDifficulties():Array<String>
  {
    var difficulties:Array<String> = [];

    var songList:Array<String> = getSongs();

    var firstSongId:String = songList[0];
    var firstSong:Song = SongRegistry.instance.fetchEntry(firstSongId);

    if (firstSong != null)
    {
      // Don't display alternate characters in Story Mode. Only show `default` and `erect` variations.
      for (difficulty in firstSong.listDifficulties([Constants.DEFAULT_VARIATION, 'erect'], false, false))
      {
        difficulties.push(difficulty);
      }
    }

    // Sort in a specific order! Fall back to alphabetical.
    difficulties.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST));

    // Filter to only include difficulties that are present in all songs
    for (songIndex in 1...songList.length)
    {
      var songId:String = songList[songIndex];
      var song:Song = SongRegistry.instance.fetchEntry(songId);

      if (song == null) continue;

      for (difficulty in difficulties)
      {
        if (!song.hasDifficulty(difficulty, [Constants.DEFAULT_VARIATION, 'erect']))
        {
          difficulties.remove(difficulty);
        }
      }
    }

    if (difficulties.length == 0) difficulties = ['normal'];

    return difficulties;
  }

  /**
   * Build the props for display over the colored background.
   * @param existingProps The existing prop sprites, if any.
   * @return The constructed prop sprites
   */
  public function buildProps(?existingProps:Array<LevelProp>):Array<LevelProp>
  {
    var props:Array<LevelProp> = existingProps == null ? [] : [for (x in existingProps) x];

    if (_data.props.length == 0) return props;

    var hiddenProps:Array<LevelProp> = props.splice(_data.props.length - 1, props.length - 1);
    for (hiddenProp in hiddenProps)
    {
      hiddenProp.visible = false;
    }

    for (propIndex in 0..._data.props.length)
    {
      var propData:LevelPropData = _data.props[propIndex];

      // Attempt to reuse the `LevelProp` object.
      // This prevents animations from resetting.
      var existingProp:Null<LevelProp> = props[propIndex];
      if (existingProp != null)
      {
        existingProp.propData = propData;
        if (existingProp.propData == null)
        {
          existingProp.visible = false;
        }
        else
        {
          existingProp.visible = true;
          existingProp.x = propData.offsets[0] + FlxG.width * 0.25 * propIndex;
        }
      }
      else
      {
        var propSprite:Null<LevelProp> = LevelProp.build(propData);
        if (propSprite == null) continue;

        propSprite.x = propData.offsets[0] + FlxG.width * 0.25 * propIndex;
        props.push(propSprite);
      }
    }

    return props;
  }
}
