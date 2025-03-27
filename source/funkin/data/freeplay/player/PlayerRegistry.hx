package funkin.data.freeplay.player;

import funkin.data.freeplay.player.PlayerData;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.freeplay.charselect.ScriptedPlayableCharacter;
import funkin.save.Save;

class PlayerRegistry extends BaseRegistry<PlayableCharacter, PlayerData>
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migratePlayerData()` function.
   */
  public static final PLAYER_DATA_VERSION:thx.semver.Version = "1.0.0";

  public static final PLAYER_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

  public static var instance(get, never):PlayerRegistry;
  static var _instance:Null<PlayerRegistry> = null;

  static function get_instance():PlayerRegistry
  {
    if (_instance == null) _instance = new PlayerRegistry();
    return _instance;
  }

  /**
   * A mapping between stage character IDs and Freeplay playable character IDs.
   */
  var ownedCharacterIds:Map<String, String> = [];

  public function new()
  {
    super('PLAYER', 'players', PLAYER_DATA_VERSION_RULE);
  }

  public override function loadEntries():Void
  {
    super.loadEntries();

    for (playerId in listEntryIds())
    {
      var player = fetchEntry(playerId);
      if (player == null) continue;

      var currentPlayerCharIds = player.getOwnedCharacterIds();
      for (characterId in currentPlayerCharIds)
      {
        ownedCharacterIds.set(characterId, playerId);
      }
    }

    log('Loaded ${countEntries()} playable characters with ${ownedCharacterIds.size()} associations.');
  }

  public function countUnlockedCharacters():Int
  {
    var count = 0;

    for (charId in listEntryIds())
    {
      var player = fetchEntry(charId);
      if (player == null) continue;

      if (player.isUnlocked()) count++;
    }

    return count;
  }

  public function hasNewCharacter():Bool
  {
    var charactersSeen = Save.instance.charactersSeen.clone();

    for (charId in listEntryIds())
    {
      var player = fetchEntry(charId);
      if (player == null) continue;

      if (!player.isUnlocked()) continue;
      if (charactersSeen.contains(charId)) continue;

      // This character is unlocked but we haven't seen them in Freeplay yet.
      return true;
    }

    // Fallthrough case.
    return false;
  }

  public function listNewCharacters():Array<String>
  {
    var charactersSeen = Save.instance.charactersSeen.clone();
    var result = [];

    for (charId in listEntryIds())
    {
      var player = fetchEntry(charId);
      if (player == null) continue;

      if (!player.isUnlocked()) continue;
      if (charactersSeen.contains(charId)) continue;

      // This character is unlocked but we haven't seen them in Freeplay yet.
      result.push(charId);
    }

    return result;
  }

  /**
   * Get the playable character associated with a given stage character.
   * @param characterId The stage character ID.
   * @return The playable character.
   */
  public function getCharacterOwnerId(characterId:Null<String>):Null<String>
  {
    if (characterId == null) return null;
    return ownedCharacterIds[characterId];
  }

  /**
   * Return true if the given stage character is associated with a specific playable character.
   * If so, the level should only appear if that character is selected in Freeplay.
   * @param characterId The stage character ID.
   * @return Whether the character is owned by any one character.
   */
  public function isCharacterOwned(characterId:String):Bool
  {
    return ownedCharacterIds.exists(characterId);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<PlayerData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<PlayerData>();
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
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<PlayerData>
  {
    var parser = new json2object.JsonParser<PlayerData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):PlayableCharacter
  {
    return ScriptedPlayableCharacter.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedPlayableCharacter.listScriptClasses();
  }

  /**
   * A list of all the playable characters from the base game, in order.
   */
  public function listBaseGamePlayerIds():Array<String>
  {
    return ["bf", "pico"];
  }

  /**
   * A list of all installed playable characters that are not from the base game.
   */
  public function listModdedPlayerIds():Array<String>
  {
    return listEntryIds().filter(function(id:String):Bool {
      return listBaseGamePlayerIds().indexOf(id) == -1;
    });
  }
}
