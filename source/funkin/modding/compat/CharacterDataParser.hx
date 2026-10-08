package funkin.modding.compat;

import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
import flixel.graphics.frames.FlxFrame;
import funkin.play.character.BaseCharacter;
import funkin.data.JsonFile;

/**
 * `CharacterDataParser` was refactored to become a `BaseRegistry`.
 * This class provides functions of `CharacterDataParser` that redirect to functions from `CharacterRegistry` so scripts don't break.
 */
class CharacterDataParser
{
  public static function loadCharacterCache():Void
  {
    CharacterRegistry.instance.loadEntries();
  }

  public static function loadCharacterCacheAsync():Void
  {
    CharacterRegistry.instance.loadEntriesAsync();
  }

  public static function queryRegistryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    return CharacterRegistry.instance.queryRegistryAssets(type);
  }

  public static function fetchCharacter(id:String, debug:Bool = false):Null<BaseCharacter>
  {
    return CharacterRegistry.instance.fetchEntry(id, {
      debug: debug
    });
  }

  public static function fetchCharacterData(charId:String):Null<CharacterData>
  {
    return CharacterRegistry.instance.fetchCharacterData(charId);
  }

  public static function listCharacterIds():Array<String>
  {
    return CharacterRegistry.instance.listEntryIds();
  }

  public static function getCharPixelIconAsset(char:String):Null<FlxFrame>
  {
    return CharacterRegistry.getCharPixelIconAsset(char);
  }

  public static function clearCharacterCache():Void
  {
    return CharacterRegistry.instance.clearEntries();
  }

  public static function parseCharacterData(charId:String):Null<CharacterData>
  {
    return CharacterRegistry.instance.parseEntryData(charId);
  }

  public static function loadCharacterFile(charPath:String):String
  {
    @:privateAccess
    var result:JsonFile = funkin.modding.compat.RegistryData.loadEntryData(charPath, '', CharacterRegistry.instance.dataFilePath, true);

    return result.contents;
  }

  static function migrateCharacterData(rawJson:String, charId:String):Null<CharacterData>
  {
    try
    {
      var charData:CharacterData = CharacterRegistry.instance.parseEntryDataRaw(rawJson);
      return charData;
    }
    catch (e)
    {
      trace(' Error parsing data for character: ${charId}');
      trace('   ${e}');
      return null;
    }
  }
}
