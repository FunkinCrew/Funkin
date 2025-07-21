package funkin.data.freeplay.player;

import funkin.data.freeplay.player.PlayerData;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.freeplay.charselect.ScriptedPlayableCharacter;
import funkin.save.Save;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class PlayerRegistry extends BaseRegistry<PlayableCharacter, PlayerData> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migratePlayerData()` function.
   */
  public static final PLAYER_DATA_VERSION:thx.semver.Version = "1.0.0";

  public static final PLAYER_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

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

      #if UNLOCK_EVERYTHING
      count++;
      #else
      if (player.isUnlocked()) count++;
      #end
    }

    return count;
  }

  public function hasNewCharacter():Bool
  {
    #if (!UNLOCK_EVERYTHING)
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
    #end

    // Fallthrough case.
    return false;
  }

  public function listNewCharacters():Array<String>
  {
    var result = [];

    #if (!UNLOCK_EVERYTHING)
    var charactersSeen = Save.instance.charactersSeen.clone();
    for (charId in listEntryIds())
    {
      var player = fetchEntry(charId);
      if (player == null) continue;

      if (!player.isUnlocked()) continue;
      if (charactersSeen.contains(charId)) continue;

      // This character is unlocked but we haven't seen them in Freeplay yet.
      result.push(charId);
    }
    #end

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
   * NOTE: This is NOT THE SAME as `player.isUnlocked()`!
   * @param characterId The stage character ID.
   * @return Whether the character is owned by any one character.
   */
  public function isCharacterOwned(characterId:String):Bool
  {
    return ownedCharacterIds.exists(characterId);
  }

  /**
   * @param characterId The character ID to check.
   * @return Whether the player saw the character unlock animation in Character Select.
   */
  public function isCharacterSeen(characterId:String):Bool
  {
    #if UNLOCK_EVERYTHING
    return true;
    #else
    return Save.instance.charactersSeen.contains(characterId);
    #end
  }
}
