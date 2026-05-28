package funkin.ui.story;

import funkin.util.SortUtil;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxColor;
import funkin.play.song.Song;
import funkin.data.IRegistryEntry;
import funkin.data.song.SongRegistry;
import funkin.data.story.level.LevelData;

/**
 * An object used to retrieve data about a story mode level (also known as "weeks").
 * Can be scripted to override each function, for custom behavior.
 */
@:nullSafety
class Level implements IRegistryEntry<LevelData>
{
  /**
   * @param id The ID of the JSON file to parse.
   */
  public function new(id:String, ?params:Dynamic)
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
   *
   * @return The list of song IDs.
   */
  public function getSongs():Array<String>
  {
    // Copy the array so that it can't be modified on accident
    return (_data == null) ? [] : _data.songs.copy();
  }

  /**
   * Retrieve the title of the level for display on the menu.
   *
   * @return Title of the level as a string.
   */
  public function getTitle():String
  {
    return _data?.name ?? 'Unknown';
  }

  /**
   * Retrieve the title of the level for display on a capsule.
   *
   * @return Title of the capsule as a string.
   */
  public function getCapsuleTitle():Null<String>
  {
    return _data?.capsule?.name ?? null;
  }

  public function getCapsuleTitleOffsets():Array<Float>
  {
    return _data?.capsule?.offsets ?? [0.0, 0.0];
  }

  /**
   * Construct the title graphic for the level.
   *
   * @return The constructed graphic as a sprite.
   */
  public function buildTitleGraphic():FunkinSprite
  {
    var titleAsset:String = _data?.titleAsset ?? '';
    if (titleAsset == '')
    {
      return new FunkinSprite().makeSolidColor(0, 0, FlxColor.TRANSPARENT);
    }
    var result:FunkinSprite = new FunkinSprite().loadTexture(titleAsset);

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
    var songNameList:Array<String> = songList.map(function(songId:String)
    {
      return getSongDisplayName(songId, difficulty);
    });
    return songNameList;
  }

  static function getSongDisplayName(songId:String, difficulty:String):String
  {
    var song:Null<Song> = SongRegistry.instance.fetchEntry(songId, {
      variation: Constants.DEFAULT_VARIATION
    });
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
    return _data?.visible ?? true;
  }

  /**
   * Build a sprite for the background of the level.
   * Can be overriden by ScriptedLevel. Not used if `isBackgroundSimple` returns true.
   *
   * @return The constructed sprite
   */
  public function buildBackground():FunkinSprite
  {
    var background:String = _data?.background ?? '#F9CF51';
    if (!background.startsWith('#'))
    {
      // Image specified
      return new FunkinSprite().loadTexture(background);
    }

    // Color specified
    var result:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width, 400, FlxColor.WHITE);
    result.color = getBackgroundColor();
    return result;
  }

  /**
   * Returns true if the background is a solid color.
   * If you have a ScriptedLevel with a fancy background, you may want to override this to false.
   *
   * @return Whether the background is a simple color
   */
  public function isBackgroundSimple():Bool
  {
    var background:String = _data?.background ?? '#F9CF51';
    return background.startsWith('#');
  }

  /**
   * Returns true if the background is a solid color.
   * If you have a ScriptedLevel with a fancy background, you may want to override this to false.
   *
   * @return The background as a simple color. May not be valid if `isBackgroundSimple` returns false.
   */
  public function getBackgroundColor():FlxColor
  {
    var background:String = _data?.background ?? '#F9CF51';
    return FlxColor.fromString(background) ?? Constants.DEFAULT_COLOR_STORY_LEVEL;
  }

  /**
   * The list of difficulties the player can select from for this level.
   * By default, this only returns difficulties on the default variation.
   *
   * @return The difficulty IDs.
   */
  public function getDifficulties():Array<String>
  {
    var difficulties:Array<String> = [];

    var songs:Array<Null<Song>> = [
      for (songId in getSongs()) SongRegistry.instance.fetchEntry(songId, {variation: Constants.DEFAULT_VARIATION})
    ];

    // Pass 1: Populate the `difficulties` Array with every difficulty available.
    for (song in songs)
    {
      for (difficultyId in song?.listDifficulties(Constants.DEFAULT_VARIATION) ?? [])
      {
        if (!difficulties.contains(difficultyId)) difficulties.push(difficultyId);
      }
    }

    // Pass 2: Remove all difficulties not available in every song.
    for (song in songs)
    {
      var songDifficulties:Array<String> = song?.listDifficulties(Constants.DEFAULT_VARIATION) ?? difficulties;

      var unknownDifficulties:Array<String> = difficulties.filter(id -> !songDifficulties.contains(id));
      for (difficultyId in unknownDifficulties) difficulties.remove(difficultyId);
    }

    // If theres no difficulties, add the default difficulty as a fallback.
    if (difficulties.length < 1) difficulties.push(Constants.DEFAULT_DIFFICULTY);

    // Sort it to make sure that it is in order.
    difficulties.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));

    return difficulties;
  }

  /**
   * Build the props for display over the colored background.
   *
   * @param existingProps The existing prop sprites to recycle, if any.
   * @return The constructed prop sprites
   */
  public function buildProps(?existingProps:Array<LevelProp>):Array<LevelProp>
  {
    if (_data == null || _data.props == null) return existingProps ?? [];

    var props:Array<LevelProp> = existingProps == null ? [] : [for (x in existingProps) x];

    if (_data.props.length == 0) return props;

    // Hides unused props
    if (_data.props.length < props.length)
    {
      for (i in _data.props.length...props.length)
      {
        props[i].visible = false;
      }
    }

    for (propIndex in 0..._data.props.length)
    {
      var propData:Null<LevelPropData> = _data.props[propIndex];
      if (propData == null) continue;

      propData.offsets ??= [0.0, 0.0];
      var xOffset:Float = propData?.offsets[0] ?? 0.0;
      var yOffset:Float = propData?.offsets[1] ?? 0.0;

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
          existingProp.x = xOffset + FlxG.width * 0.25 * propIndex;
          existingProp.y = yOffset;
        }
      }
      else
      {
        var propSprite:Null<LevelProp> = LevelProp.build(propData);
        if (propSprite == null) continue;

        propSprite.x = xOffset + FlxG.width * 0.25 * propIndex;
        propSprite.y = yOffset;
        props.push(propSprite);
      }
    }

    return props;
  }
}
