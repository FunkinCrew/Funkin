package funkin.ui.story;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.play.song.Song;
import funkin.data.IRegistryEntry;
import funkin.data.level.LevelRegistry;
import funkin.data.level.LevelData;

/**
 * An object used to retrieve data about a story mode level (also known as "weeks").
 * Can be scripted to override each function, for custom behavior.
 */
class Level implements IRegistryEntry<LevelData>
{
  /**
   * The ID of the story mode level.
   */
  public final id:String;

  /**
   * Level data as parsed from the JSON file.
   */
  public final _data:LevelData;

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
   */
  public function getTitle():String
  {
    // TODO: Maybe add localization support?
    return _data.name;
  }

  public function buildTitleGraphic():FlxSprite
  {
    var result = new FlxSprite().loadGraphic(Paths.image(_data.titleAsset));

    return result;
  }

  /**
   * Get the list of songs in this level, as an array of names, for display on the menu.
   * @return Array<String>
   */
  public function getSongDisplayNames(difficulty:String):Array<String>
  {
    var songList:Array<String> = getSongs() ?? [];
    var songNameList:Array<String> = songList.map(function(songId) {
      return funkin.play.song.SongData.SongDataParser.fetchSong(songId) ?.getDifficulty(difficulty) ?.songName ?? 'Unknown';
    });
    return songNameList;
  }

  /**
   * Whether this level is unlocked. If not, it will be greyed out on the menu and have a lock icon.
   * TODO: Change this behavior in a later release.
   */
  public function isUnlocked():Bool
  {
    return true;
  }

  /**
   * Whether this level is visible. If not, it will not be shown on the menu at all.
   */
  public function isVisible():Bool
  {
    return true;
  }

  /**
   * Build a sprite for the background of the level.
   * Can be overriden by ScriptedLevel. Not used if `isBackgroundSimple` returns true.
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
   */
  public function isBackgroundSimple():Bool
  {
    return _data.background.startsWith('#');
  }

  /**
   * Returns true if the background is a solid color.
   * If you have a ScriptedLevel with a fancy background, you may want to override this to false.
   */
  public function getBackgroundColor():FlxColor
  {
    return FlxColor.fromString(_data.background);
  }

  public function getDifficulties():Array<String>
  {
    var difficulties:Array<String> = [];

    var songList = getSongs();

    var firstSongId:String = songList[0];
    var firstSong:Song = funkin.play.song.SongData.SongDataParser.fetchSong(firstSongId);

    if (firstSong != null)
    {
      for (difficulty in firstSong.listDifficulties())
      {
        difficulties.push(difficulty);
      }
    }

    // Filter to only include difficulties that are present in all songs
    for (songIndex in 1...songList.length)
    {
      var songId:String = songList[songIndex];
      var song:Song = funkin.play.song.SongData.SongDataParser.fetchSong(songId);

      if (song == null) continue;

      for (difficulty in difficulties)
      {
        if (!song.hasDifficulty(difficulty))
        {
          difficulties.remove(difficulty);
        }
      }
    }

    if (difficulties.length == 0) difficulties = ['normal'];

    return difficulties;
  }

  public function buildProps():Array<LevelProp>
  {
    var props:Array<LevelProp> = [];

    if (_data.props.length == 0) return props;

    for (propIndex in 0..._data.props.length)
    {
      var propData = _data.props[propIndex];

      var propSprite:Null<LevelProp> = LevelProp.build(propData);
      if (propSprite == null) continue;

      propSprite.x += FlxG.width * 0.25 * propIndex;
      props.push(propSprite);
    }

    return props;
  }

  public function destroy():Void {}

  public function toString():String
  {
    return 'Level($id)';
  }

  public function _fetchData(id:String):Null<LevelData>
  {
    return LevelRegistry.instance.parseEntryData(id);
  }
}
